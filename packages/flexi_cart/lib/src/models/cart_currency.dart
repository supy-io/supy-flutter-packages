import 'package:flutter/foundation.dart';

/// Represents a currency with an exchange rate and currency code.
///
/// This class holds the exchange [rate] relative to a base currency
/// and the [code] representing the currency (e.g., "USD", "EUR").
@immutable
class CartCurrency {
  /// Creates a [CartCurrency] instance with the given [rate] and [code].
  ///
  /// Both [rate] and [code] are required.
  const CartCurrency({required this.rate, required this.code});

  /// The exchange rate relative to a base currency.
  final num rate;

  /// The currency code (e.g., "USD", "EUR").
  final String code;

  @override
  String toString() {
    return 'CartCurrency{rate: $rate, code: $code}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is CartCurrency && other.rate == rate && other.code == code;
  }

  @override
  int get hashCode => Object.hash(rate, code);
}
