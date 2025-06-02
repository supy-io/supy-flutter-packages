import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Metadata', () {
    test('Metadata set/get/remove works correctly', () {
      final cart = FlexiCart<MockItem>()..setMetadataEntry('coupon', 'SAVE10');
      expect(cart.getMetadataEntry<String>('coupon'), 'SAVE10');
      cart.removeMetadataEntry('coupon');
      expect(cart.getMetadataEntry<String>('coupon'), isNull);
    });

    test('should remove metadata key', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('session', 'abc-123')
        ..removeMetadataEntry('session');

      expect(cart.metadata.containsKey('session'), isFalse);
    });

    test('should add and retrieve metadata', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('coupon', 'SAVE20')
        ..setMetadataEntry('userId', 123);

      expect(cart.metadata['coupon'], equals('SAVE20'));
      expect(cart.metadata['userId'], equals(123));
    });

    test('should overwrite metadata key', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('coupon', 'SAVE20')
        ..setMetadataEntry('coupon', 'SAVE50');

      expect(cart.metadata['coupon'], equals('SAVE50'));
    });
    test('should reset metadata ', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('coupon', 'SAVE20')
        ..setMetadataEntry('coupon', 'SAVE50')
        ..reset();

      expect(cart.metadata['coupon'], isNull);
    });

    test('should not fail on removing nonexistent key', () {
      final cart = FlexiCart<MockItem>();

      expect(() => cart.removeMetadataEntry('notExist'), returnsNormally);
    });

    test('should notify listeners when metadata changes', () {
      final cart = FlexiCart<MockItem>();

      var notifyCount = 0;
      cart
        ..addListener(() => notifyCount++)
        ..setMetadataEntry('flag', true)
        ..removeMetadataEntry('flag');

      expect(notifyCount, equals(2));
    });

    test('should persist metadata in clone', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('note', 'Handle with care');

      final clone = cart.clone();
      expect(clone.metadata['note'], equals('Handle with care'));
    });
  });
}
