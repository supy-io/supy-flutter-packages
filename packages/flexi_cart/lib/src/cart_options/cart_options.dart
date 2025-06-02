import 'package:flexi_cart/flexi_cart.dart';

part 'validator_options.dart';

part 'behavior_options.dart';

/// A configuration class that bundles all customizable options for a
/// [FlexiCart] instance.
///
/// Use this class to control pricing formats, tax calculations,
/// validation rules,
/// behavior overrides, discount logic, shipping methods,
/// invoice metadata, session behavior,
/// and product recommendations.
class CartOptions {
  /// Creates a comprehensive set of options for
  /// customizing [FlexiCart] behavior.
  CartOptions({
    ValidatorOptions? validatorOptions,
    BehaviorOptions? behaviorOptions,
  })  : validatorOptions = validatorOptions ?? ValidatorOptions(),
        behaviorOptions = behaviorOptions ?? BehaviorOptions();

  /// Options for validating the cart during checkout, including promo codes.
  final ValidatorOptions validatorOptions;

  /// Controls logging, item filtering, and price overrides.
  final BehaviorOptions behaviorOptions;

  /// Creates a copy of this [CartOptions] with updated fields.
  CartOptions copyWith({
    ValidatorOptions? validatorOptions,
    BehaviorOptions? behaviorOptions,
  }) {
    return CartOptions(
      validatorOptions: validatorOptions ?? this.validatorOptions,
      behaviorOptions: behaviorOptions ?? this.behaviorOptions,
    );
  }
}
