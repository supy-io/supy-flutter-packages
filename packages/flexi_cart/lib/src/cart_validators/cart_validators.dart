import 'package:flexi_cart/flexi_cart.dart';

part 'cart_contains_validator.dart';

part 'cart_max_item_count_validator.dart';

part 'cart_max_length_validator.dart';

part 'cart_min_length_validator.dart';

part 'cart_min_total_validator.dart';

part 'cart_not_empty_validator.dart';

part 'cart_required_field_validator.dart';

part 'cart_validator_message.dart';

part 'i_cart_validator.dart';

part 'cart_max_total_validator.dart';

/// Provides a set of built-in cart validators for [FlexiCart] instances.
///
/// These validators check various constraints on the cart such as minimum
/// total, item count limits, required fields, and more.
/// Use these validators to enforce cart business rules and
/// ensure data integrity.
class CartValidators {
  /// Creates a validator that requires the cart's total price to be
  /// at least [minAmount].
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.minTotal] if the
  /// cart total is less than [minAmount].
  static ICartValidator cartMinTotal(double minAmount) =>
      CartMinTotalValidator(minAmount);

  /// Returns a validation error keyed by [CartValidatorKeys.maxTotal] if the
  /// cart total is less than [minAmount].
  static ICartValidator cartMaxTotal(double minAmount) =>
      CartMaxTotalValidator(minAmount);

  /// Creates a validator that requires the cart to have at least one item.
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.emptyCart]
  /// if the cart has no items.
  static ICartValidator cartNotEmpty() => CartNotEmptyValidator();

  /// Creates a validator that requires the total quantity of items in the cart
  /// to be less than or equal to [maxCount].
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.maxItems] if the
  /// total quantity exceeds [maxCount].
  static ICartValidator cartMaxItemCount(double maxCount) =>
      CartMaxItemCountValidator(maxCount);

  /// Creates a validator that requires a metadata field named [fieldName]
  /// in the
  /// cart to be non-null and non-empty.
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.required] if the
  /// field is missing or empty.
  static ICartValidator cartRequiredField(String fieldName) =>
      CartRequiredFieldValidator(fieldName);

  /// Creates a validator that requires the cart to contain an item with ID
  /// [requiredItemId].
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.contains] if the
  /// item is not present.
  static ICartValidator cartContains(String requiredItemId) =>
      CartContainsValidator(requiredItemId);

  /// Creates a validator that requires the cart to have at most [maxLength]
  /// distinct item types.
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.maxLength]
  /// if the number of distinct items exceeds [maxLength].
  static ICartValidator cartMaxLength(int maxLength) =>
      CartMaxLengthValidator(maxLength);

  /// Creates a validator that requires the cart to have at least [minLength]
  /// distinct item types.
  ///
  /// Returns a validation error keyed by [CartValidatorKeys.minLength]
  /// if the number of distinct items is less than [minLength].
  static ICartValidator cartMinLength(int minLength) =>
      CartMinLengthValidator(minLength);
}
