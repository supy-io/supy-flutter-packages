// Entry equality is load-bearing: a widget that rebuilds on entryOf(id)
// changing must not rebuild when an unrelated id resolves.
import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:test/test.dart';

void main() {
  group('equality', () {
    test('same-state entries of the same type are equal', () {
      expect(const FetchIdle<int>(), const FetchIdle<int>());
      expect(const FetchAbsent<int>(), const FetchAbsent<int>());
      expect(const FetchPresent<int>(1), const FetchPresent<int>(1));
      expect(const FetchLoading<int>(previous: 1),
          const FetchLoading<int>(previous: 1));
    });

    test('states are never equal to each other', () {
      const entries = <FetchEntry<int>>[
        FetchIdle<int>(),
        FetchLoading<int>(),
        FetchPresent<int>(1),
        FetchAbsent<int>(),
      ];
      for (var i = 0; i < entries.length; i++) {
        for (var j = 0; j < entries.length; j++) {
          if (i == j) continue;
          expect(entries[i], isNot(entries[j]));
        }
      }
    });

    test('idle and absent are distinguishable', () {
      expect(
        const FetchIdle<int>(),
        isNot(const FetchAbsent<int>()),
        reason: 'never fetched is not the same as fetched and empty',
      );
    });

    test('a differing value or previous breaks equality', () {
      expect(const FetchPresent<int>(1), isNot(const FetchPresent<int>(2)));
      expect(
        const FetchLoading<int>(previous: 1),
        isNot(const FetchLoading<int>(previous: 2)),
      );
    });

    test('failed entries compare on error, willRetry and previous', () {
      final error = Exception('x');
      expect(FetchFailed<int>(error), FetchFailed<int>(error));
      expect(
        FetchFailed<int>(error),
        isNot(FetchFailed<int>(error, willRetry: true)),
      );
      expect(
        FetchFailed<int>(error),
        isNot(FetchFailed<int>(error, previous: 1)),
      );
      expect(FetchFailed<int>(error), isNot(FetchFailed<int>(Exception('y'))));
    });

    test('hash codes agree with equality', () {
      final error = Exception('x');
      expect(const FetchIdle<int>().hashCode, const FetchIdle<int>().hashCode);
      expect(
        const FetchPresent<int>(1).hashCode,
        const FetchPresent<int>(1).hashCode,
      );
      expect(
        const FetchLoading<int>(previous: 1).hashCode,
        const FetchLoading<int>(previous: 1).hashCode,
      );
      expect(
          const FetchAbsent<int>().hashCode, const FetchAbsent<int>().hashCode);
      expect(
          FetchFailed<int>(error).hashCode, FetchFailed<int>(error).hashCode);
    });
  });

  group('accessors', () {
    test('isLoading is true only while loading', () {
      expect(const FetchLoading<int>().isLoading, isTrue);
      expect(const FetchIdle<int>().isLoading, isFalse);
      expect(const FetchPresent<int>(1).isLoading, isFalse);
    });

    test('valueOrNull surfaces a stale value during loading and failure', () {
      expect(const FetchLoading<int>(previous: 3).valueOrNull, 3);
      expect(FetchFailed<int>(Exception('x'), previous: 4).valueOrNull, 4);
      expect(const FetchPresent<int>(5).valueOrNull, 5);
      expect(const FetchIdle<int>().valueOrNull, isNull);
      expect(const FetchAbsent<int>().valueOrNull, isNull);
    });

    test('errorOrNull is set only on failure', () {
      final error = Exception('x');
      expect(FetchFailed<int>(error).errorOrNull, error);
      expect(const FetchPresent<int>(1).errorOrNull, isNull);
      expect(const FetchIdle<int>().errorOrNull, isNull);
    });
  });

  test('toString names the state and its payload', () {
    expect(const FetchIdle<int>().toString(), 'FetchIdle()');
    expect(const FetchAbsent<int>().toString(), 'FetchAbsent()');
    expect(const FetchPresent<int>(1).toString(), 'FetchPresent(1)');
    expect(
      const FetchLoading<int>(previous: 1).toString(),
      'FetchLoading(previous: 1)',
    );
    expect(
      FetchFailed<int>(Exception('x'), previous: 1).toString(),
      contains('willRetry: false'),
    );
  });
}
