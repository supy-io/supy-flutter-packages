import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Metadata', () {
    test('Metadata set/get/remove works correctly', () {
      final cart = FlexiCart<MockItem>()..setMetadata('coupon', 'SAVE10');
      expect(cart.getMetadata<String>('coupon'), 'SAVE10');
      cart.removeMetadata('coupon');
      expect(cart.getMetadata<String>('coupon'), isNull);
    });

    test('should remove metadata key', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadata('session', 'abc-123')
        ..removeMetadata('session');

      expect(cart.metadata.containsKey('session'), isFalse);
    });

    test('should add and retrieve metadata', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadata('coupon', 'SAVE20')
        ..setMetadata('userId', 123);

      expect(cart.metadata['coupon'], equals('SAVE20'));
      expect(cart.metadata['userId'], equals(123));
    });

    test('should overwrite metadata key', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadata('coupon', 'SAVE20')
        ..setMetadata('coupon', 'SAVE50');

      expect(cart.metadata['coupon'], equals('SAVE50'));
    });
    test('should reset metadata ', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadata('coupon', 'SAVE20')
        ..setMetadata('coupon', 'SAVE50')
        ..reset();

      expect(cart.metadata['coupon'], isNull);
    });

    test('should not fail on removing nonexistent key', () {
      final cart = FlexiCart<MockItem>();

      expect(() => cart.removeMetadata('notExist'), returnsNormally);
    });

    test('should notify listeners when metadata changes', () {
      final cart = FlexiCart<MockItem>();

      var notifyCount = 0;
      cart
        ..addListener(() => notifyCount++)
        ..setMetadata('flag', true)
        ..removeMetadata('flag');

      expect(notifyCount, equals(2));
    });

    test('should persist metadata in clone', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadata('note', 'Handle with care');

      final clone = cart.clone();
      expect(clone.metadata['note'], equals('Handle with care'));
    });
  });
}
