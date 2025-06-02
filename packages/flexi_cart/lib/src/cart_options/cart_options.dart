import 'package:flexi_cart/flexi_cart.dart';

// part 'price_options.dart';
//
// part 'tax_options.dart';

part 'validator_options.dart';

part 'behavior_options.dart';

// part 'discount_options.dart';
//
// part 'shipping_options.dart';
//
// part 'session_options.dart';
//
// part 'recommendation_options.dart';

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
    // ShippingOptions? shippingOptions,
    // DiscountOptions? discountOptions,
    // PriceOptions? priceOptions,
    // RecommendationOptions? recommendationOptions,
    // SessionOptions? sessionOptions,
    BehaviorOptions? behaviorOptions,
    // TaxOptions? taxOptions,
  })  : validatorOptions = validatorOptions ?? ValidatorOptions(),
        // shippingOptions = shippingOptions ?? ShippingOptions(),
        // priceOptions = priceOptions ?? PriceOptions(),
        // recommendationOptions =
        //     recommendationOptions ?? RecommendationOptions(),
        // sessionOptions = sessionOptions ?? SessionOptions(),
        behaviorOptions = behaviorOptions ?? BehaviorOptions();
  // taxOptions = taxOptions ?? TaxOptions(),
  // discountOptions = discountOptions ?? DiscountOptions()

  /// Options related to currency formatting and price display.
  // final PriceOptions priceOptions;

  /// Options for tax calculations and how tax is shown in totals.
  // final TaxOptions taxOptions;

  /// Options for validating the cart during checkout, including promo codes.
  final ValidatorOptions validatorOptions;

  /// Controls logging, item filtering, and price overrides.
  final BehaviorOptions behaviorOptions;

  /// Rules and logic for applying discounts to the cart.
  // final DiscountOptions discountOptions;

  /// Shipping rules, cost calculators, and method listings.
  // final ShippingOptions shippingOptions;

  /// Controls cart session lifespan and expiration behavior.
  // final SessionOptions sessionOptions;

  /// Returns recommended products based on current cart contents.
  // final RecommendationOptions recommendationOptions;

  /// Creates a copy of this [CartOptions] with updated fields.
  CartOptions copyWith({
    // PriceOptions? priceOptions,
    // TaxOptions? taxOptions,
    ValidatorOptions? validatorOptions,
    BehaviorOptions? behaviorOptions,
    // DiscountOptions? discountOptions,
    // ShippingOptions? shippingOptions,
    // SessionOptions? sessionOptions,
    // RecommendationOptions? recommendationOptions,
  }) {
    return CartOptions(
      // priceOptions: priceOptions ?? this.priceOptions,
      // taxOptions: taxOptions ?? this.taxOptions,
      validatorOptions: validatorOptions ?? this.validatorOptions,
      behaviorOptions: behaviorOptions ?? this.behaviorOptions,
      // discountOptions: discountOptions ?? this.discountOptions,
      // shippingOptions: shippingOptions ?? this.shippingOptions,
      // sessionOptions: sessionOptions ?? this.sessionOptions,
      // recommendationOptions:
      //     recommendationOptions ?? this.recommendationOptions,
    );
  }
}
