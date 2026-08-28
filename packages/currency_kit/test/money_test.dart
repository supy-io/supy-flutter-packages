import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  const aed = CurrencyCode.aed;
  const usd = CurrencyCode.usd;

  group('arithmetic in one currency', () {
    test('adds, subtracts, negates and scales', () {
      expect(
          const Money(10, aed) + const Money(2.5, aed), const Money(12.5, aed));
      expect(
          const Money(10, aed) - const Money(2.5, aed), const Money(7.5, aed));
      expect(-const Money(10, aed), const Money(-10, aed));
      expect(const Money(10, aed) * 3, const Money(30, aed));
      expect(const Money(10, aed) / 4, const Money(2.5, aed));
    });

    test('compares', () {
      expect(const Money(10, aed) > const Money(2, aed), isTrue);
      expect(const Money(10, aed) >= const Money(10, aed), isTrue);
      expect(const Money(2, aed) < const Money(10, aed), isTrue);
      expect(const Money(2, aed) <= const Money(2, aed), isTrue);
      expect([const Money(3, aed), const Money(1, aed)]..sort(),
          [const Money(1, aed), const Money(3, aed)]);
    });
  });

  group('mixing currencies is an error, not a silent number', () {
    test('every combining operation throws', () {
      const ten = Money(10, aed);
      const two = Money(2, usd);
      expect(() => ten + two, throwsA(isA<CurrencyMismatchError>()));
      expect(() => ten - two, throwsA(isA<CurrencyMismatchError>()));
      expect(() => ten.compareTo(two), throwsA(isA<CurrencyMismatchError>()));
      expect(() => ten > two, throwsA(isA<CurrencyMismatchError>()));
    });

    test('the error names both currencies and the operation', () {
      expect(
        () => const Money(10, aed) + const Money(2, usd),
        throwsA(
          isA<CurrencyMismatchError>()
              .having((e) => e.left, 'left', aed)
              .having((e) => e.right, 'right', usd)
              .having((e) => e.operation, 'operation', '+')
              .having((e) => e.toString(), 'message', contains('ExchangeRate')),
        ),
      );
    });

    test('unequal currencies are never equal amounts', () {
      expect(const Money(10, aed), isNot(const Money(10, usd)));
    });
  });

  group('rounding', () {
    test('rounds half away from zero at the currency precision', () {
      expect(const Money(0.125, aed).rounded().amount, 0.13);
      expect(const Money(-0.125, aed).rounded().amount, -0.13);
      expect(const Money(2.5, aed).rounded(0).amount, 3);
      expect(const Money(-2.5, aed).rounded(0).amount, -3);
    });

    test('rounds the typed decimal, not the binary value', () {
      // 412.565 is stored as 412.56499…, so rounding the double would give
      // 412.56. Money rounds what the user typed.
      expect(const Money(412.565, aed).rounded().amount, 412.57);
      expect(const Money(412.575, aed).rounded().amount, 412.58);
      expect(
        const Money(412.565, aed).rounded(2, RoundingMode.halfUpBinary).amount,
        412.56,
      );
    });

    test('precision comes from the currency', () {
      expect(const Money(1234.5678, CurrencyCode.jpy).rounded().amount, 1235);
      expect(
          const Money(1234.5678, CurrencyCode.kwd).rounded().amount, 1234.568);
    });

    test('isZero asks at the currency precision', () {
      expect(const Money(0.004, aed).isZero, isTrue);
      expect(const Money(0.005, aed).isZero, isFalse);
      expect(const Money(0.004, CurrencyCode.kwd).isZero, isFalse);
    });
  });

  group('value semantics', () {
    test('zero, abs and isNegative', () {
      expect(const Money.zero(aed).amount, 0);
      expect(const Money(-5, aed).abs, const Money(5, aed));
      expect(const Money(-5, aed).isNegative, isTrue);
      expect(const Money(0, aed).isNegative, isFalse);
    });

    test('equality and hashCode are by amount and currency', () {
      expect(const Money(10, aed), const Money(10, aed));
      expect(const Money(10, aed).hashCode, const Money(10, aed).hashCode);
      expect(const Money(10, aed), isNot(const Money(10.01, aed)));
    });

    test('copyWith relabels without converting', () {
      final relabelled = const Money(36.9, aed).copyWith(currency: usd);
      expect(relabelled.amount, 36.9, reason: 'copyWith must not apply a rate');
      expect(relabelled.currency, usd);
    });

    test('toString is for debugging, format is for users', () {
      expect(const Money(36.9, aed).toString(), 'Money(36.9, AED)');
      expect(const Money(36.9, aed).format(), 'AED 36.90');
    });
  });
}
