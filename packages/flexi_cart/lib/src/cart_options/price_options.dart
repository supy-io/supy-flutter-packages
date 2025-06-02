// part of 'cart_options.dart';
//
// /// Configuration for how prices are displayed and formatted.
// class PriceOptions {
//   /// Creates a new instance of [PriceOptions] with default values.
//   PriceOptions({
//     this.currencySymbol = r'$',
//     this.symbolOnLeft = true,
//     this.decimalPlaces = 2,
//     this.compactPriceFormat = false,
//     this.locale,
//     this.customFormatter,
//   });
//
//   /// Currency symbol (e.g. '\$', '€', '¥').
//   String currencySymbol;
//
//   /// Whether the currency symbol appears before or after the number.
//   bool symbolOnLeft;
//
//   /// Number of decimal places to show.
//   int decimalPlaces;
//
//   /// Use a compact format for large numbers (e.g. 1K, 2.5M).
//   bool compactPriceFormat;
//
//   /// Locale identifier for formatting (optional).
//   String? locale;
//
//   /// Optional custom formatter to override default formatting behavior.
//   String Function(double price)? customFormatter;
//
//   /// Formats the given [value] according to the price options.
//   String format(double value) {
//     if (customFormatter != null) {
//       return customFormatter!(value);
//     }
//     final formatted = compactPriceFormat && value >= 1000
//         ? _compactFormat(value)
//         : value.toStringAsFixed(decimalPlaces);
//     return symbolOnLeft
//         ? '$currencySymbol$formatted'
//         : '$formatted$currencySymbol';
//   }
//
//   String _compactFormat(double value) {
//     if (value >= 1e6) {
//       return '${(value / 1e6).toStringAsFixed(1)}M';
//     }
//     if (value >= 1e3) {
//       return '${(value / 1e3).toStringAsFixed(1)}K';
//     }
//     return value.toStringAsFixed(decimalPlaces);
//   }
// }
