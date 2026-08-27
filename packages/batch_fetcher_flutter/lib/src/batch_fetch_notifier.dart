import 'dart:async';

import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:flutter/foundation.dart';

/// The read side of a batch fetcher, with the scope-key type erased.
///
/// A widget needs two things from a fetcher — the state of one id, and a signal
/// when it changes — and neither depends on how requests are grouped. Erasing
/// `TKey` here is what lets one widget serve fetchers with different key types
/// without falling back to `dynamic`.
abstract interface class BatchFetchListenable<TId, TValue>
    implements Listenable {
  /// The state of [id].
  FetchEntry<TValue> entryOf(TId id);
}

/// A [ChangeNotifier] over a [BatchFetcher].
///
/// Wraps rather than extends, so the engine stays framework-free and testable
/// on its own, and so the same fetcher can also drive a bloc.
class BatchFetchNotifier<TId, TValue, TKey> extends ChangeNotifier
    implements BatchFetchListenable<TId, TValue> {
  /// Builds a fetcher from [request] and owns it: disposing this notifier
  /// disposes the fetcher.
  ///
  /// Generative on purpose — a feature-specific provider is expected to
  /// subclass this and pass its own request, which a factory constructor
  /// cannot support.
  BatchFetchNotifier({
    required BatchRequest<TId, TValue, TKey> request,
    BatchFetcherConfig config = const BatchFetcherConfig(),
    RetryPolicy retry = const ExponentialBackoff(),
    SettlePolicy<TValue>? settle,
    Clock clock = const SystemClock(),
    BatchFetcherObserver<TId>? observer,
  })  : fetcher = BatchFetcher<TId, TValue, TKey>(
          request: request,
          config: config,
          retry: retry,
          settle: settle,
          clock: clock,
          observer: observer,
        ),
        _owns = true {
    _subscription = fetcher.changes.listen((_) => notifyListeners());
  }

  /// Wraps an existing [fetcher].
  ///
  /// Set [owns] to false when the fetcher outlives this notifier — it is
  /// registered in a service locator, say — and something else disposes it.
  BatchFetchNotifier.wrapping(this.fetcher, {bool owns = true}) : _owns = owns {
    _subscription = fetcher.changes.listen((_) => notifyListeners());
  }

  /// The engine this notifier reports on.
  final BatchFetcher<TId, TValue, TKey> fetcher;

  final bool _owns;
  late final StreamSubscription<Set<TId>> _subscription;

  @override
  FetchEntry<TValue> entryOf(TId id) => fetcher.entryOf(id);

  /// Every id that has resolved to a value.
  Map<TId, TValue> get values => fetcher.values;

  /// Every id a request is in flight for.
  Set<TId> get loadingIds => fetcher.loadingIds;

  /// Whether any request is in flight or any id is queued.
  bool get isBusy => fetcher.isBusy;

  /// See [BatchFetcher.fetch].
  Future<void> fetch(BatchScope<TId, TKey> scope) => fetcher.fetch(scope);

  /// See [BatchFetcher.refresh].
  Future<void> refresh(Iterable<TId> ids) => fetcher.refresh(ids);

  /// See [BatchFetcher.invalidate].
  void invalidate({Iterable<TId>? ids}) => fetcher.invalidate(ids: ids);

  /// See [BatchFetcher.trim].
  void trim(Iterable<TId> keep) => fetcher.trim(keep);

  @override
  void dispose() {
    _subscription.cancel();
    if (_owns) fetcher.dispose();
    super.dispose();
  }
}
