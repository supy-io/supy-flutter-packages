import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flexi_cart_test.dart';

void main() {
  final testItem1 = CartItem(
    id: 'item1',
    name: 'Item 1',
    price: 5,
    quantity: 1,
    groupName: 'group',
    image: 'img1',
    unit: 'pcs',
    currency: 'USD',
  );

  final testItem2 = CartItem(
    id: 'item2',
    name: 'Item 2',
    price: 15,
    groupName: 'group',
    quantity: 1,

    image: 'img2',
    unit: 'pcs',
    currency: 'USD',
  );
  group('CartHooks', () {
    test(
      'handleItemAdded should call onItemAdded',
      () {
        var itemAddedCalled = false;
        FlexiCart(
          hooks: CartHooks(
            onItemAdded: (_) => itemAddedCalled = true,
          ),
        ).add(testItem1);
        expect(itemAddedCalled, isTrue);
      },
    );

    test('handleItemDeleted should call onItemDeleted', () {
      var itemDeletedCalled = false;
      FlexiCart(
        hooks: CartHooks(
          onItemDeleted: (_) => itemDeletedCalled = true,
        ),
      )
        ..add(testItem1)
        ..delete(testItem1);

      expect(itemDeletedCalled, isTrue);
    });

    test('handleDisposed should call onDisposed', () {
      var disposedCalled = false;
      FlexiCart(
        hooks: CartHooks(
          onDisposed: () => disposedCalled = true,
        ),
      )
        ..add(testItem1)
        ..delete(testItem1)
        ..dispose();

      expect(disposedCalled, isTrue);
    });
  });
  group('CartHooks Integration with FlexiCart', () {
    test('onItemAdded should be called for each item added', () {
      var callCount = 0;
      FlexiCart(
        hooks: CartHooks(
          onItemAdded: (_) => callCount++,
        ),
      )
        ..add(testItem1)
        ..add(testItem2);

      expect(callCount, equals(2));
    });

    test('onItemDeleted should be called for each item deleted', () {
      var callCount = 0;
      FlexiCart(
        hooks: CartHooks(
          onItemDeleted: (_) => callCount++,
        ),
      )
        ..add(testItem1)
        ..add(testItem2)
        ..delete(testItem1)
        ..delete(testItem2);

      expect(callCount, equals(2));
    });

    test(
        'onDisposed should not be called twice '
        'if dispose is called multiple times', () {
      var callCount = 0;
      FlexiCart(
        hooks: CartHooks(
          onDisposed: () => callCount++,
        ),
      )
        ..dispose()
        ..dispose();

      expect(callCount, equals(1));
    });

    test('onItemAdded and onItemDeleted callbacks should be called in order',
        () {
      final callLog = <String>[];

      FlexiCart(
        hooks: CartHooks(
          onItemAdded: (item) => callLog.add('added:${item.id}'),
          onItemDeleted: (item) => callLog.add('deleted:${item.id}'),
        ),
      )
        ..add(testItem1)
        ..add(testItem2)
        ..delete(testItem1)
        ..delete(testItem2);

      expect(
        callLog,
        equals(
          [
            'added:item1',
            'added:item2',
            'deleted:item1',
            'deleted:item2',
          ],
        ),
      );
    });

    test('no-op CartHooks should not throw on operations', () {
      final cart = FlexiCart(hooks: CartHooks());

      expect(() => cart.add(testItem1), returnsNormally);
      expect(() => cart.delete(testItem1), returnsNormally);
      expect(cart.dispose, returnsNormally);
    });
  });
}
