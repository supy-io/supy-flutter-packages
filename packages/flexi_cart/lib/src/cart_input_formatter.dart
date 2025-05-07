import 'package:flutter/services.dart';

/// A mapping of Arabic numerals to Western numerals.
const _arabicNumbersMap = {
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
};

/// A formatter for quantity input fields that supports Arabic numerals
/// and limits decimal places to [fractionCount].
///
/// Inherits from [CartInputNumberFormatter] with default [fractionCount]
/// set to 2.
class CartQuantityInputFormatter extends CartInputNumberFormatter {
  /// Creates a [CartQuantityInputFormatter] with optional [max] value and
  /// default [fractionCount] of 2.
  CartQuantityInputFormatter({
    super.fractionCount = 2,
    super.max,
  });
}

/// A formatter for price input fields that supports Arabic numerals
/// and customizable decimal precision.
///
/// Inherits from [CartInputNumberFormatter].
class CartPriceInputFormatter extends CartInputNumberFormatter {
  /// Creates a [CartPriceInputFormatter] with a required [fractionCount] and
  /// optional [max] value.
  CartPriceInputFormatter({
    required super.fractionCount,
    super.max,
  });
}

/// A base formatter that normalizes Arabic digits, enforces numeric-only input,
/// limits decimal precision, and optionally constrains values to a maximum.
class CartInputNumberFormatter extends TextInputFormatter {
  /// Creates a [CartInputNumberFormatter].
  ///
  /// [fractionCount] controls the number of decimal digits allowed.
  /// [max] sets the maximum valid numeric value.
  CartInputNumberFormatter({this.fractionCount = 3, this.max = 99999999});

  /// The maximum allowable value.
  final num max;

  /// The number of decimal places allowed.
  final int fractionCount;

  /// Transforms the user input to:
  /// - Convert Arabic numerals to Western digits.
  /// - Replace commas with periods.
  /// - Enforce one decimal point max.
  /// - Trim to [fractionCount] decimal places.
  /// - Reject values over [max].
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final arabicNumbersRegx = RegExp('[٠-٩]');
    final dotOrCommaRegx = RegExp('[.,]');

    var input = newValue.text.replaceAllMapped(arabicNumbersRegx, (match) {
      return _arabicNumbersMap[match.group(0)!]!;
    }).replaceAll(',', '.');

    if (dotOrCommaRegx.allMatches(input).length > 1 ||
        input.contains(RegExp('[^0-9.]'))) {
      return oldValue;
    }

    if (input.startsWith('.')) input = '0$input';

    final parsed = double.tryParse(input);
    if (parsed == null || parsed > max) return oldValue;

    final parts = input.split('.');
    if (parts.length == 2 && parts[1].length > fractionCount) {
      input = '${parts[0]}.${parts[1].substring(0, fractionCount)}';
    }

    return TextEditingValue(
      text: input,
      selection: TextSelection.collapsed(offset: input.length),
    );
  }
}

/// A deprecated formatter that allows input of quantities using Arabic or
/// Western digits, with a maximum integer value constraint.
///
/// Use [CartQuantityInputFormatter] instead for improved handling of
/// decimal values and consistent logic.
@Deprecated(' deprecated please use [CartQuantityInputFormatter] instead')
class QuantityInputFormatter extends TextInputFormatter {
  /// Creates a [QuantityInputFormatter] with an optional [maxQuantity].
  @Deprecated('deprecated please use [CartQuantityInputFormatter] instead')
  QuantityInputFormatter([this.maxQuantity = 999999]);

  /// The maximum quantity allowed.
  final int maxQuantity;

  /// Validates quantity input:
  /// - Converts Arabic numerals.
  /// - Disallows more than one decimal or comma.
  /// - Removes decimals before parsing and comparing to [maxQuantity].
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == ',' || newValue.text == '.') return oldValue;

    final arabicNumbersRegx = RegExp('[٠-٩]');
    final dotOrCommaRegx = RegExp('[.,]');

    // Replace Arabic numbers and commas
    final newText = newValue.text.replaceAllMapped(arabicNumbersRegx, (match) {
      return _arabicNumbersMap[match.group(0)!]!;
    }).replaceAll(',', '.');

    // Check if there are multiple dots or commas
    if (dotOrCommaRegx.allMatches(newText).length > 1) return oldValue;

    // Parse quantity ignoring decimals
    final quantity = double.tryParse(newText.replaceAll('.', ''));

    if (quantity == null || quantity > maxQuantity) return oldValue;

    return TextEditingValue(
      text: newText,
      selection: newValue.selection,
    );
  }
}
