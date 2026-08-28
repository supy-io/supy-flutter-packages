import 'dart:async';
import 'dart:collection';

import 'package:batch_fetcher/src/core/batch_outcome.dart';
import 'package:batch_fetcher/src/core/batch_scope.dart';
import 'package:batch_fetcher/src/core/clock.dart';
import 'package:batch_fetcher/src/core/config.dart';
import 'package:batch_fetcher/src/core/fetch_entry.dart';
import 'package:batch_fetcher/src/core/observer.dart';
import 'package:batch_fetcher/src/core/retry_policy.dart';
import 'package:batch_fetcher/src/core/settle_policy.dart';

/// Fetches values for a batch of ids under one scope key.
///
/// Throwing means the whole batch failed. To report a per-id failure alongside
/// ids that succeeded, return them in [BatchOutcome.failures] instead.
typedef BatchRequest<TId, TValue, TKey> = Future<BatchOutcome<TId, TValue>>
    Function(List<TId> ids, TKey key);

/// Coalesces per-id value lookups into batched requests.
///
/// The problem it solves: a list renders N rows, each needing a value only the
/// server can compute, and you want one request per screenful rather than N.
///
/// ```dart
/// final fetcher = BatchFetcher<String, double, BatchKey>(
///   request: (ids, key) async =>
///       BatchOutcome.resolved(await api.costs(ids, at: key)),
/// );
///
/// // Safe to call on every build with the whole visible page — cached ids,
/// // in-flight ids and ids inside a backoff window are all skipped.
/// await fetcher.fetch(BatchScope(key: scopeKey, ids: visibleIds));
///
/// switch (fetcher.entryOf(id)) {
///   case FetchPresent(:final value) => Text('$value'),
///   case FetchLoading() => const Skeleton(),
///   case FetchFailed(:final willRetry) => RetryChip(enabled: !willRetry),
///   case FetchAbsent() || FetchIdle() => const Text('—'),
/// }
/// ```
///
/// This class is pure Dart and holds no `Listenable`, so it drives a bloc as
/// readily as a `ChangeNotifier`. For the Flutter bindings see
/// `package:batch_fetcher_flutter`.
class BatchFetcher<TId, TValue, TKey> {
  /// Creates a fetcher that batches through [request].
  BatchFetcher({
    required BatchRequest<TId, TValue, TKey> request,
    BatchFetcherConfig config = const BatchFetcherConfig(),
    RetryPolicy retry = const ExponentialBackoff(),
    SettlePolicy<TValue>? settle,
    Clock clock = const SystemClock(),
    BatchFetcherObserver<TId>? observer,
  })  : _request = request,
        _config = config,
        _retry = retry,
        _settle = settle,
        _clock = clock,
        _observer = observer;

  final BatchRequest<TId, TValue, TKey> _request;
  final BatchFetcherConfig _config;
  final RetryPolicy _retry;
  final SettlePolicy<TValue>? _settle;
  final Clock _clock;
  final BatchFetcherObserver<TId>? _observer;

  final Map<TId, FetchEntry<TValue>> _entries = {};
  final Map<TId, DateTime> _fetchedAt = {};
  final Map<TId, int> _failureCount = {};
  final Map<TId, int> _settleCount = {};

  /// When an id becomes eligible again — a retry backoff or a settle delay.
  final Map<TId, DateTime> _dueAt = {};

  /// Bumped by [invalidate] so a response that is already in flight for the id
  /// is discarded instead of overwriting the freshly-cleared state.
  final Map<TId, int> _generation = {};

  /// The scope an id was last requested under, so [refresh] knows where to
  /// re-request it.
  final Map<TId, TKey> _scopeOf = {};

  /// Every id a request is currently in flight for, across all scopes.
  final Set<TId> _inFlight = <TId>{};

  final Map<TKey, _Scope<TId, TKey>> _scopes = {};
  final List<_Waiter<TId>> _waiters = [];

  final StreamController<Set<TId>> _changes =
      StreamController<Set<TId>>.broadcast(sync: true);

