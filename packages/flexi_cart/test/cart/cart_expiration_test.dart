import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Expiration', () {
    test('Marks cart as expired after duration', () async {
      final cart = FlexiCart<MockItem>()
        ..setExpiration(const Duration(milliseconds: 100));

      await Future<dynamic>.delayed(const Duration(milliseconds: 150));
      expect(cart.isExpired, isTrue);
    });

    test('Doesnt expire before duration', () {
      final cart = FlexiCart<MockItem>()
        ..setExpiration(const Duration(seconds: 1));
      expect(cart.isExpired, isFalse);
    });

    test('Clears expiration after reset', () {
      final cart = FlexiCart<MockItem>()
        ..setExpiration(const Duration(minutes: 5))
        ..reset();
      expect(cart.isExpired, isFalse);
    });

    test('cart expiration check works', () {
      final cart = FlexiCart<MockItem>()
        ..setExpiration(const Duration(milliseconds: 100));
      expect(cart.isExpired, isFalse);

      Future.delayed(const Duration(milliseconds: 150), () {
        expect(cart.isExpired, isTrue);
      });
    });
  });
}
