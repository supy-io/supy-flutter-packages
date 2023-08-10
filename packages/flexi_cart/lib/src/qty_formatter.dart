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
    if (newValue.text == '.') return oldValue;

    final arabicNumbersRegx = RegExp(r'[٠١٢٣٤٥٦٧٨٩]');
    final dotRegx = RegExp(r'[.]');

    newValue = TextEditingValue(
      text: newValue.text.splitMapJoin(
        arabicNumbersRegx,
        onMatch: (m) => _arabicNumbersMap[m.group(0)!]!,
        onNonMatch: (n) => n,
      ),
      selection: newValue.selection,
    );

    final dots = dotRegx.allMatches(newValue.text).length;

    if (dots > 1) return oldValue;

    final quantity = double.tryParse(newValue.text.replaceAll('.', ''));

    if (quantity == null || quantity > maxQuantity) return oldValue;

    return newValue;
  }
}
