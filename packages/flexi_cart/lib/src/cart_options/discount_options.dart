// part of 'cart_options.dart';
//
// /// Handles the logic for calculating and labeling discounts.
// class DiscountOptions {
//   /// Creates a new instance of [DiscountOptions].
//   DiscountOptions({
//     this.discountCalculator,
//     this.discountLabel = 'Discount',
//     this.allowNegative = false,
//   });
//
//   /// A function to compute the discount value based on the current cart.
//   double Function(FlexiCart cart)? discountCalculator;
//
//   /// Label to display alongside the discount value.
//   String discountLabel;
//
//   /// Whether negative discounts are allowed (e.g., penalties or surcharges).
//   bool allowNegative;
//
//   /// Calculates the discount using [discountCalculator], or returns 0.0
//   /// if none provided.
//   double calculate(FlexiCart cart) {
//     final value = discountCalculator?.call(cart) ?? 0.0;
//     // If allowNegative is false, ensure the discount is not negative
//     return allowNegative ? value : value.clamp(0.0, double.infinity);
//   }
//
//   /// Creates a copy of this [DiscountOptions] with optional overrides.
//   DiscountOptions copyWith({
//     double Function(FlexiCart cart)? discountCalculator,
//     String? discountLabel,
//     bool? allowNegative,
//   }) {
//     return DiscountOptions(
//       discountCalculator: discountCalculator ?? this.discountCalculator,
//       discountLabel: discountLabel ?? this.discountLabel,
//       allowNegative: allowNegative ?? this.allowNegative,
//     );
//   }
// }
