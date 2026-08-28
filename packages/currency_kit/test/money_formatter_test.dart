import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  const aed = CurrencyCode.aed;
  const formatter = MoneyFormatter.standard;

  group('the default layout', () {
    test('is code, space, grouped number at currency precision', () {
      expect(formatter.format(const Money(36.9, aed)), 'AED 36.90');
      expect(formatter.format(const Money(1234567.5, aed)), 'AED 1,234,567.50');
      expect(formatter.format(const Money(0, aed)), 'AED 0.00');
    });

    test('puts the minus on the number, not the code', () {
      expect(formatter.format(const Money(-36.9, aed)), 'AED -36.90');
    });

    test('never renders a negative zero', () {
      expect(formatter.format(const Money(-0.001, aed)), 'AED 0.00');
    });

    test('takes precision from the currency', () {
      expect(
          formatter.format(const Money(1234.5, CurrencyCode.jpy)), 'JPY 1,235');
      expect(formatter.format(const Money(1234.5, CurrencyCode.kwd)),
          'KWD 1,234.500');
    });
  });

  group('affix', () {
    test('can be the symbol, the code, or nothing', () {
      const registry = CustomCurrencyRegistry(symbols: {'AED': 'د.إ'});
      const symbolic = MoneyFormatter(registry: registry);
      expect(
        symbolic.format(const Money(36.9, aed),
            const MoneyFormat(affix: MoneyAffix.symbol)),
        'د.إ 36.90',
      );
      expect(
          formatter.format(const Money(36.9, aed), MoneyFormat.plain), '36.90');
      expect(formatter.format(const Money(-36.9, aed), MoneyFormat.plain),
          '-36.90');
    });

    test('can trail the number', () {
      expect(
        formatter.format(
          const Money(36.9, aed),
          const MoneyFormat(affixPosition: MoneyAffixPosition.trailing),
        ),
        '36.90 AED',
      );
      expect(
        formatter.format(
          const Money(-36.9, aed),
          const MoneyFormat(affixPosition: MoneyAffixPosition.trailing),
        ),
        '-36.90 AED',
      );
    });

    test('sign can lead the whole thing instead', () {
      expect(
        formatter.format(
          const Money(-36.9, aed),
          const MoneyFormat(signPosition: MoneySignPosition.beforeAffix),
        ),
        '-AED 36.90',
      );
    });

    test('separator is configurable', () {
      expect(
        formatter.format(
            const Money(36.9, aed), const MoneyFormat(separator: '')),
        'AED36.90',
      );
    });
  });

  group('options', () {
    test('precision can be overridden per call', () {
      expect(
        formatter.format(
            const Money(36.899, aed), const MoneyFormat(fractionDigits: 3)),
        'AED 36.899',
      );
      expect(
        formatter.format(
            const Money(36.9, aed), const MoneyFormat(fractionDigits: 0)),
        'AED 37',
      );
    });

    test('grouping can be turned off', () {
      expect(
        formatter.format(
            const Money(1234567.5, aed), const MoneyFormat(grouping: false)),
        'AED 1234567.50',
      );
    });

    test('compact abbreviates large amounts', () {
      expect(formatter.format(const Money(1234567, aed), MoneyFormat.compacted),
          startsWith('AED 1.2'));
      expect(formatter.format(const Money(999, aed), MoneyFormat.compacted),
          'AED 999');
    });

    test('locale drives digits and separators', () {
      expect(
        formatter.format(
            const Money(1234.5, aed), const MoneyFormat(locale: 'de')),
        'AED 1.234,50',
      );
    });
  });

  group('rounding happens once, here', () {
    test('rounds the typed decimal half away from zero', () {
      expect(formatter.format(const Money(412.565, aed)), 'AED 412.57');
      expect(formatter.format(const Money(412.575, aed)), 'AED 412.58');
      expect(formatter.format(const Money(0.125, aed)), 'AED 0.13');
      expect(formatter.format(const Money(1.005, aed)), 'AED 1.01');
    });

    test('the binary rule is available for parity with other systems', () {
      expect(
        formatter.format(
          const Money(412.565, aed),
          const MoneyFormat(rounding: RoundingMode.halfUpBinary),
        ),
        'AED 412.56',
      );
    });
  });

  group('registry', () {
    test('an app-wide precision override beats the currency', () {
      const flat = MoneyFormatter(
        registry: CustomCurrencyRegistry(fractionDigitsForAll: 2),
      );
      expect(
          flat.format(const Money(1234.5, CurrencyCode.kwd)), 'KWD 1,234.50');
      expect(
          flat.format(const Money(1234.5, CurrencyCode.jpy)), 'JPY 1,234.50');
    });

    test('a per-currency override beats the app-wide one', () {
      const registry = CustomCurrencyRegistry(
        fractionDigitsForAll: 2,
        fractionDigits: {'KWD': 3},
      );
      expect(registry.fractionDigitsOf(CurrencyCode.kwd), 3);
      expect(registry.fractionDigitsOf(CurrencyCode.jpy), 2);
    });

    test('falls through to ISO when nothing overrides', () {
      const registry = CustomCurrencyRegistry();
      expect(registry.fractionDigitsOf(CurrencyCode.kwd), 3);
      expect(registry.symbolOf(CurrencyCode.aed), 'AED');
    });

    test('defaults can be baked into a formatter instance', () {
      const trailing = MoneyFormatter(
        defaults: MoneyFormat(affixPosition: MoneyAffixPosition.trailing),
      );
      expect(trailing.format(const Money(36.9, aed)), '36.90 AED');
    });
  });

  group('MoneyFormat.copyWith', () {
    test('replaces only what it is given', () {
      const base = MoneyFormat(locale: 'de', fractionDigits: 3);
      expect(base.copyWith(compact: true).locale, 'de');
      expect(base.copyWith(compact: true).fractionDigits, 3);
      expect(base.copyWith(grouping: false).grouping, isFalse);
      expect(base.copyWith().affix, MoneyAffix.code);
      expect(base.copyWith(separator: '-').separator, '-');
      expect(
        base.copyWith(rounding: RoundingMode.halfUpBinary).rounding,
        RoundingMode.halfUpBinary,
      );
      expect(
        base.copyWith(affixPosition: MoneyAffixPosition.trailing).affixPosition,
        MoneyAffixPosition.trailing,
      );
      expect(
        base.copyWith(signPosition: MoneySignPosition.beforeAffix).signPosition,
        MoneySignPosition.beforeAffix,
      );
    });
  });
}
