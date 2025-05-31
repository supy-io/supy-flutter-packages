import 'package:flexi_cart/flexi_cart.dart';
import 'package:test/test.dart';

import '../../helpers/mocks.dart';

void main() {
  group('FlexiCart with BehaviorOptions', () {
    test('should prevent item addition via itemFilter', () {
      final item = CartItem(
        id: 'item1',
        name: 'Test Item',
        price: 100,
        currency: 'USD',
      );
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            itemFilter: (item) => false,
          ),
        ),
      )..add(item, shouldNotifyListeners: false);
      expect(cart.isEmpty(), isTrue);
    });

    test('should override item price via priceResolver', () {
      final item = CartItem(
        id: 'id1',
        name: 'Test Item',
        price: 100,
        currency: 'USD',
        quantity: 1,
      );
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            priceResolver: (item) => 200.0,
          ),
        ),
      )..add(item, shouldNotifyListeners: false);
      expect(cart.items[item.id]?.price, equals(200.0));
    });

    test('should log messages when logging is enabled', () {
      final logs = <String>[];

      FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            enableLogging: true,
            logger: logs.add,
          ),
        ),
      ).setNote('Special note');
      expect(logs.any((msg) => msg.contains('Set Note')), isTrue);
    });

    test('should NOT log messages when logging is disabled', () {
      final logs = <String>[];
      FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            logger: logs.add,
          ),
        ),
      ).setNote('Hidden note');
      expect(logs, isEmpty);
    });
    test('should prevent item addition via itemFilter', () {
      final item = CartItem(
        id: 'id1',
        name: 'Test Item',
        price: 100,
        currency: 'USD',
        quantity: 1,
      );
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            itemFilter: (item) => false,
          ),
        ),
      )..add(item, shouldNotifyListeners: false);
      expect(cart.isEmpty(), isTrue);
    });
    //
    test('should allow item addition via itemFilter returning true', () {
      final item = CartItem(
        id: 'id1',
        name: 'Test Item',
        price: 100,
        currency: 'USD',
        quantity: 1,
      );
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            itemFilter: (item) => true,
          ),
        ),
      )..add(item, shouldNotifyListeners: false);
      expect(cart.isNotEmpty(), isTrue);
    });
    test('should call priceResolver even on updates', () {
      final item = CartItem(
        id: 'id1',
        name: 'Test Item',
        price: 100,
        currency: 'USD',
        quantity: 1,
      );
      final prices = <double>[];
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            priceResolver: (item) {
              prices.add(item.price);
              return item.price + 50;
            },
          ),
        ),
      )
        ..add(item, shouldNotifyListeners: false)
        ..add(item..quantity = 3, shouldNotifyListeners: false);

      expect(prices.length, equals(1));

      expect(cart.items[item.id]?.price, equals(150.0));
    });

    test('combined behaviors: filter + priceResolver + logging', () {
      final logs = <String>[];
      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          behaviorOptions: BehaviorOptions(
            itemFilter: (item) {
              if (item.price < 90) {
                return false;
              }
              return true;
            },
            priceResolver: (item) => item.price + 10.0,
            enableLogging: true,
            logger: logs.add,
          ),
        ),
      )
        ..add(
          CartItem(
            id: 'valid',
            name: 'Valid Item',
            price: 100,
            currency: 'USD',
            quantity: 1,
          ),
          shouldNotifyListeners: false,
        )
        ..add(
          CartItem(
            id: 'filtered',
            name: 'Too Cheap',
            price: 20,
            currency: 'USD',
            quantity: 1,
          ),
          shouldNotifyListeners: false,
        );

      expect(cart.items.containsKey('valid'), isTrue);
      expect(cart.items.containsKey('filtered'), isFalse);
      expect(cart.items['valid']?.price, equals(110.0));
      expect(
        logs.any(
          (element) => element.contains('Item added'),
        ),
        isTrue,
      );
    });
  });
}
