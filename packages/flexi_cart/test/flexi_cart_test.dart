import 'dart:async';

import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCallbackFunction extends Mock {
  void call();
}

class MockItem extends ICartItem {
  MockItem({
    required super.id,
    required super.name,
    required super.price,
    this.quantityVal = 1,
    this.groupId = 'default',
    this.groupNameVal = 'Default Group',
  }) : super();
  double quantityVal;
  final String groupId;
  final String groupNameVal;

  @override
  String get key => id;

  @override
  double? get quantity => quantityVal;

  @override
  set quantity(double? value) => quantityVal = value ?? 0;

  @override
  String get group => groupId;

  @override
  String get groupName => groupNameVal;

  @override
  double totalPrice() => quantityVal * 10;

  @override
  double notNullQty() => quantityVal;

  @override
  bool operator ==(Object other) =>
      other is MockItem &&
      other.id == id &&
      other.name == name &&
      other.price == price &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(id, name, price, quantity);
}

class MockCartItem extends Mock implements ICartItem {}

class MockCartItem2 extends MockCartItem {}

class TestPlugin<T extends ICartItem> implements ICartPlugin<T> {
  Map<String, bool> calledMap = {
    'onChange': false,
    'onCartChanged': false,
    'onClose': false,
    'onError': false,
  };

  @override
  void onChange(FlexiCart<T> cart) {
    calledMap['onChange'] = true;
  }

  @override
  void onClose(FlexiCart<T> cart) {
    calledMap['onClose'] = true;
  }

  @override
  void onError(FlexiCart<T> cart, Object error, StackTrace stackTrace) {
    calledMap['onError'] = true;
  }
}

class CartItem extends ICartItem {
  CartItem({
    required super.price,
    required super.id,
    required super.name,
    required super.currency,
    super.groupName,
    super.image,
    super.unit = '',
    super.quantity = 0,
  });
}

