// part of 'cart_options.dart';
//
// /// Handles tax-related configurations and calculations for the cart.
// class TaxOptions {
//   /// Creates a [TaxOptions] instance.
//   ///
//   /// You can pass a custom [taxCalculator], a fixed [taxRate],
//   /// or a set of [multiTaxCalculators] to handle different types of tax.
//   ///
//   /// You may also specify formatting, exemption logic, and display options.
//   TaxOptions({
//     this.taxCalculator,
//     this.taxRate,
//     this.includeTaxInTotal = false,
//     this.taxLabel = 'Tax',
//     this.multiTaxCalculators = const {},
//     this.taxRegion,
//     this.isExempt,
//     this.taxFormatter,
//     this.applyTaxPerItem = false,
//   });
//
//   /// A custom function to compute total tax for a given [FlexiCart].
//   final double Function(FlexiCart cart)? taxCalculator;
//
//   /// A simple flat tax rate (e.g., 0.08 for 8%) if no custom logic is provided.
//   double? taxRate;
//
//   /// Whether the computed tax should be included in the total cart price.
//   bool includeTaxInTotal;
//
//   /// The label used to display tax on UI elements.
//   String taxLabel;
//
//   /// A map of multiple named tax calculators (e.g., 'VAT', 'State Tax').
//   Map<String, double Function(FlexiCart cart)> multiTaxCalculators;
//
//   /// Optionally identify the tax region (e.g., 'US', 'EU') for external logic.
//   String? taxRegion;
//
//   /// Optional function to determine if the cart is tax-exempt.
//   bool Function(FlexiCart cart)? isExempt;
//
//   /// Custom formatter to display tax amounts.
//   String Function(double taxAmount)? taxFormatter;
//
//   /// If `true`, enables per-item tax calculations instead of cart-wide.
//   bool applyTaxPerItem;
//
//   /// Calculates the total tax for the cart.
//   ///
//   /// - If the cart is exempt, returns 0.
//   /// - If a [taxCalculator] is set, uses that.
//   /// - If a [taxRate] is set, applies it to the cart subtotal.
//   /// - Otherwise, returns 0.
//   double calculate(FlexiCart cart) {
//     if (isExempt?.call(cart) ?? false) return 0;
//     if (taxCalculator != null) return taxCalculator!(cart);
//     if (taxRate != null) return cart.totalPrice() * taxRate!;
//     return 0;
//   }
//
//   /// Calculates all taxes defined in [multiTaxCalculators] and returns a map.
//   Map<String, double> calculateAll(FlexiCart cart) {
//     return {
//       for (final entry in multiTaxCalculators.entries)
//         entry.key: entry.value(cart),
//     };
//   }
//
//   /// Formats a tax amount using [taxFormatter] or a default currency format.
//   String formatTax(double amount) {
//     return taxFormatter?.call(amount) ?? '\$${amount.toStringAsFixed(2)}';
//   }
//
//   /// Creates a copy of this [TaxOptions] with optional overrides.
//   TaxOptions copyWith({
//     double Function(FlexiCart cart)? taxCalculator,
//     double? taxRate,
//     bool? includeTaxInTotal,
//     String? taxLabel,
//     Map<String, double Function(FlexiCart cart)>? multiTaxCalculators,
//     String? taxRegion,
//     bool Function(FlexiCart cart)? isExempt,
//     String Function(double taxAmount)? taxFormatter,
//     bool? applyTaxPerItem,
//   }) {
//     return TaxOptions(
//       taxCalculator: taxCalculator ?? this.taxCalculator,
//       taxRate: taxRate ?? this.taxRate,
//       includeTaxInTotal: includeTaxInTotal ?? this.includeTaxInTotal,
//       taxLabel: taxLabel ?? this.taxLabel,
//       multiTaxCalculators: multiTaxCalculators ?? this.multiTaxCalculators,
//       taxRegion: taxRegion ?? this.taxRegion,
//       isExempt: isExempt ?? this.isExempt,
//       taxFormatter: taxFormatter ?? this.taxFormatter,
//       applyTaxPerItem: applyTaxPerItem ?? this.applyTaxPerItem,
//     );
//   }
// }
