import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Metadata', () {
    test('Initial metadata is empty and unmodifiable', () {
      final cart = FlexiCart<MockItem>();
      expect(cart.metadata, isEmpty);
      expect(() => cart.metadata['newKey'] = 'value', throwsUnsupportedError);
    });

    test('set/get/remove metadata entry works correctly', () {
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

    test('should add, overwrite, and retrieve metadata', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('coupon', 'SAVE20')
        ..setMetadataEntry('userId', 123);
      expect(cart.metadata['coupon'], equals('SAVE20'));
      expect(cart.metadata['userId'], equals(123));

      cart.setMetadataEntry('coupon', 'SAVE50');
      expect(cart.metadata['coupon'], equals('SAVE50'));
    });

    test('reset should clear metadata', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('coupon', 'SAVE20')
        ..reset();
      expect(cart.metadata['coupon'], isNull);
    });

    test('should not fail on removing nonexistent key', () {
      final cart = FlexiCart<MockItem>();
      expect(() => cart.removeMetadataEntry('notExist'), returnsNormally);
    });

    test('getMetadataEntry returns typed value or null', () {
      final cart = FlexiCart<MockItem>()..setMetadataEntry('price', 9.99);
      expect(cart.getMetadataEntry<double>('price'), 9.99);

      cart.setMetadataEntry('quantity', 5);
      expect(cart.getMetadataEntry<int>('quantity'), 5);
      expect(cart.getMetadataEntry<int>('missing'), isNull);
    });

    test('addMetadataEntries adds multiple entries', () {
      final cart = FlexiCart<MockItem>()
        ..addMetadataEntries({'a': 1, 'b': true});
      expect(cart.metadata.length, 2);
      expect(cart.metadata['a'], 1);
      expect(cart.metadata['b'], true);
    });

    test('clearAllMetadata clears all keys', () {
      final cart = FlexiCart<MockItem>()
        ..setMetadataEntry('x', 1)
        ..setMetadataEntry('y', 2)
        ..clearAllMetadata();
      expect(cart.metadata, isEmpty);
    });

    test('shouldNotifyListeners triggers notifyListeners', () {
      final cart = FlexiCart<MockItem>();
      var notified = false;
      cart
        ..addListener(() => notified = true)
        ..setMetadataEntry(
          'k',
          1,
        );
      expect(notified, isTrue);
    });

    test('shouldNotifyListeners is false by default for batch add', () {
      final cart = FlexiCart<MockItem>();
      var notified = false;
      cart
        ..addListener(() => notified = true)
        ..addMetadataEntries({'a': 1, 'b': 2});
      expect(notified, isFalse);
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