  bool _disposed = false;

  /// Emits the ids whose entry changed, after every change.
  ///
  /// Synchronous and broadcast, so an adapter can turn it straight into a
  /// `notifyListeners()` without deferring a frame.
  Stream<Set<TId>> get changes => _changes.stream;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// The state of [id].
  FetchEntry<TValue> entryOf(TId id) => _entries[id] ?? FetchIdle<TValue>();

  /// Every id that has resolved to a value.
  Map<TId, TValue> get values => Map<TId, TValue>.unmodifiable(<TId, TValue>{
        for (final entry in _entries.entries)
          if (entry.value case FetchPresent<TValue>(:final value))
            entry.key: value,
      });

  /// Every id a request is in flight for.
  Set<TId> get loadingIds => UnmodifiableSetView<TId>(_inFlight);

  /// Whether any request is in flight or any id is queued.
  bool get isBusy =>
      _scopes.values.any((scope) => scope.inFlight || scope.pending.isNotEmpty);

  /// Requests values for [scope]'s ids, coalescing with any other call inside
  /// the debounce window.
  ///
  /// Ids that are already cached, already in flight, or inside a retry backoff
  /// are skipped, so calling this on every rebuild with the whole visible page
  /// is the intended usage.
  ///
  /// The returned future completes once every requested id has reached a
  /// terminal state: a value its settle policy accepts, a confirmed absence, or
  /// a failure the retry policy has given up on. It therefore waits out
  /// scheduled retries and settle delays — `await fetch(...)` means "done
  /// trying", not "one request went out". Callers that do not want to wait
  /// simply do not await it.
  Future<void> fetch(BatchScope<TId, TKey> scope) {
    if (_disposed) {
      throw StateError('fetch() called on a disposed BatchFetcher');
    }
    if (scope.ids.isEmpty) return Future<void>.value();

    final target = _scopeFor(scope.key);
    for (final id in scope.ids) {
      _scopeOf[id] = scope.key;
      if (_shouldQueue(id)) target.pending.add(id);
    }

    final waited = scope.ids.toSet();
    if (_isQuiet(waited)) return Future<void>.value();

    final waiter = _Waiter<TId>(waited);
    _waiters.add(waiter);
    _scheduleDebounce(target);
    return waiter.completer.future;
  }

  /// Drops the cached state for [ids] and requests them again under the scope
  /// each was last fetched with.
  ///
  /// Ids never fetched before are ignored — there is no scope to request them
  /// under. Use [fetch] for those.
  Future<void> refresh(Iterable<TId> ids) {
    final list = ids.toList();
    invalidate(ids: list);

    final byScope = <TKey, List<TId>>{};
    for (final id in list) {
      final key = _scopeOf[id];
      if (key != null) byScope.putIfAbsent(key, () => <TId>[]).add(id);
    }
    return Future.wait(
      byScope.entries.map(
        (entry) =>
            fetch(BatchScope<TId, TKey>(key: entry.key, ids: entry.value)),
      ),
    );
  }

  /// Clears cached state so the next [fetch] re-requests it.
  ///
  /// Pass [ids] to target specific ids, or omit it to clear everything. A
  /// response already in flight for a cleared id is discarded when it lands
  /// rather than being written over the cleared state.
  void invalidate({Iterable<TId>? ids}) {
    final target = (ids ?? _entries.keys.toList()).toList();
    if (target.isEmpty) return;

    final changed = <TId>{};

    for (final id in target) {
      if (_inFlight.contains(id)) {
        _generation[id] = (_generation[id] ?? 0) + 1;
      } else {
        _generation.remove(id);
      }
      if (_entries.remove(id) != null) changed.add(id);
      _fetchedAt.remove(id);
      _failureCount.remove(id);
      _settleCount.remove(id);
      _dueAt.remove(id);
      for (final scope in _scopes.values) {
        scope.pending.remove(id);
      }
    }

    _emit(changed);
    _settleWaiters();
    _pruneScopes();
  }

