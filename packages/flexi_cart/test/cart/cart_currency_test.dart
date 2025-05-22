import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Currency', () {
    late FlexiCart<MockItem> cart;
    const currency = CartCurrency(code: 'EUR', rate: 1.2);
    final items = [
      MockItem(id: '1', name: 'Item1', price: 100),
      MockItem(id: '2', name: 'Item2', price: 200),
    ];

    setUp(() {
      cart = FlexiCart<MockItem>()..addItems(items);
    });

    test('Applies exchange rate correctly', () {
      cart.applyExchangeRate(currency);
      expect(cart.items['1']!.price, 120);
      expect(cart.items['2']!.price, 240);
    });

    test('Restores original prices', () {
      cart
        ..add(MockItem(id: '3', name: 'Item1', price: 100))
        ..applyExchangeRate(currency);
      expect(cart.items['3']!.price, 120);
      cart.removeExchangeRate();
      expect(cart.items['3']!.price, 100);
    });

    test('Handles multiple rate applications', () {
      cart
        ..add(MockItem(id: '4', name: 'Item1', price: 100))
        ..applyExchangeRate(const CartCurrency(rate: 2.0, code: 'AED'))
        ..applyExchangeRate(const CartCurrency(rate: 0.5, code: 'SYP'));
      expect(cart.items['4']!.price, 50);
    });

    test('Multiple same exchange rate ', () {
      final cart = FlexiCart<MockItem>()
        ..add(
          MockItem(
            id: 'item1',
            price: 100,
            name: 'Apple',
            groupId: 'A',
          ),
        )
        ..add(
          MockItem(
            id: 'item2',
            price: 200,
            name: 'Orange',
            groupId: 'A',
          ),
        );

      const currency = CartCurrency(code: 'EUR', rate: 1.2);

      cart
        ..applyExchangeRate(currency) // 100 -> 120
        ..applyExchangeRate(currency) // 120 -> 120
        ..applyExchangeRate(currency) // 120 -> 120
        ..applyExchangeRate(currency) // 120 -> 120
        ..applyExchangeRate(currency); // 120 -> 120

      expect(cart.items['item1']?.price, closeTo(120.0, 0.001));
    });
    test(
      'Reset Currency with reset cart',
      () {
        final cart = FlexiCart<MockItem>()
          ..add(
            MockItem(
              id: 'item1',
              price: 100,
              name: 'Apple',
              groupId: 'A',
            ),
          )
          ..add(
            MockItem(
              id: 'item2',
              price: 200,
              name: 'Orange',
              groupId: 'A',
            ),
          );

        const currency = CartCurrency(code: 'EUR', rate: 1.2);

        cart.applyExchangeRate(currency);
        expect(cart.cartCurrency, isNotNull);
        expect(cart.items['item1']?.price, closeTo(120.0, 0.001));
        expect(cart.items['item2']?.price, closeTo(240.0, 0.001));
        cart.reset();
        expect(cart.items, isEmpty);
        expect(cart.cartCurrency, isNull);
      },
    );
    test('removeExchangeRate does nothing if no currency applied', () {
      final cart = FlexiCart<MockItem>()
        ..add(
          MockItem(
            id: 'item1',
            price: 100,
            name: 'Apple',
            groupId: 'A',
          ),
        )
        ..add(
          MockItem(
            id: 'item2',
            price: 200,
            name: 'Orange',
            groupId: 'A',
          ),
        )
        ..removeExchangeRate(shouldNotifyListeners: false);

      expect(cart.items['item1']?.price, closeTo(100.0, 0.001));
      expect(cart.items['item2']?.price, closeTo(200.0, 0.001));
    });
  });
}