void main() {
  group(
    'Cart Item',
    () {
      late CartItem cartItem;

      setUp(
        () {
          cartItem = CartItem(
            id: 'id',
            name: 'name',
            price: 10,
            groupName: 'groupName',
            image: 'image',
            unit: 'unit',
            currency: 'currency',
          );
        },
      );

      test(
        'Total price',
        () {
          expect(cartItem.totalPrice(), equals(0.0));
          cartItem.quantity = 3;
          expect(cartItem.totalPrice(), equals(30.0));
        },
      );

      test(
        'Not null quantity',
        () {
          cartItem.quantity = null;
          expect(cartItem.notNullQty(), equals(0.0));
          cartItem.quantity = 1;
          expect(cartItem.notNullQty(), equals(1.0));
        },
      );

      test(
        'Item key',
        () {
          expect(cartItem.key, equals('id'));
        },
      );

      test(
        'Item Group',
        () {
          expect(cartItem.group, equals('All'));
        },
      );

      test(
        'Increment',
        () {
          cartItem.increment();
          expect(cartItem.quantity, equals(1.0));
          cartItem.increment(inc: 2);
          expect(cartItem.quantity, equals(3.0));
        },
      );

      test(
        'Decrement',
        () {
          cartItem
            ..quantity = 1
            ..decrement();
          expect(cartItem.quantity, equals(0.0));
          cartItem.decrement();
          expect(cartItem.quantity, equals(0.0));
        },
      );
    },
  );

  group(
    'Cart item extensions',
    () {
      late final List<ICartItem> items;
      setUpAll(
        () {
          final item1 = MockCartItem();
          final item2 = MockCartItem();
          when(item1.totalPrice).thenReturn(10);
          when(item2.totalPrice).thenReturn(10);
          when(item1.notNullQty).thenReturn(0);
          when(item2.notNullQty).thenReturn(0);
          items = [item1, item2];
        },
      );

      test(
        'Total price',
        () {
          expect(items.totalPrice(), equals(20.0));
        },
      );

      test(
        'Total quantity',
        () {
          expect(items.totalQty(), equals(0.0));
          when(() => items[0].notNullQty()).thenReturn(1);
          expect(items.totalQty(), equals(1.0));
          when(() => items[1].notNullQty()).thenReturn(2);
          expect(items.totalQty(), equals(3.0));
        },
      );
    },
  );

  group(
    'Cart items group',
    () {
      late CartItemsGroup group;
      setUp(
        () {
          group = CartItemsGroup(
            id: 'group-id',
            name: 'group-name',
            items: {},
          );
        },
      );

      test(
        'Add item to group',
        () {
          final item = MockCartItem();
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');

          group.add(item);
          expect(group.items, contains(item.key));
          expect(group.items[item.key]!.notNullQty(), equals(1));
          expect(group.totalPrice(), equals(10.0));
          expect(group.totalQty(), equals(1));
        },
      );

      test(
        'Add item to group with replace false',
        () {
          final item = MockCartItem();
          final item2 = MockCartItem();

          when(item.totalPrice).thenReturn(20);
          when(item.notNullQty).thenReturn(2);
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(item2.totalPrice).thenReturn(10);
          when(item2.notNullQty).thenReturn(1);
          when(() => item2.key).thenReturn('key');
          when(() => item2.group).thenReturn('group');

          group
            ..add(item)
            ..add(item2, replace: false);
          expect(group.items, contains(item.key));
          expect(group.items[item.key]!.notNullQty(), equals(2));
          expect(group.totalPrice(), equals(20.0));
          expect(group.totalQty(), equals(2));
        },
      );

      test(
        'Remove item from group',
        () {
          final item = MockCartItem();
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          group
            ..add(item)
            ..remove(item);
          expect(group.items, isNot(contains(item.key)));
          expect(group.totalPrice(), equals(0.0));
          expect(group.totalQty(), equals(0));
        },
      );

      test('Add multiple items to group', () {
        final item1 = MockCartItem();
        final item2 = MockCartItem();
        when(item1.totalPrice).thenReturn(10);
        when(item2.totalPrice).thenReturn(10);
        when(item1.notNullQty).thenReturn(1);
        when(item2.notNullQty).thenReturn(1);
        when(() => item1.key).thenReturn('key1');
        when(() => item2.key).thenReturn('key2');
        when(() => item1.group).thenReturn('group');
        when(() => item2.group).thenReturn('group');

        group
          ..add(item1)
          ..add(item2);
        expect(group.items, contains(item1.key));
        expect(group.items, contains(item2.key));
        expect(group.totalPrice(), equals(20.0));
        expect(group.totalQty(), equals(2));
      });

      test(
        'Total price',
        () {
          expect(group.totalPrice(), equals(0.0));
          final item = MockCartItem();
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          group.add(item);
          expect(group.totalPrice(), equals(10.0));
        },
      );
    },
  );

  group(
    'Cart',
    () {
      late FlexiCart cart;
      final mockCallback =
          MockCallbackFunction(); // Your callback function mock

      setUp(
        () {
          cart = FlexiCart()..addListener(mockCallback.call);
          reset(mockCallback);
        },
      );

      test(
        'Add item to cart',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);

          cart.add(item);
          verify(mockCallback.call).called(1);

          expect(cart.isNotEmpty(), isTrue);
          expect(cart.isEmpty(), isFalse);
          expect(cart.items, contains(item.key));
          expect(cart.items[item.key]!.quantity, equals(1));
          expect(cart.groups, contains(item.group));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.totalPrice(), equals(10.0));
          expect(cart.totalQuantity(), equals(1));
          expect(cart.groups[item.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item.group]!.totalQty(), equals(1));
        },
      );

      test(
        'Should increment quantity when adding an existing item',
        () {
          final item = CartItem(
            groupName: 'groupName',
            currency: 'currency',
            price: 10,
            quantity: 1,
            id: 'id',
            name: 'name',
          );

          cart
            ..add(item)
            ..add(item, increment: true);

          verify(mockCallback.call).called(2);

          expect(cart.items[item.key]!.quantity, equals(2));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.totalPrice(), equals(20.0));
          expect(cart.totalQuantity(), equals(2));
          expect(cart.groups[item.group]!.totalPrice(), equals(20.0));
          expect(cart.groups[item.group]!.totalQty(), equals(2));
        },
      );

      test(
        'Add item to cart with quantity 0',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(0);
          when(item.totalPrice).thenReturn(0);
          when(item.notNullQty).thenReturn(0);

          cart.add(item);

          verify(mockCallback.call).called(1);
          expect(cart.items, isNot(contains(item.key)));
          expect(cart.groups, isNot(contains(item.group)));
          expect(cart.totalPrice(), equals(0.0));
          expect(cart.totalQuantity(), equals(0));
        },
      );

      test(
        'Add with addZeroQuantity enabled',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(0);

          cart
            ..addZeroQuantity = true
            ..add(item);

          verify(mockCallback.call).called(1);
          expect(cart.items, contains(item.key));
          expect(cart.groups, contains(item.group));
        },
      );

      test('Will never add null qty', () {
        final item = MockCartItem();
        when(() => item.key).thenReturn('key');
        when(() => item.group).thenReturn('group');
        when(() => item.groupName).thenReturn('groupName');
        when(() => item.price).thenReturn(10);
        when(() => item.quantity).thenReturn(null);
        when(item.notNullQty).thenReturn(0);

        cart.add(item);

        verify(mockCallback.call).called(1);
        expect(cart.items, isNot(contains(item.key)));
        expect(cart.groups, isNot(contains(item.group)));
      });

      test('Add item to cart with remove item condition', () {
        final item = MockCartItem();
        when(() => item.key).thenReturn('key');
        when(() => item.group).thenReturn('group');
        when(() => item.groupName).thenReturn('groupName');
        when(() => item.price).thenReturn(9);
        when(() => item.quantity).thenReturn(1);

        cart
          ..removeItemCondition = (item) {
            return item.price < 10.0;
          }
          ..add(item);

        verify(mockCallback.call).called(1);
        expect(cart.items, isNot(contains(item.key)));
        expect(cart.groups, isNot(contains(item.group)));
      });

      test(
        'Adding to the group should not effect others',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key2');
          when(() => item2.group).thenReturn('group2');
          when(() => item2.groupName).thenReturn('groupName2');
          when(() => item2.price).thenReturn(10);
          when(() => item2.quantity).thenReturn(1);
          when(item2.totalPrice).thenReturn(10);
          when(item2.notNullQty).thenReturn(1);

          cart
            ..add(item)
            ..add(item2);

          verify(mockCallback.call).called(2);
          expect(cart.items, contains(item.key));
          expect(cart.items, contains(item2.key));
          expect(cart.groups, contains(item.group));
          expect(cart.groups, contains(item2.group));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.groups[item2.group]!.items.length, equals(1));
          expect(cart.totalPrice(), equals(20.0));
          expect(cart.totalQuantity(), equals(2));
          expect(cart.groups[item.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item.group]!.totalQty(), equals(1));
          expect(cart.groups[item2.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item2.group]!.totalQty(), equals(1));
        },
      );

      test(
        'Add list of items',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key2');
          when(() => item2.group).thenReturn('group2');
          when(() => item2.groupName).thenReturn('groupName2');
          when(() => item2.price).thenReturn(10);
          when(() => item2.quantity).thenReturn(1);
          when(item2.totalPrice).thenReturn(10);
          when(item2.notNullQty).thenReturn(1);

          cart.addItems([item, item2], skipIfExist: true);

          verify(mockCallback.call).called(1);
          expect(cart.items.length, equals(2));
          expect(cart.items, contains(item.key));
          expect(cart.items, contains(item2.key));
          expect(cart.groups, contains(item.group));
          expect(cart.groups, contains(item2.group));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.groups[item2.group]!.items.length, equals(1));
          expect(cart.groups[item.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item2.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item.group]!.totalQty(), equals(1));
          expect(cart.groups[item2.group]!.totalQty(), equals(1));
        },
      );

      test(
        'Add list of items with same key with skipIfExist true',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key');
          when(() => item2.group).thenReturn('group');
          when(() => item2.groupName).thenReturn('groupName');
          when(() => item2.price).thenReturn(20);
          when(() => item2.quantity).thenReturn(10);
          when(item2.totalPrice).thenReturn(10);
          when(item2.notNullQty).thenReturn(1);

          cart
            ..addItems([item])
            ..addItems([item2], skipIfExist: true);

          verify(mockCallback.call).called(2);
          expect(cart.items, contains(item.key));
          expect(cart.items.length, equals(1));
          expect(cart.items[item.key]!.price, equals(10.0));
          expect(cart.items[item.key]!.quantity, equals(1));
          expect(cart.groups, contains(item.group));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.groups[item.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item.group]!.totalQty(), equals(1));
        },
      );

      test(
        'Add list of items with same key with skipIfExist false',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key');
          when(() => item2.group).thenReturn('group');
          when(() => item2.groupName).thenReturn('groupName');
          when(() => item2.price).thenReturn(20);
          when(() => item2.quantity).thenReturn(20);
          when(item2.totalPrice).thenReturn(200);
          when(item2.notNullQty).thenReturn(20);

          cart
            ..addItems([item])
            ..addItems([item2], skipIfExist: false);

          verify(mockCallback.call).called(2);
          expect(cart.items, contains(item.key));
          expect(cart.items.length, equals(1));
          expect(cart.items[item.key]!.price, equals(20));
          expect(cart.items[item.key]!.quantity, equals(20));
          expect(cart.groups, contains(item.group));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.groups[item.group]!.totalPrice(), equals(200));
          expect(cart.groups[item.group]!.totalQty(), equals(20));
        },
      );

      test('Delete item', () {
        final item = MockCartItem();
        when(() => item.key).thenReturn('key');
        when(() => item.group).thenReturn('group');
        when(() => item.groupName).thenReturn('groupName');
        when(() => item.price).thenReturn(10);
        when(() => item.quantity).thenReturn(1);
        when(item.totalPrice).thenReturn(10);
        when(item.notNullQty).thenReturn(1);

        cart
          ..add(item)
          ..delete(item);

        verify(mockCallback.call).called(2);
        expect(cart.items, isNot(contains(item.key)));
        expect(cart.groups, isNot(contains(item.group)));
      });

      test('Adding with null qty will delete the item', () {
        final item = MockCartItem();
        when(() => item.key).thenReturn('key');
        when(() => item.group).thenReturn('group');
        when(() => item.groupName).thenReturn('groupName');
        when(() => item.price).thenReturn(10);
        when(() => item.quantity).thenReturn(1);
        when(item.totalPrice).thenReturn(10);
        when(item.notNullQty).thenReturn(1);

        cart.add(item);
        when(() => item.quantity).thenReturn(null);
        when(item.notNullQty).thenReturn(0);
        cart.add(item);

        verify(mockCallback.call).called(2);
        expect(cart.items, isNot(contains(item.key)));
        expect(cart.groups, isNot(contains(item.group)));
      });

      test(
        'Removing effects group',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key2');
          when(() => item2.group).thenReturn('group2');
          when(() => item2.groupName).thenReturn('groupName2');
          when(() => item2.price).thenReturn(20);
          when(() => item2.quantity).thenReturn(20);
          when(item2.totalPrice).thenReturn(200);
          when(item2.notNullQty).thenReturn(20);

          cart.addItems([item, item2]);
          expect(cart.groups.length, equals(2));

          cart.delete(item);
          expect(cart.groups[item.group], isNull);
          expect(cart.groups.length, equals(1));

          cart.delete(item2);
          expect(cart.groups[item2.group], isNull);
          expect(cart.groups.length, equals(0));

          verify(mockCallback.call).called(3);
        },
      );

      test(
        'Remove items not in list',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.price).thenReturn(10);
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);
          final item2 = MockCartItem();
          when(() => item2.key).thenReturn('key2');
          when(() => item2.group).thenReturn('group2');
          when(() => item2.groupName).thenReturn('groupName2');
          when(() => item2.price).thenReturn(10);
          when(() => item2.quantity).thenReturn(1);
          when(item2.totalPrice).thenReturn(10);
          when(item2.notNullQty).thenReturn(1);

          cart
            ..addItems([item2, item])
            ..removeItemsNotInList([item]);

          verify(mockCallback.call).called(2);
          expect(cart.items, contains(item.key));
          expect(cart.items, isNot(contains(item2.key)));
          expect(cart.groups, contains(item.group));
          expect(cart.groups, isNot(contains(item2.group)));
          expect(cart.groups[item.group]!.items.length, equals(1));
          expect(cart.groups[item.group]!.totalPrice(), equals(10.0));
          expect(cart.groups[item.group]!.totalQty(), equals(1));
        },
      );

      test(
        'Add delivered at',
        () {
          expect(cart.deliveredAt, isNull);
          cart.setDeliveredAt(DateTime.now(), shouldNotifyListeners: true);
          expect(cart.deliveredAt, isNotNull);
          expect(cart.deliveredAt, isA<DateTime>());

          verify(mockCallback.call).called(1);
        },
      );

      test(
        'Add note',
        () {
          expect(cart.note, isNull);
          cart.setNote('note', shouldNotifyListeners: true);

          expect(cart.note, equals('note'));
          verify(mockCallback.call).called(1);
        },
      );

      test(
        'Check for large qty',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);

          cart.add(item);

          expect(cart.checkForLargeValue, isFalse);

          when(item.notNullQty).thenReturn(100);
          cart.add(item);

          expect(cart.checkForLargeValue, isTrue);
        },
      );

      test(
        'Cart in initial state',
        () {
          expect(cart.items, isEmpty);
          expect(cart.groups, isEmpty);
          expect(cart.totalPrice(), equals(0.0));
          expect(cart.totalQuantity(), equals(0));
          expect(cart.checkForLargeValue, isFalse);
          expect(cart.addZeroQuantity, isFalse);
          expect(cart.deliveredAt, isNull);
          expect(cart.note, isNull);
          expect(cart.removeItemCondition, isNull);
        },
      );

      test(
        'Reset items',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);

          cart
            ..setDeliveredAt(DateTime.now(), shouldNotifyListeners: true)
            ..setNote('note', shouldNotifyListeners: true);

          cart.addZeroQuantity = true;
          cart.removeItemCondition = (item) => false;

          cart
            ..add(item)
            ..resetItems();

          verify(mockCallback.call).called(4);
          expect(cart.items, isEmpty);
          expect(cart.groups, isEmpty);
          expect(cart.deliveredAt, isNotNull);
          expect(cart.note, equals('note'));
          expect(cart.addZeroQuantity, isTrue);
          expect(cart.removeItemCondition, isNotNull);

          cart
            ..add(item)
            ..resetItems(shouldNotifyListeners: false);

          verify(mockCallback.call).called(1);
          expect(cart.items, isEmpty);
          expect(cart.groups, isEmpty);
          expect(cart.deliveredAt, isNotNull);
          expect(cart.note, equals('note'));
          expect(cart.addZeroQuantity, isTrue);
          expect(cart.removeItemCondition, isNotNull);
        },
      );

      test(
        'Reset cart',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);

          cart
            ..addZeroQuantity = true
            ..setDeliveredAt(DateTime.now(), shouldNotifyListeners: true)
            ..setNote('note', shouldNotifyListeners: true)
            ..removeItemCondition = (item) => true;

          cart.add(item);
          cart.reset();

          verify(mockCallback.call).called(4);
          expect(cart.items, isEmpty);
          expect(cart.groups, isEmpty);
          expect(cart.totalPrice(), equals(0.0));
          expect(cart.totalQuantity(), equals(0));
          expect(cart.addZeroQuantity, isFalse);
          expect(cart.deliveredAt, isNull);
          expect(cart.note, isNull);
          expect(cart.removeItemCondition, isNull);

          cart.addZeroQuantity = true;
          cart.setDeliveredAt(DateTime.now(), shouldNotifyListeners: true);
          cart
            ..setNote('note', shouldNotifyListeners: true)
            ..removeItemCondition = (item) => true;

          cart.add(item);
          cart.reset(shouldNotifyListeners: false);

          verify(mockCallback.call).called(3);
          expect(cart.items, isEmpty);
          expect(cart.groups, isEmpty);
          expect(cart.totalPrice(), equals(0.0));
          expect(cart.totalQuantity(), equals(0));
          expect(cart.addZeroQuantity, isFalse);
          expect(cart.deliveredAt, isNull);
          expect(cart.note, isNull);
          expect(cart.removeItemCondition, isNull);
        },
      );

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
        'Cart cloning',
        () {
          final item = MockCartItem();
          when(() => item.key).thenReturn('key');
          when(() => item.group).thenReturn('group');
          when(() => item.groupName).thenReturn('groupName');
          when(() => item.quantity).thenReturn(1);
          when(item.totalPrice).thenReturn(10);
          when(item.notNullQty).thenReturn(1);

          cart.addZeroQuantity = true;
          cart.setDeliveredAt(DateTime.now());
          cart.setNote('note');
          cart.removeItemCondition = (item) => false;

          cart.add(item);

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
        'Dispose callback',
        () {
          cart = FlexiCart(onDisposed: mockCallback.call)..dispose();

          verify(mockCallback.call).called(1);
        },
      );
    },
  );
  test('logs messages on item add/remove', () {
    final cart = FlexiCart<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);

    cart
      ..add(item)
      ..delete(item);
    expect(cart.logs.length, 2);
    expect(
      cart.logs[0],
      contains('Item added: 1 - {notified: true}'),
    );
    expect(
      cart.logs[1],
      contains(
        'Item has been removed: 1 - {notified: true}',
      ),
    );
  });
  test('logs messages on reset/reset items', () {
    final cart = FlexiCart<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);

    cart
      ..add(item)
      ..resetItems()
      ..reset();

    expect(cart.logs.length, 3);
    expect(cart.logs[0], contains('Item added: 1'));
    expect(cart.logs[1], contains('Items have been reset: [$item]'));
    expect(
      cart.logs[2],
      contains('Cart has been reset:\n'
          '- groups: {}\n'
          '- items: {}\n'
          '- deliveredAt: null\n'
          '- expiresAt: null - {notified: true}'),
    );
  });

  test('cart expiration check works', () {
    final cart = FlexiCart<MockItem>()
      ..setExpiration(const Duration(milliseconds: 100));
    expect(cart.isExpired, isFalse);

    // Delay long enough to trigger expiration
    Future.delayed(const Duration(milliseconds: 150), () {
      expect(cart.isExpired, isTrue);
    });
  });

  test('plugin is notified on cart change', () {
    final cart = FlexiCart<MockItem>();
    final plugin = TestPlugin<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);
    cart
      ..registerPlugin(plugin)
      ..add(item);

    expect(plugin.calledMap['onChange'], isTrue);
  });
  test('plugin is notified on cart onCartChanged', () {
    final cart = FlexiCart<MockItem>();
    final plugin = TestPlugin<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);
    cart
      ..registerPlugin(plugin)
      ..add(item);

    expect(plugin.calledMap['onCartChanged'], isTrue);
  });
  test('plugin is notified on cart onClose', () {
    final cart = FlexiCart<MockItem>();
    final plugin = TestPlugin<MockItem>();
    cart
      ..registerPlugin(plugin)
      ..dispose();

    expect(plugin.calledMap['onClose'], isTrue);
  });
  test('plugin is notified on cart onError', () {
    final cart = FlexiCart<MockItem>();
    final plugin = TestPlugin<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);

    cart
      ..registerPlugin(plugin)
      ..dispose()
      ..add(item);

    expect(plugin.calledMap['onError'], isTrue);
  });

  test('cart lock prevents modification', () {
    final cart = FlexiCart<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);

    cart.lock();
    expect(cart.isLocked, isTrue);

    expect(() => cart.add(item), throwsStateError);
    expect(() => cart.delete(item), throwsStateError);

    cart.unlock();
    expect(cart.isLocked, isFalse);

    // Should work after unlock
    cart.add(item);
    expect(cart.items.length, 1);
  });
}