  /// Forgets every id outside [keep], to bound memory on a long-lived list.
  ///
  /// Ids currently in flight are kept regardless, so a response never lands on
  /// state that was dropped underneath it.
  void trim(Iterable<TId> keep) {
    final retain = keep.toSet()..addAll(_inFlight);
    // Queued ids count as known even before they have an entry: an id awaiting
    // a retry, or awaiting its first drain, is exactly what this is meant to
    // forget. Dropping the entry alone would leave it in the queue to be
    // requested and re-created on the next drain.
    final known = <TId>{
      ..._entries.keys,
      for (final scope in _scopes.values) ...scope.pending,
    };
    final drop = known.where((id) => !retain.contains(id)).toList();
    if (drop.isEmpty) return;

    final changed = <TId>{};
    for (final id in drop) {
      if (_entries.remove(id) != null) changed.add(id);
      _fetchedAt.remove(id);
      _failureCount.remove(id);
      _settleCount.remove(id);
      _dueAt.remove(id);
      _generation.remove(id);
      _scopeOf.remove(id);
      for (final scope in _scopes.values) {
        scope.pending.remove(id);
      }
    }

    _emit(changed);
    // A caller awaiting one of these ids would otherwise wait for a request
    // that is never going to be sent.
    _settleWaiters();
    _pruneScopes();
  }

