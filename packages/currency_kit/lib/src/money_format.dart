import 'package:currency_kit/src/rounding.dart';

/// What to show beside the number.
enum MoneyAffix {
  /// The ISO code, e.g. `AED`.
  code,

  /// The registry's symbol, e.g. `د.إ`.
  symbol,

  /// Nothing — just the number.
  none,
}

/// Which side of the number the affix goes on.
enum MoneyAffixPosition {
  /// `AED 36.90`
  leading,

  /// `36.90 AED`
  trailing,
}

/// Where the minus sign goes on a negative amount.
enum MoneySignPosition {
  /// `AED -36.90` — the affix stays first.
  beforeNumber,

  /// `-AED 36.90` — the sign leads the whole thing.
  beforeAffix,
}

/// Display options for `MoneyFormatter`.
///
/// The defaults reproduce `AED 36.90` / `AED -36.90`, matching the convention
/// this package was extracted from.
class MoneyFormat {
  /// Const constructor; every field has a default.
  const MoneyFormat({
    this.affix = MoneyAffix.code,
    this.affixPosition = MoneyAffixPosition.leading,
    this.signPosition = MoneySignPosition.beforeNumber,
    this.fractionDigits,
    this.compact = false,
    this.grouping = true,
    this.locale,
    this.separator = ' ',
    this.rounding = RoundingMode.halfUpDecimal,
  });

  /// A bare number, with no currency affix.
  static const plain = MoneyFormat(affix: MoneyAffix.none);

  /// A short form for dense UI, e.g. `AED 1.2M`.
  static const compacted = MoneyFormat(compact: true);

  /// What to show beside the number.
  final MoneyAffix affix;

  /// Which side the affix goes on.
  final MoneyAffixPosition affixPosition;

  /// Where the minus sign goes.
  final MoneySignPosition signPosition;

  /// Decimals to show. Defaults to the registry's answer for the currency.
  final int? fractionDigits;

  /// Whether to abbreviate large amounts (`1.2M`).
  final bool compact;

  /// Whether to group thousands (`1,234.00`).
  final bool grouping;

  /// BCP-47 locale for digits and separators. Defaults to the ambient locale.
  final String? locale;

  /// String placed between the affix and the number.
  final String separator;

  /// How to resolve an amount sitting on a rounding boundary.
  final RoundingMode rounding;

  /// A copy with any field replaced.
  ///
  /// Passing null for a field keeps the current value; to clear
  /// [fractionDigits] or [locale], construct a new [MoneyFormat].
  MoneyFormat copyWith({
    MoneyAffix? affix,
    MoneyAffixPosition? affixPosition,
    MoneySignPosition? signPosition,
    int? fractionDigits,
    bool? compact,
    bool? grouping,
    String? locale,
    String? separator,
    RoundingMode? rounding,
  }) =>
      MoneyFormat(
        affix: affix ?? this.affix,
        affixPosition: affixPosition ?? this.affixPosition,
        signPosition: signPosition ?? this.signPosition,
        fractionDigits: fractionDigits ?? this.fractionDigits,
        compact: compact ?? this.compact,
        grouping: grouping ?? this.grouping,
        locale: locale ?? this.locale,
        separator: separator ?? this.separator,
        rounding: rounding ?? this.rounding,
      );
}
