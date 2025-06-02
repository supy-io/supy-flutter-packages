import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flexi_cart_test.dart';

void main() {
  group('Cart History', () {
    test('logs messages on item add/remove', () {
      final cart = FlexiCart<MockItem>();
      final item = MockItem(id: '1', name: 'item-name', price: 10);

      cart
        ..add(item)
        ..delete(item);
      expect(cart.history.length, 2);
      expect(
        cart.history[0],
        contains('Item added: 1 - {notified: true}'),
      );
      expect(
        cart.history[1],
        contains(
          'Item has been removed: 1 - {notified: true}',
        ),
      );
    });
    test('logs messages on reset/reset items', () {
      final cart = FlexiCart<MockItem>();
      final item = MockItem(id: '1', name: 'item-name', price: 10);

      cart.add(item);
      expect(cart.history[0], contains('Item added: 1'));
      cart.reset();
      expect(cart.history.length, 0);
    });
  });
}
