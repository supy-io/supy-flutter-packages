import 'package:flutter/services.dart';

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

class QuantityInputFormatter extends TextInputFormatter {
  QuantityInputFormatter([this.maxQuantity = 999999]);

  final int maxQuantity;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == ',' || newValue.text == '.') return oldValue;

    final arabicNumbersRegx = RegExp(r'[٠-٩]');
    final dotOrCommaRegx = RegExp(r'[.,]');

    // Replace Arabic numbers and commas
    String newText = newValue.text.replaceAllMapped(arabicNumbersRegx, (match) {
      return _arabicNumbersMap[match.group(0)!]!;
    }).replaceAll(',', '.');

    // Check if there are multiple dots or commas
    if (dotOrCommaRegx.allMatches(newText).length > 1) return oldValue;

    // Parse quantity
    final quantity = double.tryParse(newText.replaceAll('.', ''));

    if (quantity == null || quantity > maxQuantity) return oldValue;

    return TextEditingValue(
      text: newText,
      selection: newValue.selection,
    );
  }
}
