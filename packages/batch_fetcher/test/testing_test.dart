// The test kit is shipped API, so it carries the same expectations as the
// engine: if FakeClock lies about ordering, every timing test built on it is
// quietly wrong.
import 'dart:async';

import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:batch_fetcher/batch_fetcher_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeClock', () {
    test('does not move on its own', () async {
      final clock = FakeClock(start: DateTime.utc(2026, 5));
      final before = clock.now();
      await clock.pumpMicrotasks();

      expect(clock.now(), before);
    });

    test('fires timers in due order, not scheduling order', () async {
      final clock = FakeClock();
      final fired = <String>[];

      clock
        ..timer(const Duration(seconds: 3), () => fired.add('late'))
        ..timer(const Duration(seconds: 1), () => fired.add('early'));

      await clock.advance(const Duration(seconds: 5));

      expect(fired, ['early', 'late']);
    });

    test('honours a timer scheduled from inside a firing timer', () async {
      final clock = FakeClock();
      final fired = <String>[];

      clock.timer(const Duration(seconds: 1), () {
        fired.add('first');
        clock.timer(const Duration(seconds: 1), () => fired.add('second'));
      });

      await clock.advance(const Duration(seconds: 5));

      expect(fired, ['first', 'second']);
    });

    test('leaves a timer scheduled beyond the window pending', () async {
      final clock = FakeClock();
      var fired = false;
      clock.timer(const Duration(seconds: 10), () => fired = true);

      await clock.advance(const Duration(seconds: 5));

      expect(fired, isFalse);
      expect(clock.pendingTimers, 1);
      expect(clock.now(), DateTime.utc(2026).add(const Duration(seconds: 5)));
    });

    test('a cancelled timer never fires and stops being pending', () async {
      final clock = FakeClock();
      var fired = false;
      final timer = clock.timer(const Duration(seconds: 1), () => fired = true);

      expect(timer.isActive, isTrue);
      timer.cancel();
      expect(timer.isActive, isFalse);
      expect(clock.pendingTimers, 0);
      expect(timer.tick, 0);

      await clock.advance(const Duration(seconds: 5));
      expect(fired, isFalse);
    });

    test('clamps a negative duration to zero', () async {
      final clock = FakeClock();
      var fired = false;
      clock.timer(const Duration(seconds: -1), () => fired = true);

      await clock.advance(Duration.zero);

      expect(fired, isTrue);
    });
  });

  group('ScriptedRequest', () {
    test('replays steps in order and repeats the last one', () async {
      final script = ScriptedRequest<String, int, BatchKey>([
        (ids, key) => const BatchOutcome.resolved({'a': 1}),
        (ids, key) => const BatchOutcome.resolved({'a': 2}),
      ]);

      expect((await script(['a'], BatchKey.none)).values, {'a': 1});
      expect((await script(['a'], BatchKey.none)).values, {'a': 2});
      expect(
        (await script(['a'], BatchKey.none)).values,
        {'a': 2},
        reason: 'a test only scripts the calls it cares about',
      );
    });

    test('records the ids and keys of every call', () async {
      final script = ScriptedRequest<String, int, BatchKey>.always(
        (id) => id.length,
      );
      final key = BatchKey(const ['loc']);

      await script(['a', 'bb'], key);
      await script(['ccc'], key);

      expect(script.callCount, 2);
      expect(script.calls, [
        ['a', 'bb'],
        ['ccc'],
      ]);
      expect(script.keys, [key, key]);
      expect(script.idCount, 3);
      expect(() => script.calls.first.add('x'), throwsUnsupportedError);
    });

    test('alwaysFailing throws the given error every call', () async {
      final error = Exception('down');
      final script =
          ScriptedRequest<String, int, BatchKey>.alwaysFailing(error);

      await expectLater(
        script(['a'], BatchKey.none),
        throwsA(same(error)),
      );
    });
  });

  group('RecordingObserver', () {
    test('records nothing until something happens', () {
      final observer = RecordingObserver<String>();

      expect(observer.batches, isEmpty);
      expect(observer.batchErrors, isEmpty);
      expect(observer.retries, isEmpty);
      expect(observer.gaveUp, isEmpty);
      expect(observer.unsettled, isEmpty);
    });
  });

  group('BatchFetcherObserver', () {
    test('its default methods are no-ops, so a partial observer is valid',
        () async {
      final clock = FakeClock();
      final fetcher = BatchFetcher<String, int, BatchKey>(
        request: (ids, key) async => throw Exception('boom'),
        clock: clock,
        retry: const NoRetry(),
        observer: const _SilentObserver(),
      );
      addTearDown(fetcher.dispose);

      final future = fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      await clock.advance(const Duration(milliseconds: 61));
      await future;

      expect(fetcher.entryOf('a'), isA<FetchFailed<int>>());
    });

    test('its retry and settle hooks are no-ops too', () async {
      final clock = FakeClock();
      var attempt = 0;
      final fetcher = BatchFetcher<String, int, BatchKey>(
        request: (ids, key) async {
          attempt++;
          if (attempt == 1) throw Exception('boom');
          return BatchOutcome.resolved(<String, int>{
            for (final id in ids) id: 0,
          });
        },
        clock: clock,
        retry: const ExponentialBackoff(base: Duration(seconds: 1), jitter: 0),
        settle: const SettleWhen<int>(_isNonZero),
        observer: const _SilentObserver(),
      );
      addTearDown(fetcher.dispose);

      final future = fetcher.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      await clock.advance(const Duration(seconds: 10));
      await future;

      expect(attempt, 3, reason: 'one failure, one retry, one settle re-fetch');
      expect(fetcher.entryOf('a'), const FetchPresent<int>(0));
    });
  });

  group('SystemClock', () {
    test('drives a real fetcher on real time', () async {
      final fetcher = BatchFetcher<String, int, BatchKey>(
        request: (ids, key) async => BatchOutcome.resolved(<String, int>{
          for (final id in ids) id: id.length,
        }),
        config: const BatchFetcherConfig(debounce: Duration(milliseconds: 1)),
      );
      addTearDown(fetcher.dispose);

      await fetcher.fetch(BatchScope(key: BatchKey.none, ids: const ['abc']));

      expect(fetcher.entryOf('abc'), const FetchPresent<int>(3));
    });

    test('now advances', () async {
      const clock = SystemClock();
      final before = clock.now();
      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(clock.now().isAfter(before), isTrue);
    });
  });
}

bool _isNonZero(int value) => value != 0;

/// An observer that overrides nothing, exercising the base no-op bodies.
class _SilentObserver extends BatchFetcherObserver<String> {
  const _SilentObserver();
}
