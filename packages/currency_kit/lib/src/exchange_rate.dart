import 'package:currency_kit/src/currency_code.dart';
import 'package:currency_kit/src/errors.dart';
import 'package:currency_kit/src/money.dart';
import 'package:meta/meta.dart';

/// A rate between two currencies, with the direction stated in the type.
///
/// Reads as **"1 [base] = [rate] [quote]"** — the same sentence a currency
/// picker shows the user:
///
/// ```dart
/// // 1 USD = 3.69 AED
/// final rate = ExchangeRate(
///   base: CurrencyCode.usd,
///   quote: CurrencyCode.aed,
///   rate: 3.69,
/// );
///
/// rate.toQuote(Money(10, CurrencyCode.usd));   // AED 36.90  — the user typed 10 USD
/// rate.toBase(Money(36.90, CurrencyCode.aed)); // USD 10.00  — rendering a stored AED amount
/// ```
///
/// ## Display-only conversion
///
/// The two methods are the *only* two places a rate should ever be applied:
///
/// - [toQuote] at the **input boundary** — the user typed an amount in the
///   currency they are reading; store it in the canonical currency.
/// - [toBase] at the **render boundary** — an amount is stored canonically;
///   show it in the currency the user selected.
///
/// Everything between those boundaries stays in the canonical currency.
/// Re-basing stored state when the user switches currency round-trips the
/// value through `× r ÷ r`, which is lossy in binary floating point — the
/// user changes a view and the data moves. There is deliberately no API here
/// for doing that.
@immutable
final class ExchangeRate {
  /// A rate meaning "1 [base] = [rate] [quote]".
  ///
  /// Throws [ArgumentError] if [rate] is not finite and positive, or if
  /// [base] and [quote] are the same currency at a rate other than 1.
  factory ExchangeRate({
    required CurrencyCode base,
    required CurrencyCode quote,
    required double rate,
  }) {
    if (!rate.isFinite || rate <= 0) {
      throw ArgumentError.value(rate, 'rate', 'must be finite and positive');
    }
    if (base == quote && rate != 1) {
      throw ArgumentError.value(
        rate,
        'rate',
        'must be 1 when base and quote are both $base',
      );
    }
    return ExchangeRate._(base, quote, rate);
  }

  const ExchangeRate._(this.base, this.quote, this.rate);

  /// The identity rate for [currency] — 1:1 with itself.
  ///
  /// Use this instead of a nullable rate so "no supplier currency selected"
  /// and "a rate of 1" take the same code path.
  const ExchangeRate.identity(CurrencyCode currency)
      : base = currency,
        quote = currency,
        rate = 1;

  /// The currency one unit of which is worth [rate] [quote].
  final CurrencyCode base;

  /// The currency [rate] is expressed in.
  final CurrencyCode quote;

  /// How many [quote] one [base] is worth.
  final double rate;

  /// Whether this rate leaves amounts unchanged.
  bool get isIdentity => rate == 1 && base == quote;

  /// This rate read in the other direction: "1 [quote] = 1/[rate] [base]".
  ExchangeRate get inverted =>
      ExchangeRate._(quote, base, isIdentity ? 1 : 1 / rate);

  /// Converts an amount in [base] to [quote] — the **input** boundary.
  ///
  /// Throws [CurrencyMismatchError] if [amount] is not in [base].
  Money toQuote(Money amount) {
    if (amount.currency != base) {
      throw CurrencyMismatchError(amount.currency, base, 'toQuote');
    }
    return Money(isIdentity ? amount.amount : amount.amount * rate, quote);
  }

  /// Converts an amount in [quote] to [base] — the **render** boundary.
  ///
  /// Throws [CurrencyMismatchError] if [amount] is not in [quote].
  Money toBase(Money amount) {
    if (amount.currency != quote) {
      throw CurrencyMismatchError(amount.currency, quote, 'toBase');
    }
    return Money(isIdentity ? amount.amount : amount.amount / rate, base);
  }

  /// A copy with any field replaced.
  ExchangeRate copyWith({
    CurrencyCode? base,
    CurrencyCode? quote,
    double? rate,
  }) =>
      ExchangeRate(
        base: base ?? this.base,
        quote: quote ?? this.quote,
        rate: rate ?? this.rate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRate &&
          other.base == base &&
          other.quote == quote &&
          other.rate == rate;

  @override
  int get hashCode => Object.hash(base, quote, rate);

  @override
  String toString() => '1 $base = $rate $quote';
}
