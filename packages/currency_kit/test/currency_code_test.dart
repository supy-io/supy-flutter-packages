import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  group('CurrencyCode.parse', () {
    test('resolves a known code case-insensitively', () {
      expect(CurrencyCode.parse('AED'), CurrencyCode.aed);
      expect(CurrencyCode.parse('aed'), CurrencyCode.aed);
      expect(CurrencyCode.parse('  usd  '), CurrencyCode.usd);
    });

    test('throws on an unknown code rather than falling back', () {
      expect(
          () => CurrencyCode.parse('XYZ'), throwsA(isA<UnknownCurrencyCode>()));
      expect(() => CurrencyCode.parse(''), throwsA(isA<UnknownCurrencyCode>()));
      expect(
          () => CurrencyCode.parse('AE'), throwsA(isA<UnknownCurrencyCode>()));
    });

    test('names the offending value in the error', () {
      expect(
        () => CurrencyCode.parse('XYZ'),
        throwsA(
          isA<UnknownCurrencyCode>()
              .having((e) => e.value, 'value', 'XYZ')
              .having((e) => e.toString(), 'message', contains('XYZ')),
        ),
      );
    });
  });

  group('CurrencyCode.tryParse', () {
    test('returns null instead of throwing', () {
      expect(CurrencyCode.tryParse('XYZ'), isNull);
      expect(CurrencyCode.tryParse('SYP'), CurrencyCode.syp);
    });
  });

  group('fraction digits follow ISO-4217, not a global default', () {
    test('two decimals is the common case', () {
      expect(CurrencyCode.aed.fractionDigits, 2);
      expect(CurrencyCode.usd.fractionDigits, 2);
      expect(CurrencyCode.parse('SYP').fractionDigits, 2);
    });

    test('zero-decimal currencies', () {
      for (final code in ['JPY', 'KRW', 'VND', 'ISK', 'XAF', 'XOF', 'XPF']) {
        expect(CurrencyCode.parse(code).fractionDigits, 0, reason: code);
      }
    });

    test('three-decimal currencies', () {
      for (final code in ['KWD', 'BHD', 'OMR', 'JOD', 'TND', 'IQD', 'LYD']) {
        expect(CurrencyCode.parse(code).fractionDigits, 3, reason: code);
      }
    });
  });

  group('CurrencyCode.custom', () {
    test('accepts a code the package does not ship', () {
      final points = CurrencyCode.custom('PTS', fractionDigits: 0);
      expect(points.code, 'PTS');
      expect(points.fractionDigits, 0);
      expect(CurrencyCode.isKnown('PTS'), isFalse);
    });

    test('normalizes and validates', () {
      expect(CurrencyCode.custom(' btc ').code, 'BTC');
      expect(() => CurrencyCode.custom(''), throwsArgumentError);
      expect(
        () => CurrencyCode.custom('PTS', fractionDigits: -1),
        throwsArgumentError,
      );
      expect(
        () => CurrencyCode.custom('PTS', fractionDigits: 21),
        throwsArgumentError,
      );
    });
  });

  group('identity', () {
    test('equality is by code and precision', () {
      expect(CurrencyCode.parse('AED'), CurrencyCode.aed);
      expect(CurrencyCode.parse('AED').hashCode, CurrencyCode.aed.hashCode);
      expect(CurrencyCode.aed, isNot(CurrencyCode.usd));
      expect(CurrencyCode.custom('AED', fractionDigits: 3),
          isNot(CurrencyCode.aed));
    });

    test('sorts and prints as the code', () {
      final codes = [CurrencyCode.usd, CurrencyCode.aed, CurrencyCode.eur]
        ..sort();
      expect(codes.map((c) => c.toString()).toList(), ['AED', 'EUR', 'USD']);
    });
  });

  group('the shipped table', () {
    test('covers every code the registry knows', () {
      expect(CurrencyCode.knownCodes, hasLength(159));
      for (final code in CurrencyCode.knownCodes) {
        expect(CurrencyCode.tryParse(code), isNotNull, reason: code);
      }
    });

    test('isKnown is case-insensitive and excludes junk', () {
      expect(CurrencyCode.isKnown('kwd'), isTrue);
      expect(CurrencyCode.isKnown('ZZZ'), isFalse);
    });
  });
}
