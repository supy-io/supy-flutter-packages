import 'package:currency_kit/src/currency_code.dart';

/// Resolves the presentation details of a currency: how many decimals to show
/// and what glyph to show it with.
///
/// Separate from [CurrencyCode] because these are *app* decisions. An app may
/// legitimately show every currency at its own precision, or force one
/// precision across the board to match a back office.
abstract interface class CurrencyRegistry {
  /// Decimal places to display [currency] with.
  int fractionDigitsOf(CurrencyCode currency);

  /// The glyph to display [currency] with, e.g. `AED` or `د.إ`.
  String symbolOf(CurrencyCode currency);
}

/// The ISO-4217 defaults: each currency's own minor-unit count, and the
/// alphabetic code as its own symbol.
///
/// The code doubles as the symbol on purpose. A wrong glyph is worse than a
/// plain code, and outside a handful of currencies there is no single correct
/// symbol — so apps that want glyphs supply them via [CustomCurrencyRegistry].
class IsoCurrencyRegistry implements CurrencyRegistry {
  /// Const constructor.
  const IsoCurrencyRegistry();

  @override
  int fractionDigitsOf(CurrencyCode currency) => currency.fractionDigits;

  @override
  String symbolOf(CurrencyCode currency) => currency.code;
}

/// A registry that layers app overrides over [IsoCurrencyRegistry].
///
/// ```dart
/// // Show every currency at the retailer's configured precision.
/// const registry = CustomCurrencyRegistry(fractionDigitsForAll: 2);
///
/// // Real glyphs for the currencies we care about, ISO codes elsewhere.
/// const registry = CustomCurrencyRegistry(
///   symbols: {'AED': 'د.إ', 'USD': r'\$'},
/// );
/// ```
class CustomCurrencyRegistry implements CurrencyRegistry {
  /// Overrides on top of [base].
  const CustomCurrencyRegistry({
    this.base = const IsoCurrencyRegistry(),
    this.symbols = const {},
    this.fractionDigits = const {},
    this.fractionDigitsForAll,
  });

  /// The registry consulted when no override matches.
  final CurrencyRegistry base;

  /// Symbol overrides, keyed by uppercase ISO code.
  final Map<String, String> symbols;

  /// Per-currency precision overrides, keyed by uppercase ISO code.
  final Map<String, int> fractionDigits;

  /// One precision for every currency. Beaten by [fractionDigits].
  ///
  /// Use when the display precision is an app-wide setting rather than a
  /// property of the currency.
  final int? fractionDigitsForAll;

  @override
  int fractionDigitsOf(CurrencyCode currency) =>
      fractionDigits[currency.code] ??
      fractionDigitsForAll ??
      base.fractionDigitsOf(currency);

  @override
  String symbolOf(CurrencyCode currency) =>
      symbols[currency.code] ?? base.symbolOf(currency);
}
