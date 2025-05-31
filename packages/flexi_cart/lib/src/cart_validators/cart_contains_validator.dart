part of 'cart_validators.dart';

/// Validator that checks if the cart contains a specific item
class CartContainsValidator extends ICartValidator {
  /// Creates an instance of [CartContainsValidator] with the required item ID.
  CartContainsValidator(this.requiredItemId);

  /// The ID of the item that must be present in the cart.
  final String requiredItemId;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    final containsItem =
        cart.itemsList.any((item) => item.id == requiredItemId);
    if (!containsItem) {
      return {
        CartValidatorKeys.contains: 'Cart must contain item $requiredItemId',
      };
    }
    return null;
  }
}
