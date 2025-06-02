part of 'cart_validators.dart';

/// Interface for validating a [FlexiCart] instance.
abstract class ICartValidator {
  /// Creates an instance of the validator.
  const ICartValidator();

  /// Validates the provided [FlexiCart] instance.
  ///
  /// Returns a [Map] of validation errors if validation fails,
  /// where each key is a validation error code (string),
  /// and the value is either an error message or related data.
  ///
  /// Returns `null` if the cart is valid.
  Map<String, dynamic>? validate(FlexiCart cart);

  /// Calls [validate] to perform validation on the provided [FlexiCart].
  ///
  /// This method allows the validator to be used as a callable.
  ///
  /// Returns a map of validation errors or `null`.
  Map<String, dynamic>? call(FlexiCart cart) => validate(cart);
}
