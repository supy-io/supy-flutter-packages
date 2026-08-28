import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  group('halfUpDecimal — the default', () {
    test('rounds the decimal a person typed, half away from zero', () {
      expect(roundToFractionDigits(412.565, 2), 412.57);
      expect(roundToFractionDigits(-412.565, 2), -412.57);
      expect(roundToFractionDigits(1.005, 2), 1.01);
      expect(roundToFractionDigits(2.675, 2), 2.68);
      expect(roundToFractionDigits(0.145, 2), 0.15);
      expect(roundToFractionDigits(0.125, 2), 0.13);
    });

    test('rounds at zero decimals', () {
      expect(roundToFractionDigits(2.5, 0), 3);
      expect(roundToFractionDigits(-2.5, 0), -3);
      expect(roundToFractionDigits(412.565, 0), 413);
      expect(roundToFractionDigits(1234567.5, 0), 1234568);
    });

    test('leaves values that are already short enough alone', () {
      expect(roundToFractionDigits(36.9, 2), 36.9);
      expect(roundToFractionDigits(0, 2), 0);
      expect(roundToFractionDigits(1234567, 2), 1234567);
    });

    test('keeps the sign on an amount that rounds to zero', () {
      expect(roundToFractionDigits(-0.001, 2).isNegative, isTrue);
      expect(roundToFractionDigits(-0.001, 2), 0);
    });

    test('handles magnitudes that print in exponential form', () {
      expect(roundToFractionDigits(1e-9, 2), 0);
      expect(roundToFractionDigits(1e21, 2), 1e21);
    });
  });

  group('halfUpBinary — for matching a system that already does this', () {
    test('rounds the stored double, so a typed half can go down', () {
      const binary = RoundingMode.halfUpBinary;
      expect(roundToFractionDigits(412.565, 2, mode: binary), 412.56);
      expect(roundToFractionDigits(1.005, 2, mode: binary), 1.0);
      expect(roundToFractionDigits(0.125, 2, mode: binary), 0.13);
    });

    test('differs from the decimal mode on roughly 5% of typed amounts', () {
      var differences = 0;
      for (var thousandths = 0; thousandths < 20000; thousandths++) {
        final value = thousandths / 1000;
        final decimal = roundToFractionDigits(value, 2);
        final binary = roundToFractionDigits(
          value,
          2,
          mode: RoundingMode.halfUpBinary,
        );
        if (decimal != binary) differences++;
      }
      expect(differences / 20000, closeTo(0.05, 0.02));
    });
  });

  group('guards', () {
    test('passes non-finite values through untouched', () {
      expect(roundToFractionDigits(double.nan, 2).isNaN, isTrue);
      expect(roundToFractionDigits(double.infinity, 2), double.infinity);
      expect(
        roundToFractionDigits(double.negativeInfinity, 2),
        double.negativeInfinity,
      );
    });

    test('rejects a precision that cannot be expressed', () {
      expect(() => roundToFractionDigits(1, -1), throwsArgumentError);
      expect(() => roundToFractionDigits(1, 21), throwsArgumentError);
      expect(roundToFractionDigits(1, 20), 1);
    });
  });
}
