import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  const aed = CurrencyCode.aed;
  const usd = CurrencyCode.usd;

  // "1 USD = 3.69 AED" — the sentence the currency picker shows the user.
  final usdToAed = ExchangeRate(base: usd, quote: aed, rate: 3.69);

  group('construction states the direction', () {
    test('reads as 1 base = rate quote', () {
      expect(usdToAed.toString(), '1 USD = 3.69 AED');
      expect(usdToAed.base, usd);
      expect(usdToAed.quote, aed);
    });

    test('rejects a rate that cannot be a rate', () {
      expect(
        () => ExchangeRate(base: usd, quote: aed, rate: 0),
        throwsArgumentError,
      );
      expect(
        () => ExchangeRate(base: usd, quote: aed, rate: -1),
        throwsArgumentError,
      );
      expect(
        () => ExchangeRate(base: usd, quote: aed, rate: double.nan),
        throwsArgumentError,
      );
      expect(
        () => ExchangeRate(base: usd, quote: aed, rate: double.infinity),
        throwsArgumentError,
      );
    });

    test('rejects a same-currency rate that is not 1', () {
      expect(
        () => ExchangeRate(base: aed, quote: aed, rate: 3.69),
        throwsArgumentError,
      );
      expect(ExchangeRate(base: aed, quote: aed, rate: 1).isIdentity, isTrue);
    });
  });

  group('the two boundaries', () {
    test('toQuote is the input boundary: the user typed 10 USD', () {
      expect(usdToAed.toQuote(const Money(10, usd)).rounded(),
          const Money(36.9, aed));
    });

    test('toBase is the render boundary: show 36.90 AED as USD', () {
      expect(usdToAed.toBase(const Money(36.9, aed)).rounded(),
          const Money(10, usd));
    });

    test('each rejects an amount in the wrong currency', () {
      expect(() => usdToAed.toQuote(const Money(10, aed)),
          throwsA(isA<CurrencyMismatchError>()));
      expect(() => usdToAed.toBase(const Money(10, usd)),
          throwsA(isA<CurrencyMismatchError>()));
    });
  });

  group('identity', () {
    test('leaves amounts untouched in both directions', () {
      const identity = ExchangeRate.identity(aed);
      expect(identity.toQuote(const Money(36.9, aed)), const Money(36.9, aed));
      expect(identity.toBase(const Money(36.9, aed)), const Money(36.9, aed));
      expect(identity.isIdentity, isTrue);
    });

    test('is the safe stand-in for "no currency selected"', () {
      const identity = ExchangeRate.identity(aed);
      expect(identity.inverted.isIdentity, isTrue);
      expect(identity.rate, 1);
    });
  });

  group('inverted', () {
    test('reads the rate the other way', () {
      final aedToUsd = usdToAed.inverted;
      expect(aedToUsd.base, aed);
      expect(aedToUsd.quote, usd);
      expect(aedToUsd.rate, closeTo(1 / 3.69, 1e-12));
    });

    test('round-trips back to the original', () {
      expect(usdToAed.inverted.inverted.rate, closeTo(3.69, 1e-12));
    });

    test('inverting swaps which boundary is which', () {
      expect(usdToAed.inverted.toBase(const Money(10, usd)).rounded(),
          const Money(36.9, aed));
    });
  });

  group('display-only: switching currency cannot move a stored amount', () {
    test('the worked example, end to end', () {
      // 1. The user reads USD and types 10.
      const typed = Money(10, usd);
      final stored = usdToAed.toQuote(typed).rounded();
      expect(stored, const Money(36.9, aed));
      expect(stored.format(), 'AED 36.90');

      // 2. They switch the picker to AED: the same stored amount, re-rendered.
      expect(stored.format(), 'AED 36.90');

      // 3. They switch back to USD.
      expect(usdToAed.toBase(stored).rounded().format(), 'USD 10.00');

      // 4. The stored amount never moved.
      expect(stored, const Money(36.9, aed));
    });

    test('twenty toggles leave the stored amount bit-identical', () {
      const stored = Money(36.9, aed);
      var value = stored;
      for (var i = 0; i < 20; i++) {
        // Rendering in USD and back is what a currency toggle does *to the
        // view*. It must never be written back to state — and even if it is,
        // rounding at the boundary keeps it stable.
        value = usdToAed.toQuote(usdToAed.toBase(value)).rounded();
      }
      expect(value, stored);
      expect(identical(value.amount, stored.amount) || value == stored, isTrue);
    });

    test('a rate with no exact binary representation still round-trips', () {
      final awkward = ExchangeRate(base: usd, quote: aed, rate: 3.6725);
      var value = const Money(1234.56, aed);
      for (var i = 0; i < 50; i++) {
        value = awkward.toQuote(awkward.toBase(value)).rounded();
      }
      expect(value, const Money(1234.56, aed));
    });

    test('storing in the display currency is what actually loses money', () {
      // This is GRN's model, and the reason the invariant exists: the amount
      // is held in the currency the user is *reading*, rounded to that
      // currency's precision. A toggle then quantises it and converts back.
      double toggle(double storedAed) {
        final shown = usdToAed.toBase(Money(storedAed, aed)).rounded();
        return usdToAed.toQuote(shown).rounded().amount;
      }

      // AED 0.03 shows as USD 0.01, which converts back to AED 0.04.
      // The user changed a view; the data moved.
      expect(toggle(0.03), 0.04);
      expect(toggle(0.05), 0.04);
      expect(toggle(0.01), 0.00);
    });

    test('most amounts do not survive a single toggle under that model', () {
      var moved = 0;
      for (var fils = 1; fils <= 2000; fils++) {
        final stored = fils / 100;
        final shown = usdToAed.toBase(Money(stored, aed)).rounded();
        if (usdToAed.toQuote(shown).rounded().amount != stored) moved++;
      }
      // Measured at ~73% across the first 2000 dirham. Pinned loosely so the
      // test documents the scale without being brittle about the exact count.
      expect(moved / 2000, greaterThan(0.5));
    });

    test('the display-only model is stable for the same amounts', () {
      // Storing locally and converting only to render: the stored value is
      // never written back, so nothing quantises it.
      for (var fils = 1; fils <= 2000; fils++) {
        final stored = Money(fils / 100, aed);
        for (var i = 0; i < 5; i++) {
          usdToAed.toBase(stored).rounded(); // render, discard
        }
        expect(stored.amount, fils / 100);
      }
    });
  });

  group('value semantics', () {
    test('equality, hashCode and copyWith', () {
      expect(usdToAed, ExchangeRate(base: usd, quote: aed, rate: 3.69));
      expect(usdToAed.hashCode,
          ExchangeRate(base: usd, quote: aed, rate: 3.69).hashCode);
      expect(usdToAed, isNot(ExchangeRate(base: usd, quote: aed, rate: 3.7)));
      expect(usdToAed.copyWith(rate: 3.7).rate, 3.7);
      expect(usdToAed.copyWith().base, usd);
    });
  });
}
