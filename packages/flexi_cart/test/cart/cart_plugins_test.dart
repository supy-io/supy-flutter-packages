import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Plugins', () {
    late FlexiCart<MockItem> cart;
    late TestPlugin<MockItem> plugin;
    final item = MockItem(id: '1', name: 'item', price: 10);

    setUp(() {
      cart = FlexiCart<MockItem>();
      plugin = TestPlugin<MockItem>();
      cart.registerPlugin(plugin);
    });

    test('Notifies on change', () {
      cart.add(item);
      expect(plugin.calledMap['onChange'], isTrue);
    });

    test('Notifies on error', () {
      cart.dispose();
      expect(
        () => cart.add(item),
        throwsA(isA<CartDisposedException>()),
      );
      expect(plugin.calledMap['onError'], isTrue);
    });

    test('Notifies on close', () {
      cart.dispose();
      expect(plugin.calledMap['onClose'], isTrue);
    });
  });
}
