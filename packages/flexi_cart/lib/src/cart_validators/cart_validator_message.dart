part of 'cart_validators.dart';

/// A utility class that defines standard keys
/// used for cart validation messages.
///
/// These keys are intended to be used in conjunction with cart validators
/// to provide structured, consistent error messaging throughout the cart
/// system.
///
/// Example usage:
///
/// ```dart
/// final errors = cart.validateCheckout();
/// final message = errorMessages[CartValidatorMessage.emptyCart];
/// ```
class CartValidatorKeys {
  /// Indicates that a required value was not provided.
  ///
  /// Typically used when a field or value is missing.
  static const String required = 'required';

  /// Indicates that a value does not meet the minimum allowed value.
  static const String min = 'min';

  /// Indicates that a value exceeds the maximum allowed value.
  static const String max = 'max';

  /// Indicates that a value's length is less than the minimum allowed.
  static const String minLength = 'minLength';

  /// Indicates that a value's length exceeds the maximum allowed.
  static const String maxLength = 'maxLength';

  /// Indicates that a value is not equal to an expected value.
  static const String equals = 'equals';

  /// Indicates that a value does not contain a required element.
  static const String contains = 'contains';

  // -----------------------------
  // Cart-specific validation keys
  // -----------------------------

  /// Indicates that the cart is empty and must contain at least one item.
  static const String emptyCart = 'emptyCart';

  /// Indicates that the total value of the cart is below the required minimum.
  static const String minTotal = 'minTotal';

  /// Indicates that the total value of the cart exceeds the allowed maximum.
  static const String maxTotal = 'maxTotal';

  /// Indicates that the number of items in the cart exceeds the allowed limit.
  static const String maxItems = 'maxItems';

  /// Indicates that one or more items in the cart are out of stock.
  static const String outOfStock = 'outOfStock';

  /// Indicates that an item in the cart is invalid or malformed.
  static const String invalidItem = 'invalidItem';

  /// Indicates that an item is no longer available or cannot be purchased.
  static const String unavailableItem = 'unavailableItem';
}
