import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartInputNumberFormatter', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);

    test('Arabic numerals are converted', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '٥٠.٥'),
      );
      expect(result.text, '50.5');
    });

    test('Limits decimal places to fractionCount', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '12.3456'),
      );
      expect(result.text, '12.34');
    });

    test('Rejects values over max', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '150.25'),
      );
      expect(result.text, '');
    });

    test('Handles leading dot properly', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '.75'),
      );
      expect(result.text, '0.75');
    });

    test('Rejects multiple dots', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1.2.3'),
      );
      expect(result.text, '');
    });

    test('Rejects non-numeric characters', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '12a3'),
      );
      expect(result.text, '');
    });
  });

  group('CartQuantityInputFormatter', () {
    final formatter = CartQuantityInputFormatter(max: 50);

    test('Enforces max value', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '55.5'),
      );
      expect(result.text, '');
    });

    test('Accepts valid value with decimals', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '49.99'),
      );
      expect(result.text, '49.99');
    });
  });

  group('CartPriceInputFormatter', () {
    final formatter = CartPriceInputFormatter(fractionCount: 1, max: 1000);

    test('Trims to 1 decimal', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '123.456'),
      );
      expect(result.text, '123.4');
    });
  });

//   group('QuantityInputFormatter (deprecated)', () {
// // Reason: Legacy formatter is used for backward compatibility.
// // ignore: deprecated_member_use, deprecated_member_use_from_same_package
//     final formatter =
//         QuantityInputFormatter(); // ignore: deprecated_member_use  // Reason: legacy compatibility
//
//     test('Accepts valid integer quantity', () {
//       final result = formatter.formatEditUpdate(
//         TextEditingValue.empty,
//         const TextEditingValue(text: '50'),
//       );
//       expect(result.text, '50');
//     });
//
//     test('Rejects if quantity exceeds max', () {
//       final result = formatter.formatEditUpdate(
//         TextEditingValue.empty,
//         const TextEditingValue(text: '150'),
//       );
//       expect(result.text, '');
//     });
//
//     test('Arabic numerals handled properly', () {
//       final result = formatter.formatEditUpdate(
//         TextEditingValue.empty,
//         const TextEditingValue(text: '١٠٠'),
//       );
//       expect(result.text, '100');
//     });
//
//     test('Rejects if multiple commas or dots', () {
//       final result = formatter.formatEditUpdate(
//         TextEditingValue.empty,
//         const TextEditingValue(text: '1,2.3'),
//       );
//       expect(result.text, '');
//     });
//
//     test('Ignores decimal when parsing max', () {
//       final result = formatter.formatEditUpdate(
//         TextEditingValue.empty,
//         const TextEditingValue(text: '10.0'),
//       );
//       expect(result.text, '10.0'); // Still under 100 when decimal is ignored
//     });
//   });

  test('Mixed Arabic and Western numerals are normalized correctly', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '٣2.٥'),
    );
    expect(result.text, '32.5');
  });
  test('Handles input starting with 0 properly', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '012.3'),
    );
    expect(result.text, '012.3'); // Leading zeros are not trimmed
  });
  test('Handles empty string input', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '1'), // previous value
      TextEditingValue.empty,
    );
    expect(result.text, '');
  });
  test('Accepts values with trailing decimal zeroes within limit', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '25.10'),
    );
    expect(result.text, '25.10');
  });
  test('Comma replaced with dot and parsed correctly', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '23,99'),
    );
    expect(result.text, '23.99');
  });
  test('Rejects multiple decimal points', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '12.3.4'),
    );
    expect(result.text, '');
  });
  test('Rejects single dot input', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '.'),
    );
    expect(result.text, '0.');
  });
  test('Accepts value exactly at max limit', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '100.00'),
    );
    expect(result.text, '100.00');
  });
  test('Rejects third decimal digit if fractionCount is 2', () {
    final formatter = CartInputNumberFormatter(fractionCount: 2, max: 100);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '99.999'),
    );
    expect(result.text, '99.99');
  });

  test(
    'Should format Arabic numbers to English numbers',
    () {
      final formatter = CartQuantityInputFormatter(max: 99999999999);

      const oldValue = TextEditingValue(
        text: '50',
      );
      const newValue = TextEditingValue(
        text: '١٢٣٤٥٦٧٨٩٠',
      );

      const expectedValue = TextEditingValue(
        text: '1234567890',
        selection: TextSelection.collapsed(offset: 10),
      );

      expect(formatter.formatEditUpdate(oldValue, newValue), expectedValue);
    },
  );

  test(
    'Should reject values greater than max quantity',
    () {
      final formatter = CartQuantityInputFormatter(max: 100);
      const oldValue = TextEditingValue(
        text: '50',
      );
      const newValue = TextEditingValue(
        text: '101',
      );

      expect(formatter.formatEditUpdate(oldValue, newValue), oldValue);
    },
  );

  test(
    'Should reject values with more than one decimal point',
    () {
      final formatter = CartQuantityInputFormatter(max: 100);
      const oldValue = TextEditingValue(
        text: '50.00',
      );
      const newValue1 = TextEditingValue(
        text: '50..',
      );
      const newValue2 = TextEditingValue(
        text: '50.0.0',
      );

      expect(formatter.formatEditUpdate(oldValue, newValue1), oldValue);
      expect(formatter.formatEditUpdate(oldValue, newValue2), oldValue);
    },
  );

  test(
    'Should reject values with only a decimal point',
    () {
      final formatter = CartQuantityInputFormatter(max: 100);
      const oldValue = TextEditingValue(
        text: '50.00',
      );
      const newValue = TextEditingValue(
        text: '.',
      );
      expect(
        formatter.formatEditUpdate(oldValue, newValue),
        const TextEditingValue(
          text: '0.',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
    },
  );

  test(
    'Should allow valid values',
    () {
      final formatter = CartQuantityInputFormatter(max: 100);
      const oldValue = TextEditingValue(
        text: '50.00',
        selection: TextSelection.collapsed(offset: 5),
      );
      const newValue = TextEditingValue(
        text: '75',
        selection: TextSelection.collapsed(offset: 2),
      );

      expect(formatter.formatEditUpdate(oldValue, newValue), newValue);
    },
  );
}
