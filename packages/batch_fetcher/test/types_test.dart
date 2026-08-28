import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:test/test.dart';

void main() {
  group('BatchOutcome', () {
    test('defaults to empty results and absent-unlisted', () {
      const outcome = BatchOutcome<String, int>();

      expect(outcome.values, isEmpty);
      expect(outcome.failures, isEmpty);
      expect(outcome.absent, isEmpty);
      expect(outcome.unlisted, UnlistedIds.absent);
    });

    test('resolved carries values and leaves the rest empty', () {
      const outcome = BatchOutcome<String, int>.resolved({'a': 1});

      expect(outcome.values, {'a': 1});
      expect(outcome.failures, isEmpty);
      expect(outcome.absent, isEmpty);
    });

    test('toString counts each bucket', () {
      final outcome = BatchOutcome<String, int>(
        values: const {'a': 1},
        failures: {'b': Exception('x')},
        absent: const {'c'},
        unlisted: UnlistedIds.failed,
      );

      expect(
        outcome.toString(),
        'BatchOutcome(values: 1, failures: 1, absent: 1, unlisted: failed)',
      );
    });
  });

  group('BatchScope', () {
    test('copies the ids so a later mutation cannot reach the fetcher', () {
      final ids = ['a'];
      final scope = BatchScope<String, BatchKey>(key: BatchKey.none, ids: ids);
      ids.add('b');

      expect(scope.ids, ['a']);
      expect(() => scope.ids.add('c'), throwsUnsupportedError);
    });

    test('toString reports the key and the id count, not the ids', () {
      final scope = BatchScope<String, BatchKey>(
        key: BatchKey.none,
        ids: const ['a', 'b'],
      );

      expect(scope.toString(), 'BatchScope(key: BatchKey([]), ids: 2)');
    });
  });

  group('SettleWhen', () {
    test('delegates to its predicate', () {
      const policy = SettleWhen<int>(_isNonZero);

      expect(policy.isSettled(1), isTrue);
      expect(policy.isSettled(0), isFalse);
      expect(policy.retryDelay, const Duration(seconds: 3));
      expect(policy.maxAttempts, 1);
    });
  });

  group('NoRetry', () {
    test('gives up immediately', () {
      expect(const NoRetry().nextDelay(1, Exception('x')), isNull);
    });
  });

  group('ExponentialBackoff', () {
    test('keeps jittered delays within the jitter band', () {
      const policy = ExponentialBackoff(
        base: Duration(seconds: 1),
        maxAttempts: 2,
        jitter: 0.5,
      );

      for (var i = 0; i < 50; i++) {
        final delay = policy.nextDelay(1, Exception('x'))!;
        expect(delay.inMilliseconds, inInclusiveRange(500, 1500));
      }
    });
  });
}

bool _isNonZero(int value) => value != 0;
