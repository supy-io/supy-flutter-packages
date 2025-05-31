part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartMinLengthValidator extends ICartValidator {
  /// exceeds a specified minimum length.
  CartMinLengthValidator(this.minLength);

  /// Creates an instance of [CartMinLengthValidator] with the specified
  final int minLength;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.items.length < minLength) {
      return {
        CartValidatorKeys.minLength:
            'Minimum item types required is $minLength',
      };
    }
    return null;
  }
}
