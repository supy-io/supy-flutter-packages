/// How to resolve an amount sitting exactly on a rounding boundary.
enum RoundingMode {
  /// Rounds the **decimal the value represents**, half away from zero.
  ///
  /// `412.565` rounds to `412.57`, which is what a person who typed
  /// `412.565` expects. Implemented on the shortest decimal string that
  /// round-trips to the same double, so no epsilon fudge is involved.
  halfUpDecimal,

  /// Rounds the **binary value**, half away from zero — `toStringAsFixed`
  /// semantics.
  ///
  /// `412.565` is stored as `412.56499…`, so it rounds *down* to `412.56`.
  /// Correct about the double, surprising about the money. Use only to match
  /// a system that already behaves this way.
  halfUpBinary,
}

/// Rounds [value] to [fractionDigits] decimal places.
///
/// Defaults to [RoundingMode.halfUpDecimal] — the humane answer for money,
/// and the one that matches what a user typed.
///
/// It is still binary floating point: the *result* is a double and may not be
/// exactly representable. Exactness needs integer minor units. What this
/// function guarantees is that the rounding decision is made on the decimal a
/// person would recognise, in one place, the same way every time.
double roundToFractionDigits(
  double value,
  int fractionDigits, {
  RoundingMode mode = RoundingMode.halfUpDecimal,
}) {
  if (fractionDigits < 0 || fractionDigits > 20) {
    throw ArgumentError.value(
      fractionDigits,
      'fractionDigits',
      'must be between 0 and 20',
    );
  }
  if (!value.isFinite) return value;
  if (mode == RoundingMode.halfUpBinary) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  final text = value.toString();
  // Very large or very small magnitudes print in exponential form, where
  // there is no decimal point to cut. Their nearest double is far coarser
  // than the requested precision anyway, so the binary answer is the same.
  if (text.contains('e') || text.contains('E')) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  final point = text.indexOf('.');
  if (point < 0) return value;
  if (text.length - point - 1 <= fractionDigits) return value;

  final negative = text.startsWith('-');
  final digits = text.replaceAll('-', '').replaceAll('.', '');
  final keep = point - (negative ? 1 : 0) + fractionDigits;

  var kept = BigInt.parse(digits.substring(0, keep));
  if (int.parse(digits[keep]) >= 5) kept += BigInt.one;

  final padded = kept.toString().padLeft(fractionDigits + 1, '0');
  final rounded = fractionDigits == 0
      ? padded
      : '${padded.substring(0, padded.length - fractionDigits)}'
          '.${padded.substring(padded.length - fractionDigits)}';

  return double.parse(negative ? '-$rounded' : rounded);
}
