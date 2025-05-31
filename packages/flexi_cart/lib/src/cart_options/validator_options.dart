part of 'cart_options.dart';

/// Signature for a function that validates a [FlexiCart] instance.
///
/// Returns a map of field names to error messages if validation fails,
/// or `null`/empty if validation succeeds.

/// Provides configuration for validating a [FlexiCart] during its lifecycle,
/// including support for custom validators and promo code validation.
class ValidatorOptions {
  /// Creates a new instance of [ValidatorOptions].
  ///
  /// [validators] is an optional list of functions to validate cart state.
  /// [promoCode] can be used to validate discount logic.
  /// [promoCodeValidator] validates the provided promo code.
  /// If [autoValidate] is `true`, validations will be triggered automatically
  /// on cart changed notifier with (e.g., item added, quantity changed).
  ValidatorOptions({
    List<ICartValidator>? validators,
    this.promoCode,
    this.promoCodeValidator,
    this.autoValidate = false,
  }) : _validators = validators != null ? List.of(validators) : [];

  /// If `true`, the cart will be validated automatically after each change.
  final bool autoValidate;

  /// The current promotional code applied to the cart, if any.
  String? promoCode;

  /// A function that validates the current [promoCode].
  ///
  /// Returns an error message if the promo code is invalid, or `null` if valid.
  final String? Function(String code)? promoCodeValidator;

  /// Internal list of custom cart validators.
  ///
  /// These functions should return maps of field names to error messages,
  /// or an empty map if no validation errors occur.
  final List<ICartValidator> _validators;

  /// A read-only list of validators currently configured.
  List<ICartValidator> get validators => _validators;

  /// Returns `true` if at least one validator has been added.
  bool get hasValidators => _validators.isNotEmpty;

  /// Adds a single [validator] to the list of custom validators.
  void addValidator(ICartValidator validator) {
    _validators.add(validator);
  }

  /// Removes the given [validator] from the list of custom validators.
  void removeValidator(ICartValidator validator) {
    _validators.remove(validator);
  }

  /// Adds multiple [validators] to the list at once.
  void addValidators(List<ICartValidator> validators) {
    _validators.addAll(validators);
  }

  /// Removes all currently registered validators.
  void clearValidators() {
    _validators.clear();
  }

  /// Executes all validators and returns a map of validation errors.
  ///
  /// Each error is returned as a key-value pair where the key typically
  /// refers to a form field or logical condition
  /// (e.g., `"quantity"`, `"promoCode"`),
  /// and the value is a corresponding error message.
  ///
  /// If no errors occur, an empty map is returned.
  Map<String, dynamic> validate(FlexiCart cart) {
    final errors = <String, dynamic>{};

    for (final validator in _validators) {
      final result = validator(cart);
      if (result != null && result.isNotEmpty) {
        errors.addAll(result);
      }
    }

    if (promoCodeValidator != null && promoCode != null) {
      final promoError = promoCodeValidator!(promoCode!);
      if (promoError != null && promoError.isNotEmpty) {
        errors['promoCode'] = promoError;
      }
    }

    return errors;
  }

  /// Returns a new [ValidatorOptions] instance with overridden values.
  ///
  /// Useful for immutability patterns where an updated copy is needed
  /// rather than modifying an existing instance.
  ValidatorOptions copyWith({
    List<ICartValidator>? validators,
    String? promoCode,
    String? Function(String code)? promoCodeValidator,
  }) {
    return ValidatorOptions(
      validators: validators ?? _validators,
      promoCode: promoCode ?? this.promoCode,
      promoCodeValidator: promoCodeValidator ?? this.promoCodeValidator,
    );
  }
}
