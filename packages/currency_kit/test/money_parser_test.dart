import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  const aed = CurrencyCode.aed;
  const parser = MoneyParser();

  group('reads what a person actually types', () {
    test('plain numbers', () {
      expect(parser.tryParse('10', aed), const Money(10, aed));
      expect(parser.tryParse('36.90', aed), const Money(36.9, aed));
      expect(parser.tryParse('  36.9  ', aed), const Money(36.9, aed));
      expect(parser.tryParse('.5', aed), const Money(0.5, aed));
    });

    test('with the currency affix left in', () {
      expect(parser.tryParse('AED 36.90', aed), const Money(36.9, aed));
      expect(parser.tryParse('36.90 AED', aed), const Money(36.9, aed));
      expect(parser.tryParse(r'$36.90', aed), const Money(36.9, aed));
    });

    test('with grouping separators', () {
      expect(parser.tryParse('1,234.50', aed), const Money(1234.5, aed));
      expect(parser.tryParse('1,234,567.50', aed), const Money(1234567.5, aed));
    });

    test('negatives, wherever the sign sits relative to the affix', () {
      expect(parser.tryParse('-36.90', aed), const Money(-36.9, aed));
      expect(parser.tryParse('- 36.90', aed), const Money(-36.9, aed));
      expect(parser.tryParse('AED -36.90', aed), const Money(-36.9, aed));
      expect(parser.tryParse('-AED 36.90', aed), const Money(-36.9, aed));
      expect(parser.tryParse('(36.90)', aed), const Money(-36.9, aed));
      expect(parser.tryParse('36.90-', aed), const Money(36.9, aed),
          reason: 'a trailing minus is not a convention we accept');
    });

    test('Arabic-Indic digits and separator', () {
      expect(parser.tryParse('١٢٣٤٫٥٠', aed), const Money(1234.5, aed));
      expect(parser.tryParse('۳٦٫۹', aed), const Money(36.9, aed));
    });
  });

  group('decimal separator', () {
    test('is inferred when both separators appear', () {
      expect(parser.tryParse('1.234,50', aed), const Money(1234.5, aed));
      expect(parser.tryParse('1,234.50', aed), const Money(1234.5, aed));
    });

    test('a lone comma with three digits after it is grouping', () {
      expect(parser.tryParse('1,234', aed), const Money(1234, aed));
    });

    test('a lone comma with two digits after it is a decimal point', () {
      expect(parser.tryParse('36,90', aed), const Money(36.9, aed));
    });

    test('can be forced', () {
      const european = MoneyParser(decimalSeparator: ',');
      expect(european.tryParse('1.234', aed), const Money(1234, aed));
      expect(european.tryParse('36,9', aed), const Money(36.9, aed));
    });
  });

  group('refuses to guess', () {
    test('returns null for anything that is not a number', () {
      expect(parser.tryParse('', aed), isNull);
      expect(parser.tryParse('   ', aed), isNull);
      expect(parser.tryParse('abc', aed), isNull);
      expect(parser.tryParse('AED', aed), isNull);
      expect(parser.tryParse('.', aed), isNull);
    });

    test('separators alone are not a number', () {
      expect(parser.tryParse(',', aed), isNull);
      expect(parser.tryParse('-', aed), isNull);
      expect(parser.tryParse('-.', aed), isNull);
    });

    test('parse throws where tryParse returns null', () {
      expect(() => parser.parse('abc', aed), throwsFormatException);
      expect(parser.parse('36.9', aed), const Money(36.9, aed));
    });
  });

  group('round-trips with the formatter', () {
    test('anything formatted can be read back', () {
      const formatter = MoneyFormatter.standard;
      for (final amount in [0.0, 36.9, -36.9, 1234567.5, 0.05]) {
        final money = Money(amount, aed);
        final text = formatter.format(money);
        expect(parser.tryParse(text, aed), money, reason: text);
      }
    });
  });
}
