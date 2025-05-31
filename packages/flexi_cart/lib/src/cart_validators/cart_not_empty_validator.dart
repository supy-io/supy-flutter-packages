part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartNotEmptyValidator extends ICartValidator {
  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.items.isEmpty) {
      return {
        CartValidatorKeys.emptyCart: 'Cart cannot be empty',
      };
    }
    return null;
  }
}
