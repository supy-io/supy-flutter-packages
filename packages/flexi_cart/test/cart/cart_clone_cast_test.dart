import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Clone & Cast', () {
    late FlexiCart originalCart;
    final item = MockItem(id: '1', name: 'item', price: 10);

    setUp(() {
      originalCart = FlexiCart<MockItem>()
        ..add(item)
        ..setMetadata('key', 'value')
        ..setNote('note');
    });

    test('Clone creates independent copy', () {
      final clone = originalCart.clone()
        ..add(MockItem(id: '2', name: 'item2', price: 20));
      expect(originalCart.items.length, 1);
      expect(clone.items.length, 2);
      expect(identical(clone, originalCart), false);
    });

    test('Cast maintains data integrity', () {
      final castCart = originalCart.cast<MockItem>();
      expect(castCart.items.values.first, isA<MockItem>());
      expect(castCart.metadata['key'], 'value');
    });

    test('Clone preserves metadata', () {
      final clone = originalCart.clone();
      expect(clone.metadata['key'], 'value');
    });
    test('Clone and cast cart', () {
      final cart = FlexiCart<MockItem>()
        ..add(MockItem(id: 'x', price: 5, name: 'name'));
      final cloned = cart.clone();

      expect(cloned.items.length, 1);
      expect(cloned.getItemsGroupLength('default'), 1);

      final casted = cart.cast<MockItem>();
      expect(casted, isA<FlexiCart<MockItem>>());
    });
    test('Cart cast changes type', () {
      final item = MockItem(
        id: 'item2',
        price: 200,
        name: 'Orange',
        groupId: 'A',
      );
      final cart = FlexiCart<MockItem>()..add(item);
      final casted = cart.cast<MockItem>();
      expect(casted.items.length, 1);
    });

    test(
      'Cart casting',
      () {
        final cart = FlexiCart<ICartItem>(
          items: {'item1': MockCartItem(), 'item2': MockCartItem2()},
          groups: {
            'group1': CartItemsGroup<ICartItem>(
              id: 'group1',
              name: 'group1',
              items: {
                'item3': MockCartItem(),
                'item4': MockCartItem2(),
              },
            ),
          },
        );

        final castedCart = cart.cast<MockCartItem>();

        expect(
          castedCart.items,
          {
            'item1': isA<MockCartItem>(),
            'item2': isA<MockCartItem>(),
          },
        );
        expect(
          castedCart.groups,
          {
            'group1': isA<CartItemsGroup<MockCartItem>>(),
          },
        );
        expect(
          castedCart.groups.values.first.items,
          {
            'item3': isA<MockCartItem>(),
            'item4': isA<MockCartItem>(),
          },
        );
      },
    );

    test(
      'Cart cloning with mocking',
      () {
        final cart = FlexiCart();
        final item = MockCartItem();
        when(() => item.key).thenReturn('key');
        when(() => item.group).thenReturn('group');
        when(() => item.groupName).thenReturn('groupName');
        when(() => item.quantity).thenReturn(1);
        when(item.totalPrice).thenReturn(10);
        when(item.notNullQty).thenReturn(1);

        cart
          ..addZeroQuantity = true
          ..setDeliveredAt(DateTime.now())
          ..setNote('note')
          ..removeItemCondition = (item) {
            return false;
          }
          ..add(item);

        final clonedCart = cart.clone();

        expect(clonedCart.items, isNotEmpty);
        expect(clonedCart.groups, isNotEmpty);
        expect(clonedCart.totalPrice(), equals(10.0));
        expect(clonedCart.totalQuantity(), equals(1));
        expect(clonedCart.addZeroQuantity, isTrue);
        expect(clonedCart.deliveredAt, isNotNull);
        expect(clonedCart.note, equals('note'));
        expect(clonedCart.removeItemCondition, isNotNull);
      },
    );

    test(
      'Cart casting wtih mock',
      () {
        final cart = FlexiCart<ICartItem>(
          items: {'item1': MockCartItem(), 'item2': MockCartItem2()},
          groups: {
            'group1': CartItemsGroup<ICartItem>(
              id: 'group1',
              name: 'group1',
              items: {
                'item3': MockCartItem(),
                'item4': MockCartItem2(),
              },
            ),
          },
        );

        final castedCart = cart.cast<MockCartItem>();

        expect(
          castedCart.items,
          {
            'item1': isA<MockCartItem>(),
            'item2': isA<MockCartItem>(),
          },
        );
        expect(
          castedCart.groups,
          {
            'group1': isA<CartItemsGroup<MockCartItem>>(),
          },
        );
        expect(
          castedCart.groups.values.first.items,
          {
            'item3': isA<MockCartItem>(),
            'item4': isA<MockCartItem>(),
          },
        );
      },
    );
  });
}
