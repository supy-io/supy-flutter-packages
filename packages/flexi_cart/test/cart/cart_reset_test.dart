import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Reset', () {
    late FlexiCart<MockItem> cart;
    late MockCallbackFunction mockCallback;
    final item = MockItem(id: '1', name: 'item', price: 10);

    setUp(() {
      mockCallback = MockCallbackFunction();
      cart = FlexiCart<MockItem>()
        ..add(item)
        ..setMetadata('test', 'value')
        ..setNote('note');
    });

    test('Reset items clears cart but keeps metadata', () {
      cart.resetItems();
      expect(cart.items, isEmpty);
      expect(cart.metadata, isNotEmpty);
    });

    test('Full reset clears all cart data', () {
      cart.reset();
      expect(cart.items, isEmpty);
      expect(cart.metadata, isEmpty);
      expect(cart.note, isNull);
    });

    test('Reset with shouldNotifyListeners=false', () {
      var notified = false;
      cart
        ..addListener(() => notified = true)
        ..reset(shouldNotifyListeners: false);
      expect(notified, isFalse);
    });
    test('Reset items and cart', () {
      final item = MockItem(
        id: 'item1',
        price: 200,
        name: 'Orange',
        groupId: 'A',
      );
      final item2 = MockItem(
        id: 'item2',
        price: 200,
        name: 'Orange',
        groupId: 'AB',
      );
      final cart = FlexiCart<MockItem>()..add(item);
      expect(cart.isNotEmpty(), true);

      cart.resetItems();
      expect(cart.isEmpty(), true);

      cart
        ..add(item2)
        ..setNote('test')
        ..reset();
      expect(cart.isEmpty(), true);
      expect(cart.note, null);
    });

    test(
      'Reset cart with mock callback',
      () {
        final cart = FlexiCart()..addListener(mockCallback.call);

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
          ..removeItemCondition = (item) {
            return true;
          }
          ..add(item)
          ..reset();

        verify(mockCallback.call).called(4);
        expect(cart.items, isEmpty);
        expect(cart.groups, isEmpty);
        expect(cart.totalPrice(), equals(0.0));
        expect(cart.totalQuantity(), equals(0));
        expect(cart.addZeroQuantity, isFalse);
        expect(cart.deliveredAt, isNull);
        expect(cart.note, isNull);
        expect(cart.removeItemCondition, isNull);

        cart
          ..addZeroQuantity = true
          ..setDeliveredAt(DateTime.now(), shouldNotifyListeners: true)
          ..setNote('note', shouldNotifyListeners: true)
          ..removeItemCondition = (item) {
            return true;
          }
          ..add(item)
          ..reset(shouldNotifyListeners: false);

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
  });
}
