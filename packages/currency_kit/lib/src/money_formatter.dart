import 'package:currency_kit/src/currency_registry.dart';
import 'package:currency_kit/src/money.dart';
import 'package:currency_kit/src/money_format.dart';
import 'package:currency_kit/src/rounding.dart';
import 'package:intl/intl.dart';

/// Renders [Money] as text.
///
/// The amount is rounded once, here, via [roundToFractionDigits] — then the
/// rounded value is formatted. Letting `NumberFormat` do its own rounding is
/// what makes `412.565` render as `412.56`.
///
/// ```dart
/// const formatter = MoneyFormatter.standard;
/// formatter.format(Money(36.9, CurrencyCode.aed));    // 'AED 36.90'
/// formatter.format(Money(-36.9, CurrencyCode.aed));   // 'AED -36.90'
/// formatter.format(Money(1234567, CurrencyCode.aed),
///     MoneyFormat.compacted);                          // 'AED 1.23M'
/// ```
class MoneyFormatter {
  /// A formatter using [registry] for precision and symbols, and [defaults]
  /// for any call that does not pass its own [MoneyFormat].
  const MoneyFormatter({
    this.registry = const IsoCurrencyRegistry(),
    this.defaults = const MoneyFormat(),
  });

  /// ISO precision, ISO codes as symbols, `AED 36.90` layout.
  static const standard = MoneyFormatter();

  /// Resolves precision and symbols.
  final CurrencyRegistry registry;

  /// Options used when [format] is called without an override.
  final MoneyFormat defaults;

  /// Renders [money], overriding [defaults] with [format] when given.
  String format(Money money, [MoneyFormat? format]) {
    final options = format ?? defaults;
    final digits =
        options.fractionDigits ?? registry.fractionDigitsOf(money.currency);
    final rounded =
        roundToFractionDigits(money.amount, digits, mode: options.rounding);

    final body = _number(rounded.abs(), digits, options);
    final sign = rounded < 0 ? '-' : '';
    final affix = switch (options.affix) {
      MoneyAffix.code => money.currency.code,
      MoneyAffix.symbol => registry.symbolOf(money.currency),
      MoneyAffix.none => '',
    };

    if (affix.isEmpty) return '$sign$body';

    return switch ((options.affixPosition, options.signPosition)) {
      (MoneyAffixPosition.leading, MoneySignPosition.beforeNumber) =>
        '$affix${options.separator}$sign$body',
      (MoneyAffixPosition.leading, MoneySignPosition.beforeAffix) =>
        '$sign$affix${options.separator}$body',
      (MoneyAffixPosition.trailing, _) =>
        '$sign$body${options.separator}$affix',
    };
  }

  String _number(double value, int digits, MoneyFormat options) {
    if (options.compact) {
      return NumberFormat.compact(locale: options.locale).format(value);
    }
    if (!options.grouping) return value.toStringAsFixed(digits);
    return NumberFormat.decimalPatternDigits(
      locale: options.locale,
      decimalDigits: digits,
    ).format(value);
  }
}
