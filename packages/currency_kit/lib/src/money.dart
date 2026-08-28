import 'package:currency_kit/src/currency_code.dart';
import 'package:currency_kit/src/errors.dart';
import 'package:currency_kit/src/money_format.dart';
import 'package:currency_kit/src/money_formatter.dart';
import 'package:currency_kit/src/rounding.dart';
import 'package:meta/meta.dart';

/// An amount of money that knows what it is denominated in.
///
/// The currency travels with the number so "which currency is this?" stops
/// being a comment and starts being a type. Arithmetic across currencies
/// throws [CurrencyMismatchError] rather than silently producing a number
/// that means nothing.
///
/// ```dart
/// final price = Money(36.90, CurrencyCode.aed);
/// price.format();            // 'AED 36.90'
/// price + Money(1, CurrencyCode.usd); // throws CurrencyMismatchError
/// ```
///
/// The amount is a `double`. That is a deliberate, documented compromise: it
/// matches the JSON and model types this package was extracted to serve.
/// [rounded] is the one place the rounding rule lives, so a value crosses a
/// boundary rounded exactly once.
@immutable
final class Money implements Comparable<Money> {
  /// An [amount] of [currency].
  const Money(this.amount, this.currency);

  /// Zero in [currency].
  const Money.zero(this.currency) : amount = 0;

  /// The numeric amount, unrounded.
  final double amount;

  /// The currency [amount] is denominated in.
  final CurrencyCode currency;

  /// Decimal places this money is conventionally written with.
  int get fractionDigits => currency.fractionDigits;

  /// Whether the amount rounds to zero at the currency's precision.
  bool get isZero => roundToFractionDigits(amount, fractionDigits) == 0;

  /// Whether the amount is below zero.
  bool get isNegative => amount < 0;

  /// This amount rounded to [fractionDigits], defaulting to the currency's.
  ///
  /// See [roundToFractionDigits] for the rule.
  Money rounded([
    int? fractionDigits,
    RoundingMode mode = RoundingMode.halfUpDecimal,
  ]) =>
      Money(
        roundToFractionDigits(
          amount,
          fractionDigits ?? this.fractionDigits,
          mode: mode,
        ),
        currency,
      );

  /// The absolute value of this amount.
  Money get abs => Money(amount.abs(), currency);

  /// A copy with [amount] and/or [currency] replaced.
  ///
  /// Replacing the currency **relabels** the amount; it does not convert it.
  /// Use an `ExchangeRate` to convert.
  Money copyWith({double? amount, CurrencyCode? currency}) =>
      Money(amount ?? this.amount, currency ?? this.currency);

  /// Sum of two amounts in the same currency.
  Money operator +(Money other) {
    _assertSameCurrency(other, '+');
    return Money(amount + other.amount, currency);
  }

  /// Difference of two amounts in the same currency.
  Money operator -(Money other) {
    _assertSameCurrency(other, '-');
    return Money(amount - other.amount, currency);
  }

  /// This amount negated.
  Money operator -() => Money(-amount, currency);

  /// This amount scaled by a dimensionless [factor], e.g. a quantity.
  Money operator *(num factor) => Money(amount * factor, currency);

  /// This amount divided by a dimensionless [divisor].
  Money operator /(num divisor) => Money(amount / divisor, currency);

  /// Whether this amount is greater than [other] in the same currency.
  bool operator >(Money other) => compareTo(other) > 0;

  /// Whether this amount is greater than or equal to [other].
  bool operator >=(Money other) => compareTo(other) >= 0;

  /// Whether this amount is less than [other] in the same currency.
  bool operator <(Money other) => compareTo(other) < 0;

  /// Whether this amount is less than or equal to [other].
  bool operator <=(Money other) => compareTo(other) <= 0;

  /// Renders this amount for display, e.g. `AED 36.90`.
  ///
  /// Uses [MoneyFormatter.standard] unless [format] says otherwise. For
  /// repeated formatting with the same options, hold a [MoneyFormatter].
  String format([MoneyFormat? format]) =>
      MoneyFormatter.standard.format(this, format);

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other, 'compareTo');
    return amount.compareTo(other.amount);
  }

  void _assertSameCurrency(Money other, String operation) {
    if (other.currency != currency) {
      throw CurrencyMismatchError(currency, other.currency, operation);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  /// A debug representation. Use [format] for anything a user reads.
  @override
  String toString() => 'Money($amount, $currency)';
}
