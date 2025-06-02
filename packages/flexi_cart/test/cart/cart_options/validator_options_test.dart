import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mocks.dart';

void main() {
  group('FlexiCart validation', () {
    test('CartValidator returns error if total quantity is too low', () {
      final item = CartItem(
        id: '1',
        name: 'Test Item',
        price: 10,
        quantity: 2,
        currency: 'USD',
      );

      final cart = FlexiCart<CartItem>(
        options: CartOptions(
          validatorOptions: ValidatorOptions(
            validators: [
              CartValidators.cartMinLength(1),
              CartValidators.cartMinTotal(100),
            ],
          ),
        ),
      );

      expect(cart.validate(), {
        'minLength': 'Minimum item types required is 1',
        'minTotal': r'Minimum total price is $100.00',
      });

      cart.add(item);

      expect(
        cart.validate(),
        {'minTotal': r'Minimum total price is $100.00'},
      );
    });

    test('Multiple validators and promo code check work together', () {
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 20,
        quantity: 1,
        currency: 'USD',
      );
      final item2 = CartItem(
        id: 'B',
        name: 'Test Item',
        price: 50,
        quantity: 2,
        currency: 'USD',
      );
      final cart = FlexiCart(
        options: CartOptions(
          validatorOptions: ValidatorOptions(
            validators: [CartValidators.cartMaxTotal(50)],
            promoCode: 'BADCODE',
            promoCodeValidator: (code) =>
                code == 'GOODCODE' ? null : 'Promo code error',
          ),
        ),
      )
        ..add(item1)
        ..add(item2);

      final errors = cart.options.validatorOptions.validate(cart);
      expect(
        errors,
        equals(
          {
            'maxTotal': r'Maximum total price is $50.00',
            'promoCode': 'Promo code error',
          },
        ),
      );
      expect(
        errors,
        equals(
          {
            'maxTotal': r'Maximum total price is $50.00',
            'promoCode': 'Promo code error',
          },
        ),
      );
    });

    test('cartNotEmpty returns error when cart is empty', () {
      final cart = FlexiCart();

      final validator = CartValidators.cartNotEmpty();
      final errors = validator.validate(cart);

      expect(errors, isNotNull);
      expect(errors!.containsKey(CartValidatorKeys.emptyCart), isTrue);
    });

    test('cartNotEmpty returns null when cart has items', () {
      final cart = FlexiCart();
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 20,
        quantity: 1,
        currency: 'USD',
      );
      cart.add(item1);
      final validator = CartValidators.cartNotEmpty();
      final errors = validator.validate(cart);

      expect(errors, isNull);
    });

    test('cartMinTotal returns error when total below minimum', () {
      final cart = FlexiCart();
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 20,
        quantity: 1,
        currency: 'USD',
      );
      cart.add(item1);
      final validator = CartValidators.cartMinTotal(50);
      final errors = validator.validate(cart);

      expect(errors, isNotNull);
      expect(errors!.containsKey(CartValidatorKeys.minTotal), isTrue);
    });

    test('cartMinTotal returns null when total meets minimum', () {
      final cart = FlexiCart();
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 50,
        quantity: 1,
        currency: 'USD',
      );
      cart.add(item1);

      final validator = CartValidators.cartMinTotal(50);
      final errors = validator.validate(cart);

      expect(errors, isNull);
    });

    test('cartMaxItemCount returns error when items exceed max', () {
      final cart = FlexiCart();
      for (var i = 0; i < 3; i++) {
        final item = CartItem(
          id: 'item$i',
          name: 'Test Item $i',
          price: 10,
          quantity: 1,
          currency: 'USD',
        );
        cart.add(item);
      }

      final validator = CartValidators.cartMaxItemCount(2);
      final errors = validator.validate(cart);

      expect(errors, isNotNull);
      expect(errors!.containsKey(CartValidatorKeys.maxItems), isTrue);
    });

    test('cartMaxItemCount returns null when item count within max', () {
      final cart = FlexiCart();
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 50,
        quantity: 10,
        currency: 'USD',
      );
      cart.add(item1);
      final validator = CartValidators.cartMaxItemCount(10);
      final errors = validator.validate(cart);

      expect(errors, isNull);
    });
    test('cartMaxLength returns null when item count within max', () {
      final cart = FlexiCart();
      final item1 = CartItem(
        id: 'A',
        name: 'Test Item',
        price: 50,
        quantity: 10,
        currency: 'USD',
      );
      cart.add(item1);
      final validator = CartValidators.cartMaxLength(2);
      final errors = validator.validate(cart);

      expect(errors, isNull);
    });

    test('cartMaxLength returns error when items exceed max', () {
      final cart = FlexiCart();
      for (var i = 0; i < 3; i++) {
        final item = CartItem(
          id: 'item$i',
          name: 'Test Item $i',
          price: 10,
          quantity: 1,
          currency: 'USD',
        );
        cart.add(item);
      }

      final validator = CartValidators.cartMaxLength(1);
      final errors = validator.validate(cart);

      expect(errors, isNotNull);
      expect(errors!.containsKey(CartValidatorKeys.maxLength), isTrue);
    });

    test('cartRequiredField returns null when required field present', () {
      final cart = FlexiCart()..setMetadataEntry('email', 'user@example.com');
      final validator = CartValidators.cartRequiredField('email');
      final errors = validator.validate(cart);

      expect(errors, isNull);
    });
  });
}
