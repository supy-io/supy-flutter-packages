// Behaviour tests for the engine.
//
// Most of these exist because the in-app predecessor got them wrong: an
// unenforced retry budget, a domain rule baked into the engine, "not returned"
// forced to mean "failed", a response landing on state that had just been
// invalidated, and per-key maps that only ever grew. Each group names the
// property, not the implementation.
import 'dart:async';

import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('batching', () {
    test('coalesces ids queued in one debounce window into one request',
        () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['bb'])));
      final last = h.fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['ccc']),
      );

      await h.clock.advance(debounceWindow);
      await last;

      expect(h.script.callCount, 1);
      expect(h.script.calls.single, ['a', 'bb', 'ccc']);
      expect(h.fetcher.values, {'a': 1, 'bb': 2, 'ccc': 3});
    });

    test('skips ids that already resolved', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);
      await _fetch(h, ['a', 'bb', 'ccc']);

      expect(h.script.callCount, 2);
      expect(h.script.calls[1], ['ccc'],
          reason: 'cached ids are not refetched');
    });

    test('skips ids already in flight', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate), resolveAll]);
      addTearDown(h.fetcher.dispose);

      final first =
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a']));
      await h.clock.advance(debounceWindow);
      expect(h.fetcher.loadingIds, {'a'});

      // Asking again mid-flight must not send a second request for 'a'.
      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      await h.clock.advance(debounceWindow);
      expect(h.script.callCount, 1);

      gate.complete(const BatchOutcome.resolved({'a': 1}));
      await h.clock.pumpMicrotasks();
      await first;
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
    });

    test('splits at maxBatchSize and drains the remainder', () async {
      final h = harness(config: const BatchFetcherConfig(maxBatchSize: 2));
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb', 'ccc', 'dddd', 'eeeee']);

      expect(h.script.calls.map((ids) => ids.length), [2, 2, 1]);
      expect(h.fetcher.values.length, 5);
    });

    test('groups ids into one request per scope key', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      final one = BatchKey(const ['loc_1']);
      final two = BatchKey(const ['loc_2']);
      unawaited(h.fetcher.fetch(BatchScope(key: one, ids: const ['a'])));
      final last = h.fetcher.fetch(BatchScope(key: two, ids: const ['bb']));
      await h.clock.advance(debounceWindow);
      await last;

      expect(h.script.callCount, 2);
      expect(h.script.keys.toSet(), {one, two});
    });
  });

  group('fetch() future', () {
    test('completes only once every requested id is terminal', () async {
      final h = harness(
        steps: [throwing(boom), resolveAll],
        retry: const ExponentialBackoff(base: Duration(seconds: 1)),
      );
      addTearDown(h.fetcher.dispose);

      var done = false;
      final future = h.fetcher
          .fetch(BatchScope(key: BatchKey.none, ids: const ['a']))
          .then((_) => done = true);

      await h.clock.advance(debounceWindow);
      expect(done, isFalse, reason: 'a retry is still scheduled');

      await h.clock.advance(const Duration(seconds: 2));
      await future;
      expect(done, isTrue);
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
    });

    test('returns an already-complete future when everything is cached',
        () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);
      await _fetch(h, ['a']);

      var synchronous = true;
      unawaited(
        h.fetcher
            .fetch(BatchScope(key: BatchKey.none, ids: const ['a']))
            .whenComplete(() => expect(synchronous, isTrue)),
      );
      await h.clock.pumpMicrotasks();
      synchronous = false;

      expect(h.script.callCount, 1);
    });

    test('is a no-op for an empty id list', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await h.fetcher
          .fetch(BatchScope(key: BatchKey.none, ids: const <String>[]));
      await h.clock.advance(debounceWindow);

      expect(h.script.callCount, 0);
    });

    test('throws after dispose', () async {
      final h = harness();
      await h.fetcher.dispose();

      expect(
        () => h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])),
        throwsStateError,
      );
    });
  });

  group('per-id results', () {
    test('a per-id failure does not discard the ids that succeeded', () async {
      final h = harness(
        steps: [
          (ids, key) => BatchOutcome<String, int>(
                values: const {'a': 1},
                failures: {'bb': boom},
              ),
        ],
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);

      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
      expect(h.fetcher.entryOf('bb'), isA<FetchFailed<int>>());
      expect(h.fetcher.values, {'a': 1});
    });

    test('a confirmed absence is cached and not requested again', () async {
      final h = harness(
        steps: [
          (ids, key) => const BatchOutcome<String, int>(absent: {'a'}),
        ],
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      expect(h.fetcher.entryOf('a'), const FetchAbsent<int>());

      await _fetch(h, ['a']);
      expect(h.script.callCount, 1,
          reason: 'absence is an answer, not an error');
    });

    test('a thrown request fails every id in the batch', () async {
      final h = harness(steps: [throwing(boom)]);
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);

      for (final id in ['a', 'bb']) {
        expect(h.fetcher.entryOf(id), FetchFailed<int>(boom));
      }
      expect(h.observer.batchErrors, [boom]);
    });

    test('a refresh keeps the stale value visible while loading', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [resolveTo(7), gated(gate)]);
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      final refreshed = h.fetcher.refresh(['a']);
      await h.clock.advance(debounceWindow);

      expect(h.fetcher.entryOf('a'), const FetchLoading<int>());

      gate.complete(const BatchOutcome.resolved({'a': 9}));
      await h.clock.pumpMicrotasks();
      await refreshed;
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(9));
    });
  });

  group('unlisted ids', () {
    test('are treated as absent by default', () async {
      final h = harness(
        steps: [
          (ids, key) => const BatchOutcome.resolved({'a': 1})
        ],
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);

      expect(h.fetcher.entryOf('bb'), const FetchAbsent<int>());
    });

    test('are reported as failures under UnlistedIds.failed', () async {
      final h = harness(
        steps: [
          (ids, key) => const BatchOutcome.resolved(
                {'a': 1},
                unlisted: UnlistedIds.failed,
              ),
        ],
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);

      expect(h.fetcher.entryOf('bb'), isA<FetchFailed<int>>());
    });

    test('leave the previous entry untouched under UnlistedIds.ignore',
        () async {
      final h = harness(
        steps: [
          resolveTo(5),
          (ids, key) => const BatchOutcome.resolved(
                <String, int>{},
                unlisted: UnlistedIds.ignore,
              ),
        ],
        config: const BatchFetcherConfig(staleAfter: Duration(minutes: 1)),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      await h.clock.advance(const Duration(minutes: 2));
      await _fetch(h, ['a']);

      expect(
        h.script.callCount,
        2,
        reason: 'the stale value was re-requested',
      );
      expect(
        h.fetcher.entryOf('a'),
        const FetchPresent<int>(5),
        reason: 'a partitioned request answers about a subset only',
      );
    });
  });

  group('retry', () {
    test('retries after the backoff without another fetch call', () async {
      final h = harness(
        steps: [throwing(boom), resolveAll],
        retry: const ExponentialBackoff(base: Duration(seconds: 1), jitter: 0),
      );
      addTearDown(h.fetcher.dispose);

      final future = h.fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      await h.clock.advance(debounceWindow);
      expect(h.fetcher.entryOf('a'), FetchFailed<int>(boom, willRetry: true));
      expect(h.script.callCount, 1);

      await h.clock.advance(const Duration(seconds: 1));
      await future;

      expect(h.script.callCount, 2, reason: 'the wake timer re-drained it');
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
    });

    test('enforces maxAttempts rather than clamping the counter', () async {
      final h = harness(
        steps: [throwing(boom)],
        retry: const ExponentialBackoff(
          base: Duration(seconds: 1),
          maxAttempts: 3,
          jitter: 0,
        ),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a'], settleFor: const Duration(minutes: 1));

      expect(h.script.callCount, 3, reason: 'three attempts, then it stops');
      expect(h.fetcher.entryOf('a'), FetchFailed<int>(boom));
      expect(h.observer.gaveUp, ['a']);
      expect(h.observer.retries.map((r) => r.$2), [1, 2]);
    });

    test('backs off exponentially, capped at max', () async {
      const policy = ExponentialBackoff(
        base: Duration(seconds: 1),
        max: Duration(seconds: 5),
        maxAttempts: 10,
        jitter: 0,
      );

      expect(policy.nextDelay(1, boom), const Duration(seconds: 1));
      expect(policy.nextDelay(2, boom), const Duration(seconds: 2));
      expect(policy.nextDelay(3, boom), const Duration(seconds: 4));
      expect(policy.nextDelay(4, boom), const Duration(seconds: 5));
      expect(policy.nextDelay(9, boom), const Duration(seconds: 5));
      expect(policy.nextDelay(10, boom), isNull);
    });

    test('does not requeue an id it has given up on', () async {
      final h = harness(steps: [throwing(boom)]);
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      await _fetch(h, ['a']);

      expect(h.script.callCount, 1);
    });

    test('a fresh value clears the failure history', () async {
      final h = harness(
        steps: [throwing(boom), resolveAll, throwing(boom)],
        retry: const ExponentialBackoff(base: Duration(seconds: 1), jitter: 0),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a'], settleFor: const Duration(seconds: 5));
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
      expect(h.observer.retries.map((r) => r.$2), [1]);

      unawaited(h.fetcher.refresh(['a']));
      await h.clock.advance(debounceWindow);

      expect(
        h.observer.retries.map((r) => r.$2),
        [1, 1],
        reason: 'the second failure starts a new attempt count, not attempt 2',
      );
    });
  });

  group('settle policy', () {
    test('re-fetches a value the policy rejects, then accepts it', () async {
      final h = harness(
        steps: [resolveTo(0), resolveTo(42)],
        settle: SettleWhen<int>((value) => value != 0),
      );
      addTearDown(h.fetcher.dispose);

      final future = h.fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      await h.clock.advance(debounceWindow);

      expect(
        h.fetcher.entryOf('a'),
        const FetchPresent<int>(0),
        reason: 'an unsettled value is still shown, not hidden',
      );
      expect(h.observer.unsettled.single.$1, 'a');

      await h.clock.advance(const Duration(seconds: 4));
      await future;

      expect(h.script.callCount, 2);
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(42));
    });

    test('accepts the value once maxAttempts is spent', () async {
      final h = harness(
        steps: [resolveTo(0)],
        settle: SettleWhen<int>((value) => value != 0, maxAttempts: 2),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a'], settleFor: const Duration(seconds: 30));

      expect(h.script.callCount, 3, reason: 'first call plus two re-fetches');
      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(0));

      await _fetch(h, ['a']);
      expect(h.script.callCount, 3, reason: '0 is now believed');
    });

    test('never re-fetches a settled value', () async {
      final h = harness(
        steps: [resolveTo(7)],
        settle: SettleWhen<int>((value) => value != 0),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a'], settleFor: const Duration(seconds: 30));

      expect(h.script.callCount, 1);
      expect(h.observer.unsettled, isEmpty);
    });
  });

  group('invalidate', () {
    test('clears cached values so the next fetch re-requests them', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      h.fetcher.invalidate(ids: ['a']);

      expect(h.fetcher.entryOf('a'), const FetchIdle<int>());
      await _fetch(h, ['a']);
      expect(h.script.callCount, 2);
    });

    test('discards a response already in flight for an invalidated id',
        () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate), resolveAll]);
      addTearDown(h.fetcher.dispose);

      final first =
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a']));
      await h.clock.advance(debounceWindow);

      h.fetcher.invalidate(ids: ['a']);
      gate.complete(const BatchOutcome.resolved({'a': 99}));
      await h.clock.pumpMicrotasks();
      await first;

      expect(
        h.fetcher.entryOf('a'),
        const FetchIdle<int>(),
        reason: 'a stale response must not overwrite cleared state',
      );
    });

    test('with no ids clears everything', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb']);
      h.fetcher.invalidate();

      expect(h.fetcher.values, isEmpty);
    });
  });

  group('dispose', () {
    test('drops a response that lands after dispose', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate)]);

      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      await h.clock.advance(debounceWindow);
      await h.fetcher.dispose();

      gate.complete(const BatchOutcome.resolved({'a': 1}));
      await h.clock.pumpMicrotasks();

      expect(h.fetcher.values, isEmpty);
    });

    test('cancels pending timers', () async {
      final h = harness();

      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      expect(h.clock.pendingTimers, 1);

      await h.fetcher.dispose();
      expect(h.clock.pendingTimers, 0);
      expect(h.fetcher.isDisposed, isTrue);
    });

    test('completes any future a caller is still awaiting', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate)]);

      final future =
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a']));
      await h.clock.advance(debounceWindow);
      await h.fetcher.dispose();

      await expectLater(future, completes);
    });

    test('is idempotent', () async {
      final h = harness();
      await h.fetcher.dispose();
      await h.fetcher.dispose();
      expect(h.fetcher.isDisposed, isTrue);
    });
  });

  group('staleness', () {
    test('re-requests a value once staleAfter has elapsed', () async {
      final h = harness(
        config: const BatchFetcherConfig(staleAfter: Duration(minutes: 5)),
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      await _fetch(h, ['a']);
      expect(h.script.callCount, 1);

      await h.clock.advance(const Duration(minutes: 6));
      await _fetch(h, ['a']);
      expect(h.script.callCount, 2);
    });

    test('caches forever when staleAfter is null', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);
      await h.clock.advance(const Duration(days: 1));
      await _fetch(h, ['a']);

      expect(h.script.callCount, 1);
    });
  });

  group('scopes', () {
    test('drops a scope once it has no work left', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      for (var i = 0; i < 200; i++) {
        await _fetch(h, ['id_$i'], key: BatchKey(['loc_$i']));
      }

      // 200 distinct scopes came and went without tripping the tripwire, which
      // can only be true if each was reclaimed when it went quiet.
      expect(h.script.callCount, 200);
    });

    test('asserts once live scopes exceed maxTrackedScopes', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(
        steps: [gated(gate)],
        config: const BatchFetcherConfig(maxTrackedScopes: 3),
      );
      addTearDown(h.fetcher.dispose);

      // Hold every scope open by never completing the gate, which is what an
      // identity-compared key does by accident on every rebuild.
      for (var i = 0; i < 3; i++) {
        unawaited(h.fetcher
            .fetch(BatchScope(key: BatchKey(['k_$i']), ids: ['a_$i'])));
      }
      await h.clock.advance(debounceWindow);

      expect(
        () => h.fetcher.fetch(
          BatchScope(
              key: BatchKey(const ['k_overflow']), ids: const ['a_overflow']),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('changes stream', () {
    test('emits the ids whose entry changed', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      final emissions = <Set<String>>[];
      final sub = h.fetcher.changes.listen(emissions.add);
      addTearDown(sub.cancel);

      await _fetch(h, ['a', 'bb']);

      expect(
        emissions,
        [
          {'a', 'bb'}, // both moved to loading
          {'a', 'bb'}, // both resolved
        ],
      );
    });

    test('does not emit when nothing changed', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);
      await _fetch(h, ['a']);

      final emissions = <Set<String>>[];
      final sub = h.fetcher.changes.listen(emissions.add);
      addTearDown(sub.cancel);

      await _fetch(h, ['a']);
      h.fetcher.invalidate(ids: ['nonexistent']);

      expect(emissions, isEmpty);
    });
  });

  group('trim', () {
    test('forgets ids outside the keep set', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a', 'bb', 'ccc']);
      h.fetcher.trim(['a']);

      expect(h.fetcher.values.keys, ['a']);
      expect(h.fetcher.entryOf('bb'), const FetchIdle<int>());
    });

    test('drops an id queued for retry instead of resurrecting it', () async {
      final h = harness(
        steps: [throwing(boom), resolveAll],
        retry: const ExponentialBackoff(base: Duration(seconds: 5), jitter: 0),
      );
      addTearDown(h.fetcher.dispose);

      unawaited(h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: ['a'])));
      await h.clock.advance(debounceWindow);
      expect(h.fetcher.entryOf('a'), FetchFailed<int>(boom, willRetry: true));
      expect(h.script.callCount, 1);

      // 'a' is queued for a retry that has not come due yet.
      h.fetcher.trim(<String>[]);
      expect(h.fetcher.entryOf('a'), const FetchIdle<int>());

      await h.clock.advance(const Duration(seconds: 10));

      expect(
        h.script.callCount,
        1,
        reason: 'a trimmed id must not come back through the retry queue',
      );
      expect(h.fetcher.entryOf('a'), const FetchIdle<int>());
    });

    test('drops an id queued but not yet requested', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      unawaited(
        h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: ['a', 'bb'])),
      );
      h.fetcher.trim(const ['a']);
      await h.clock.advance(debounceWindow);

      expect(h.script.calls.single, ['a']);
    });

    test('completes a waiter left behind by the ids it dropped', () async {
      final h = harness(
        steps: [throwing(boom)],
        retry: const ExponentialBackoff(base: Duration(seconds: 5), jitter: 0),
      );
      addTearDown(h.fetcher.dispose);

      var done = false;
      final future = h.fetcher
          .fetch(BatchScope(key: BatchKey.none, ids: ['a']))
          .then((_) => done = true);
      await h.clock.advance(debounceWindow);
      expect(done, isFalse, reason: 'still waiting on the scheduled retry');

      h.fetcher.trim(<String>[]);
      await h.clock.pumpMicrotasks();
      await future;

      expect(done, isTrue);
    });

    test('keeps ids still in flight regardless', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate)]);
      addTearDown(h.fetcher.dispose);

      final future =
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a']));
      await h.clock.advance(debounceWindow);
      h.fetcher.trim(<String>[]);

      gate.complete(const BatchOutcome.resolved({'a': 1}));
      await h.clock.pumpMicrotasks();
      await future;

      expect(h.fetcher.entryOf('a'), const FetchPresent<int>(1));
    });
  });

  group('backoff windows', () {
    test('an id inside its backoff window is not re-queued by a new fetch',
        () async {
      final h = harness(
        steps: [throwing(boom), resolveAll],
        retry: const ExponentialBackoff(base: Duration(seconds: 10), jitter: 0),
      );
      addTearDown(h.fetcher.dispose);

      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      await h.clock.advance(debounceWindow);
      expect(h.script.callCount, 1);

      // A rebuilding list asks again immediately. Without the window this is
      // exactly how a failing id turns into a request per frame.
      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      await h.clock.advance(const Duration(seconds: 1));

      expect(h.script.callCount, 1);
    });

    test('wakes at the earliest of several pending windows', () async {
      final h = harness(
        steps: [
          (ids, key) => BatchOutcome<String, int>(
                failures: {for (final id in ids) id: boom},
              ),
          resolveAll,
        ],
        retry: const ExponentialBackoff(base: Duration(seconds: 2), jitter: 0),
        config: const BatchFetcherConfig(maxBatchSize: 2),
      );
      addTearDown(h.fetcher.dispose);

      unawaited(
        h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a', 'bb'])),
      );
      await h.clock.advance(debounceWindow);
      expect(h.script.callCount, 1);

      await h.clock.advance(const Duration(seconds: 3));
      expect(h.script.callCount, 2, reason: 'the earliest window woke it');
      expect(h.fetcher.values, {'a': 1, 'bb': 2});
    });

    test('a batch that failed together retries together', () async {
      final h = harness(
        steps: [throwing(boom), resolveAll],
        // Real jitter, which is what splinters a retry batch if the delay is
        // resolved per id instead of per attempt.
        retry: const ExponentialBackoff(base: Duration(seconds: 1)),
      );
      addTearDown(h.fetcher.dispose);

      final ids = [for (var i = 0; i < 50; i++) 'id_$i'];
      await _fetch(h, ids, settleFor: const Duration(seconds: 5));

      expect(
        h.script.calls.map((call) => call.length),
        [50, 50],
        reason: 'one request, one retry — not one retry per id',
      );
      expect(h.fetcher.values.length, 50);
    });

    test('isBusy reports queued and in-flight work', () async {
      final gate = Completer<BatchOutcome<String, int>>();
      final h = harness(steps: [gated(gate)]);
      addTearDown(h.fetcher.dispose);

      expect(h.fetcher.isBusy, isFalse);

      final future = h.fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      expect(h.fetcher.isBusy, isTrue, reason: 'queued behind the debounce');

      await h.clock.advance(debounceWindow);
      expect(h.fetcher.isBusy, isTrue, reason: 'in flight');

      gate.complete(const BatchOutcome.resolved({'a': 1}));
      await h.clock.pumpMicrotasks();
      await future;
      expect(h.fetcher.isBusy, isFalse);
    });

    test('an invalidate that empties the queue leaves nothing to drain',
        () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      unawaited(
          h.fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['a'])));
      h.fetcher.invalidate(ids: ['a']);
      await h.clock.advance(debounceWindow);

      expect(h.script.callCount, 0);
      expect(h.fetcher.isBusy, isFalse);
    });

    test('UnlistedIds.ignore on a never-seen id leaves it idle', () async {
      final h = harness(
        steps: [
          (ids, key) => const BatchOutcome.resolved(
                <String, int>{},
                unlisted: UnlistedIds.ignore,
              ),
        ],
      );
      addTearDown(h.fetcher.dispose);

      await _fetch(h, ['a']);

      expect(h.fetcher.entryOf('a'), const FetchIdle<int>());
    });
  });

  group('refresh', () {
    test('re-requests ids under the scope they were last fetched with',
        () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      final key = BatchKey(const ['loc_1']);
      await _fetch(h, ['a'], key: key);
      await _refresh(h, ['a']);

      expect(h.script.callCount, 2);
      expect(h.script.keys, [key, key]);
    });

    test('ignores ids never fetched before', () async {
      final h = harness();
      addTearDown(h.fetcher.dispose);

      await _refresh(h, ['never_seen']);

      expect(h.script.callCount, 0);
    });
  });
}

/// Refreshes [ids] and advances the clock so the request actually goes out.
Future<void> _refresh(
  Harness h,
  List<String> ids, {
  Duration settleFor = Duration.zero,
}) async {
  final future = h.fetcher.refresh(ids);
  await h.clock.advance(debounceWindow + settleFor);
  await future;
}

/// Fetches [ids] and advances past the debounce window, plus [settleFor] to let
/// any scheduled retry or settle delay play out.
Future<void> _fetch(
  Harness h,
  List<String> ids, {
  BatchKey key = BatchKey.none,
  Duration settleFor = Duration.zero,
}) async {
  final future = h.fetcher.fetch(BatchScope(key: key, ids: ids));
  await h.clock.advance(debounceWindow + settleFor);
  await future;
}