  /// Cancels every timer, stops emitting, and drops any response still in
  /// flight.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final scope in _scopes.values) {
      scope.debounce?.cancel();
      scope.wake?.cancel();
    }
    _scopes.clear();
    _inFlight.clear();
    for (final waiter in _waiters) {
      if (!waiter.completer.isCompleted) waiter.completer.complete();
    }
    _waiters.clear();
    await _changes.close();
  }

  // ===== queueing =====

  _Scope<TId, TKey> _scopeFor(TKey key) {
    final existing = _scopes[key];
    if (existing != null) return existing;

    assert(
      _scopes.length < _config.maxTrackedScopes,
      'BatchFetcher is tracking ${_scopes.length} live scopes, which exceeds '
      'maxTrackedScopes (${_config.maxTrackedScopes}). Scope keys are almost '
      'certainly not comparing equal when they should: a key type holding a '
      'List, Set or Map compares by identity in Dart, so it mints a new scope '
      'on every rebuild. Use BatchKey, or give the key value equality over '
      'scalar fields.',
    );

    return _scopes[key] = _Scope<TId, TKey>(key);
  }

  bool _shouldQueue(TId id) {
    if (_inFlight.contains(id)) return false;

    final due = _dueAt[id];
    if (due != null && due.isAfter(_clock.now())) return false;

    final entry = _entries[id];
    return switch (entry) {
      null || FetchIdle<TValue>() => true,
      FetchLoading<TValue>() => false,
      FetchFailed<TValue>(:final willRetry) => willRetry,
      FetchAbsent<TValue>() => _isStale(id),
      FetchPresent<TValue>(:final value) =>
        _isStale(id) || _needsSettle(id, value),
    };
  }

  bool _isStale(TId id) {
    final after = _config.staleAfter;
    if (after == null) return false;
    final at = _fetchedAt[id];
    if (at == null) return true;
    return !_clock.now().isBefore(at.add(after));
  }

  bool _needsSettle(TId id, TValue value) {
    final settle = _settle;
    if (settle == null || settle.isSettled(value)) return false;
    return (_settleCount[id] ?? 0) < settle.maxAttempts;
  }

  void _scheduleDebounce(_Scope<TId, TKey> scope) {
    if (scope.pending.isEmpty) return;
    scope.debounce?.cancel();
    scope.debounce = _clock.timer(_config.debounce, () {
      scope.debounce = null;
      _drain(scope.key);
    });
  }

  // ===== draining =====

  Future<void> _drain(TKey key) async {
    final scope = _scopes[key];
    if (_disposed || scope == null || scope.inFlight) return;

    scope.debounce?.cancel();
    scope.debounce = null;

    final now = _clock.now();
    // Ids coming due within one debounce window travel together. Backoff
    // delays are jittered per id, so without this a batch of fifty that failed
    // together would come back as fifty separate retry requests.
    final gathered = now.add(_config.debounce);
    final batch = <TId>[];
    DateTime? earliest;

    for (final id in scope.pending) {
      final due = _dueAt[id];
      if (due == null || !due.isAfter(gathered)) {
        batch.add(id);
        if (batch.length >= _config.maxBatchSize) break;
      } else if (earliest == null || due.isBefore(earliest)) {
        earliest = due;
      }
    }

    if (batch.isEmpty) {
      _scheduleWake(scope, earliest, now);
      _pruneScope(key);
      _settleWaiters();
      return;
    }

    scope.pending.removeAll(batch);
    _inFlight.addAll(batch);
    scope.inFlight = true;

    final generations = <TId, int>{
      for (final id in batch) id: _generation[id] ?? 0,
    };
    final before = <TId, FetchEntry<TValue>?>{
      for (final id in batch) id: _entries[id],
    };

    final changed = <TId>{};
    for (final id in batch) {
      _dueAt.remove(id);
      _entries[id] = FetchLoading<TValue>(previous: before[id]?.valueOrNull);
      changed.add(id);
    }
    _emit(changed);

    _observer?.onBatchStart(key, batch);

    BatchOutcome<TId, TValue>? outcome;
    Object? thrown;
    try {
      outcome = await _request(batch, key);
      // A request callback is caller-supplied and may throw anything at all;
      // the point of this layer is that one bad batch does not take the
      // fetcher down with it.
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      thrown = error;
    }

    _observer?.onBatchEnd(key, batch, error: thrown);

    // A fetcher disposed mid-flight must not write to its cache, or notify.
    if (_disposed) return;

    scope.inFlight = false;
    _inFlight.removeAll(batch);

    final survivors =
        batch.where((id) => (_generation[id] ?? 0) == generations[id]).toList();

    final applied = <TId>{};
    // The retry delay is resolved once per attempt number per drain, not once
    // per id: jitter exists to spread load across clients, and applying it per
    // id inside one client only splinters the batch it just failed on.
    final delays = <int, Duration?>{};
    if (thrown != null) {
      for (final id in survivors) {
        _recordFailure(id, thrown, scope, applied, delays);
      }
    } else {
      _applyOutcome(survivors, outcome!, before, scope, applied, delays);
    }

    _emit(applied);
    _settleWaiters();

    if (scope.pending.isNotEmpty) {
      scheduleMicrotask(() => _drain(key));
    } else {
      _pruneScope(key);
    }
  }

  void _applyOutcome(
    List<TId> survivors,
    BatchOutcome<TId, TValue> outcome,
    Map<TId, FetchEntry<TValue>?> before,
    _Scope<TId, TKey> scope,
    Set<TId> changed,
    Map<int, Duration?> delays,
  ) {
    final requested = survivors.toSet();
    final mentioned = <TId>{};
    final now = _clock.now();
    final settle = _settle;

    for (final entry in outcome.values.entries) {
      final id = entry.key;
      if (!requested.contains(id)) continue;
      mentioned.add(id);
      _entries[id] = FetchPresent<TValue>(entry.value);
      _fetchedAt[id] = now;
      _failureCount.remove(id);
      changed.add(id);

      if (settle == null || settle.isSettled(entry.value)) {
        _settleCount.remove(id);
        continue;
      }
      final attempt = (_settleCount[id] ?? 0) + 1;
      if (attempt > settle.maxAttempts) continue;
      _settleCount[id] = attempt;
      _dueAt[id] = now.add(settle.retryDelay);
      scope.pending.add(id);
      _observer?.onUnsettled(id, attempt, settle.retryDelay);
    }

    for (final id in outcome.absent) {
      if (!requested.contains(id)) continue;
      mentioned.add(id);
      _entries[id] = FetchAbsent<TValue>();
      _fetchedAt[id] = now;
      _failureCount.remove(id);
      changed.add(id);
    }

    for (final entry in outcome.failures.entries) {
      if (!requested.contains(entry.key)) continue;
      mentioned.add(entry.key);
      _recordFailure(entry.key, entry.value, scope, changed, delays);
    }

    for (final id in survivors) {
      if (mentioned.contains(id)) continue;
      switch (outcome.unlisted) {
        case UnlistedIds.absent:
          _entries[id] = FetchAbsent<TValue>();
          _fetchedAt[id] = now;
          _failureCount.remove(id);
          changed.add(id);
        case UnlistedIds.failed:
          _recordFailure(
            id,
            StateError('id was not returned by the batch request'),
            scope,
            changed,
            delays,
          );
        case UnlistedIds.ignore:
          final restored = before[id];
          if (restored == null) {
            _entries.remove(id);
          } else {
            _entries[id] = restored;
          }
          changed.add(id);
      }
    }
  }

  void _recordFailure(
    TId id,
    Object error,
    _Scope<TId, TKey> scope,
    Set<TId> changed,
    Map<int, Duration?> delays,
  ) {
    final attempt = (_failureCount[id] ?? 0) + 1;
    _failureCount[id] = attempt;
    final previous = _entries[id]?.valueOrNull;
    final delay = delays.putIfAbsent(
      attempt,
      () => _retry.nextDelay(attempt, error),
    );

    if (delay == null) {
      _entries[id] = FetchFailed<TValue>(error, previous: previous);
      _observer?.onGaveUp(id, error);
    } else {
      _entries[id] =
          FetchFailed<TValue>(error, willRetry: true, previous: previous);
      _dueAt[id] = _clock.now().add(delay);
      scope.pending.add(id);
      _observer?.onRetryScheduled(id, attempt, delay);
    }
    changed.add(id);
  }

  void _scheduleWake(
    _Scope<TId, TKey> scope,
    DateTime? earliest,
    DateTime now,
  ) {
    scope.wake?.cancel();
    if (earliest == null) {
      scope.wake = null;
      return;
    }
    final delay = earliest.difference(now);
    scope.wake = _clock.timer(delay.isNegative ? Duration.zero : delay, () {
      scope.wake = null;
      _drain(scope.key);
    });
  }

  // ===== bookkeeping =====

  /// A scope with nothing queued, nothing in flight and no timers is dropped,
  /// so the per-scope maps track live work rather than every key ever seen.
  void _pruneScope(TKey key) {
    final scope = _scopes[key];
    if (scope == null || !scope.isIdle) return;
    _scopes.remove(key);
  }

  void _pruneScopes() {
    _scopes.keys.toList().forEach(_pruneScope);
  }

  bool _isQuiet(Set<TId> ids) {
    if (ids.any(_inFlight.contains)) return false;
    for (final scope in _scopes.values) {
      if (ids.any(scope.pending.contains)) return false;
    }
    return true;
  }

  void _settleWaiters() {
    if (_waiters.isEmpty) return;
    final done = _waiters.where((waiter) => _isQuiet(waiter.ids)).toList();
    for (final waiter in done) {
      _waiters.remove(waiter);
      if (!waiter.completer.isCompleted) waiter.completer.complete();
    }
  }

  void _emit(Set<TId> changed) {
    if (_disposed || changed.isEmpty || _changes.isClosed) return;
    _changes.add(Set<TId>.unmodifiable(changed));
  }
}

/// One batching group: the queue, in-flight set and timers for a single key.
class _Scope<TId, TKey> {
  _Scope(this.key);

  final TKey key;
  final LinkedHashSet<TId> pending = LinkedHashSet<TId>();
  bool inFlight = false;
  Timer? debounce;
  Timer? wake;

  bool get isIdle =>
      !inFlight && pending.isEmpty && debounce == null && wake == null;
}

/// One caller awaiting the ids it asked for.
class _Waiter<TId> {
  _Waiter(this.ids);

  final Set<TId> ids;
  final Completer<void> completer = Completer<void>();
}
