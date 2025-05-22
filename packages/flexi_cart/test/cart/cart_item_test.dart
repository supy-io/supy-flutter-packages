import 'package:flutter_test/flutter_test.dart';

import '../helpers/mocks.dart';

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
}
