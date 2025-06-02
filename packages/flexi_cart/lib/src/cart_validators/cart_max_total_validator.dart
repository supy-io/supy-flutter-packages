part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartMaxTotalValidator extends ICartValidator {
  /// exceeds a specified minimum total price.
  CartMaxTotalValidator(this.maxAmount);

  /// Creates an instance of [CartMinTotalValidator] with the specified
  final double maxAmount;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalPrice() > maxAmount) {
      return {
        CartValidatorKeys.maxTotal:
            'Maximum total price is \$${maxAmount.toStringAsFixed(2)}',
      };
    }
    return null;
  }
}
