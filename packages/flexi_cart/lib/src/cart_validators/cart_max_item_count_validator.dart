part of 'cart_validators.dart';

/// Validator that checks if the total number of items in the cart
class CartMaxItemCountValidator extends ICartValidator {
  /// exceeds a specified maximum count.
  CartMaxItemCountValidator(this.maxCount);

  /// Creates an instance of [CartMaxItemCountValidator]
  /// with the specified maximum count.
  final double maxCount;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalQuantity() > maxCount) {
      return {
        CartValidatorKeys.maxItems: 'Maximum allowed items is $maxCount',
      };
    }
    return null;
  }
}
