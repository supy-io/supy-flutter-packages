import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restoreFrom copies all cart state from another cart', () {
    final original = FlexiCart<MyCartItem>()
      ..addItems([
        MyCartItem(key: 'i1', id: 'id1', name: 'Item1', price: 5, quantity: 2),
        MyCartItem(key: 'i2', id: 'id2', name: 'Item2', price: 3),
      ])
      ..setNote('Original note')
      ..setDeliveredAt(DateTime.utc(2024, 5))
      ..setMetadataEntry('user', 'Alice')
      ..addValidator(CartNotEmptyValidator()) // mock validator
      ..addZeroQuantity = true;

    final newCart = FlexiCart<MyCartItem>()..restoreFrom(original);

    // Items
    expect(newCart.items.length, equals(2));
    expect(newCart.items.containsKey('i1'), isTrue);
    expect(newCart.items['i1']!.name, equals('Item1'));

    // Groups
    expect(newCart.groups.keys.length, equals(original.groups.keys.length));

    // Note
    expect(newCart.note, equals('Original note'));

    // DeliveredAt
    expect(newCart.deliveredAt, equals(DateTime.utc(2024, 5)));

    // Metadata
    expect(newCart.metadata['user'], equals('Alice'));

    // Zero quantity flag
    expect(newCart.addZeroQuantity, isTrue);

    // Validation errors copied
    expect(
        newCart.validationErrors.keys, equals(original.validationErrors.keys));

    // History should include restoration
    expect(
        newCart.history.last,
        contains('Restored cart from another instance'
            ' - {notified: true} - {notified: false}'));
  });
}

/// Minimal concrete cart item for testing
class MyCartItem extends ICartItem {
  MyCartItem({
    required super.id,
    required super.name,
    required this.key,
    required super.price,
    super.group = 'default',
    super.groupName = 'Default',
    super.quantity = 1,
  });

  @override
  final String key;
}
