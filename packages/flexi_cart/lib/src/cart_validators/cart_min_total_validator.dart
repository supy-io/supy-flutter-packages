part of 'cart_validators.dart';

/// Validator that checks if the number of different item types in the cart
class CartMinTotalValidator extends ICartValidator {
  /// exceeds a specified minimum total price.
  CartMinTotalValidator(this.minAmount);

  /// Creates an instance of [CartMinTotalValidator] with the specified
  final double minAmount;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalPrice() <= minAmount) {
      return {
        CartValidatorKeys.minTotal:
            'Minimum total price is \$${minAmount.toStringAsFixed(2)}',
      };
    }
    return null;
  }
}
