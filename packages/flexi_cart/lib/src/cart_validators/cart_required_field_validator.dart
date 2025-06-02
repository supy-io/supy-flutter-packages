part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartRequiredFieldValidator extends ICartValidator {
  /// exceeds a specified minimum total price.
  CartRequiredFieldValidator(this.fieldName);

  /// Creates an instance of [CartRequiredFieldValidator] with the specified
  final String fieldName;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    final value = cart.metadata[fieldName];
    if (value == null || (value is String && value.trim().isEmpty)) {
      return {
        CartValidatorKeys.required: "Field '$fieldName' is required",
      };
    }
    return null;
  }
}
