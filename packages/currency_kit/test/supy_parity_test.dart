// Parity goldens for the app this package was extracted from.
//
// Every expectation below was RECORDED from the live implementation in
// supy-mobile (`apps/retailer/lib/common/extensions/src/string_extension.dart`
// `String.format`, over `ExDouble.toPrecision`) before any of it moved here.
// They exist so the migration is a refactor and not a redesign — if one of
// these changes, a price on a user's screen changed.
//
// The app's rounding is an epsilon-nudged half-up: multiply by 10^n, add a
// relative epsilon of 1e-10, round. `RoundingMode.halfUpDecimal` reproduces it
// exactly across 300k typed amounts, without the fudge factor — and without
// the over-rounding the epsilon causes on large computed values.
import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  const aed = CurrencyCode.aed;
  const formatter = MoneyFormatter.standard;

  String format(double amount, int digits) => formatter.format(
        Money(amount, aed),
        MoneyFormat(fractionDigits: digits),
      );

  group('recorded from the retailer app, precision 2', () {
    test('matches', () {
      expect(format(0, 2), 'AED 0.00');
      expect(format(36.9, 2), 'AED 36.90');
      expect(format(-36.9, 2), 'AED -36.90');
      expect(format(412.565, 2), 'AED 412.57');
      expect(format(412.575, 2), 'AED 412.58');
      expect(format(1234567.5, 2), 'AED 1,234,567.50');
    });
  });

  group('recorded from the retailer app, precision 0', () {
    test('matches', () {
      expect(format(0, 0), 'AED 0');
      expect(format(36.9, 0), 'AED 37');
      expect(format(-36.9, 0), 'AED -37');
      expect(format(412.565, 0), 'AED 413');
      expect(format(412.575, 0), 'AED 413');
      expect(format(1234567.5, 0), 'AED 1,234,568');
    });
  });

  group('recorded from the retailer app, precision 3', () {
    test('matches', () {
      expect(format(0, 3), 'AED 0.000');
      expect(format(36.9, 3), 'AED 36.900');
      expect(format(-36.9, 3), 'AED -36.900');
      expect(format(412.565, 3), 'AED 412.565');
      expect(format(1234567.5, 3), 'AED 1,234,567.500');
      expect(format(-0.001, 3), 'AED -0.001');
    });
  });

  group('deliberate deviations from the recorded behaviour', () {
    test('an amount that rounds to zero loses its sign entirely', () {
      // The app renders '-AED 0.00' here: its negative-sign special case is
      // guarded by `rounded < 0`, which is false for -0.0, so the value falls
      // through to intl's own layout — a different layout from every other
      // negative on the same screen. Rendering a signless zero is the fix.
      expect(format(-0.001, 2), 'AED 0.00');
      expect(format(-0.001, 0), 'AED 0');
    });

    test('the sign stays put for amounts that do not round away', () {
      expect(format(-0.005, 2), 'AED -0.01');
    });
  });

  group('the supplier-currency rates the dev backend actually serves', () {
    // "Test Supplier Mobile": USD @ 3.67, SYP @ 0.02608923, on an AED
    // retailer. Mirrors apps/retailer/test/common/utils/exchange_rates_test.
    final usd = ExchangeRate(base: CurrencyCode.usd, quote: aed, rate: 3.67);
    final syp = ExchangeRate(
      base: CurrencyCode.syp,
      quote: aed,
      rate: 0.02608923,
    );

    test('USD: 367 AED renders as 100 USD', () {
      expect(usd.toBase(const Money(367, aed)).rounded().amount, 100);
    });

    test('SYP: a tiny rate keeps its precision', () {
      expect(
        syp.toBase(const Money(2.608923, aed)).amount,
        closeTo(100, 1e-6),
      );
    });

    test('an identity rate leaves the amount alone', () {
      expect(
        const ExchangeRate.identity(aed).toBase(const Money(42.5, aed)).amount,
        42.5,
      );
    });
  });
}
