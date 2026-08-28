import 'package:currency_kit/src/currency_code.dart';

/// Thrown when a string cannot be resolved to a known ISO-4217 currency.
///
/// Deliberately an exception rather than a silent default: an amount labelled
/// with the wrong currency is a worse outcome than a failed parse.
class UnknownCurrencyCode implements Exception {
  /// [value] could not be resolved to a currency.
  const UnknownCurrencyCode(this.value);

  /// The string that could not be resolved.
  final String value;

  @override
  String toString() =>
      'UnknownCurrencyCode: "$value" is not a known ISO-4217 code. '
      'Use CurrencyCode.custom to define one this package does not ship.';
}

/// Thrown when two amounts in different currencies are combined or compared.
///
/// This is a programming error, not a data error — adding USD to AED has no
/// meaning without an `ExchangeRate`, so the fix is at the call site.
class CurrencyMismatchError extends Error {
  /// The [operation] was attempted between [left] and [right].
  CurrencyMismatchError(this.left, this.right, this.operation);

  /// Currency of the left-hand operand.
  final CurrencyCode left;

  /// Currency of the right-hand operand.
  final CurrencyCode right;

  /// The operation that was attempted, e.g. `+` or `compareTo`.
  final String operation;

  @override
  String toString() =>
      'CurrencyMismatchError: cannot apply "$operation" to $left and $right. '
      'Convert one side with an ExchangeRate first.';
}
