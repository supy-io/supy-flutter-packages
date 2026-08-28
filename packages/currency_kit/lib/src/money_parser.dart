import 'package:currency_kit/src/currency_code.dart';
import 'package:currency_kit/src/money.dart';

/// Reads user-typed text back into [Money].
///
/// The mirror of `MoneyFormatter`: tolerant of what a person types — currency
/// affixes, spaces, grouping separators, Arabic-Indic digits — and strict
/// about what it returns. Ambiguous input yields null rather than a guess.
///
/// ```dart
/// const parser = MoneyParser();
/// parser.tryParse('AED 1,234.50', CurrencyCode.aed); // Money(1234.5, AED)
/// parser.tryParse('١٢٣٤٫٥٠', CurrencyCode.aed);      // Money(1234.5, AED)
/// parser.tryParse('abc', CurrencyCode.aed);          // null
/// ```
class MoneyParser {
  /// A parser that reads [decimalSeparator] as the decimal point.
  ///
  /// When null, the separator is inferred: the last `.` or `,` in the text
  /// wins if the other also appears, otherwise a lone `,` followed by exactly
  /// three digits is treated as grouping.
  const MoneyParser({this.decimalSeparator});

  /// Forces the decimal separator instead of inferring it.
  final String? decimalSeparator;

  /// Parses [text] as an amount of [currency], or returns null.
  Money? tryParse(String text, CurrencyCode currency) {
    final amount = _amount(text);
    return amount == null ? null : Money(amount, currency);
  }

  /// Parses [text] as an amount of [currency].
  ///
  /// Throws [FormatException] when [text] is not a number.
  Money parse(String text, CurrencyCode currency) {
    final money = tryParse(text, currency);
    if (money == null) {
      throw FormatException('Not a monetary amount', text);
    }
    return money;
  }

  double? _amount(String text) {
    final normalized = _normalizeDigits(text.trim());
    if (normalized.isEmpty) return null;

    final negative = _isNegative(normalized);
    final separator = decimalSeparator ?? _inferSeparator(normalized);

    final buffer = StringBuffer();
    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      if (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39) {
        buffer.write(char);
      } else if (char == separator) {
        buffer.write('.');
      }
    }

    final digits = buffer.toString();
    if (digits.isEmpty || digits == '.') return null;

    final value = double.tryParse(digits);
    if (value == null) return null;
    return negative ? -value : value;
  }

  /// Whether a minus sign or opening bracket precedes the first digit.
  ///
  /// The sign is not always leading: the default display format is
  /// `AED -36.90`, so anything before the number counts.
  bool _isNegative(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x30 && rune <= 0x39) return false;
      if (rune == 0x2D || rune == 0x28) return true;
    }
    return false;
  }

  /// Maps Arabic-Indic and Eastern Arabic-Indic digits onto ASCII, and the
  /// Arabic decimal separator onto `.`.
  String _normalizeDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30);
      } else if (rune == 0x066B) {
        buffer.write('.');
      } else if (rune == 0x066C) {
        buffer.write(',');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  String _inferSeparator(String text) {
    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');

    if (lastDot >= 0 && lastComma >= 0) {
      return lastDot > lastComma ? '.' : ',';
    }
    if (lastComma >= 0) {
      // A lone comma with exactly three digits after it is grouping: 1,234.
      final trailing = text.length - lastComma - 1;
      return trailing == 3 ? '.' : ',';
    }
    return '.';
  }
}
