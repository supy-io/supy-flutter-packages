import 'package:currency_kit/currency_kit.dart';
import 'package:test/test.dart';

void main() {
  group('roundToFractionDigits', () {
    test('rounds half away from zero on the binary value', () {
      expect(roundToFractionDigits(0.125, 2), 0.13);
      expect(roundToFractionDigits(-0.125, 2), -0.13);
      expect(roundToFractionDigits(2.5, 0), 3);
      expect(roundToFractionDigits(412.565, 2), 412.56);
    });

    test('passes non-finite values through untouched', () {
      expect(roundToFractionDigits(double.nan, 2).isNaN, isTrue);
      expect(roundToFractionDigits(double.infinity, 2), double.infinity);
      expect(
        roundToFractionDigits(double.negativeInfinity, 2),
        double.negativeInfinity,
      );
    });

    test('rejects a precision toStringAsFixed cannot express', () {
      expect(() => roundToFractionDigits(1, -1), throwsArgumentError);
      expect(() => roundToFractionDigits(1, 21), throwsArgumentError);
      expect(roundToFractionDigits(1, 20), 1);
    });
  });
}
