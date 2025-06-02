part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartMaxLengthValidator extends ICartValidator {
  /// exceeds a specified maximum length.
  CartMaxLengthValidator(this.maxLength);

  /// Creates an instance of [CartMaxLengthValidator] with the specified
  /// maximum length.
  final int maxLength;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.items.length > maxLength) {
      return {
        CartValidatorKeys.maxLength: 'Maximum item types allowed is $maxLength',
      };
    }
    return null;
  }
}
