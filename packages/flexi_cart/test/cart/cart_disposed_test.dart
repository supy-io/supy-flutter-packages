import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Disposed', () {
    late FlexiCart<MockItem> cart;
    setUp(() {
      cart = FlexiCart<MockItem>()
        ..add(MockItem(name: 'item', price: 10, id: '1'))
        ..dispose();
    });

    test('add does not modify items after dispose', () {
      expect(
        () => cart.add(MockItem(name: 'another', price: 5, id: '1')),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });
    test('delete does not affect items after dispose', () {
      expect(
        () => cart.delete(MockItem(name: 'another', price: 5, id: '1')),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });
    test('reset does not clear items after dispose', () {
      expect(
        () => cart.reset(),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });
    test(
      'cart prevents actions',
      () {
        expect(
          () => cart.add(MockItem(name: 'name', price: 1, id: 'a')),
          throwsA(isA<CartDisposedException>()),
        );

        expect(cart.items.length, 1);
      },
    );

    test('addItems throws after dispose', () {
      expect(
        () => cart.addItems([
          MockItem(name: 'item 2', price: 20, id: '2'),
          MockItem(name: 'item 3', price: 30, id: '3'),
        ]),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });

    test('clearItemsGroup throws after dispose', () {
      expect(
        () => cart.clearItemsGroup('group-id'),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });

    test('resetItems throws after dispose', () {
      expect(
        () => cart.resetItems(),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.items.length, 1);
    });

    test('applyExchangeRate throws after dispose', () {
      expect(
        () =>
            cart.applyExchangeRate(const CartCurrency(rate: 3.67, code: 'AED')),
        throwsA(isA<CartDisposedException>()),
      );
      expect(
        cart.cartCurrency,
        isNull,
      ); // Assuming no rate was applied before dispose
    });

    test('removeExchangeRate throws after dispose', () {
      expect(
        () => cart.removeExchangeRate(),
        throwsA(isA<CartDisposedException>()),
      );
      expect(cart.cartCurrency, isNull);
    });

    // test('read operations still work after dispose', () {
    //   expect(cart.items.length, 1);
    //   expect(cart.totalPrice(), 10);
    //   expect(cart.items.('1'), isTrue);
    //   expect(cart.getQuantity('1'), 1);
    //   expect(cart.getItem('1')?.name, 'item');
    // });
  });
}
