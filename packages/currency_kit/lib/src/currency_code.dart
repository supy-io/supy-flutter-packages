import 'package:currency_kit/src/errors.dart';
import 'package:meta/meta.dart';

/// An ISO-4217 currency code together with the number of decimal places the
/// currency is conventionally written with.
///
/// The fraction digits are part of the identity of a currency, not of an
/// amount: JPY has 0, AED has 2, KWD has 3. Formatting an amount with the
/// wrong number of decimals is the single most common currency bug, so the
/// count travels with the code rather than being passed around beside it.
///
/// ```dart
/// final aed = CurrencyCode.parse('AED');   // throws on an unknown code
/// final usd = CurrencyCode.tryParse('usd'); // null on an unknown code
/// ```
///
/// Parsing never guesses. An unrecognised code is an error, not a silent
/// fallback to some default currency — a mislabelled amount is worse than a
/// failed parse.
@immutable
final class CurrencyCode implements Comparable<CurrencyCode> {
  const CurrencyCode._(this.code, this.fractionDigits);

  /// Parses [value] as an ISO-4217 code, case-insensitively.
  ///
  /// Throws [UnknownCurrencyCode] if the code is not recognised. Use
  /// [CurrencyCode.custom] for a code this package does not know about.
  factory CurrencyCode.parse(String value) {
    final code = tryParse(value);
    if (code == null) throw UnknownCurrencyCode(value);
    return code;
  }

  /// A currency this package does not ship — a local unit, a crypto asset, or
  /// an ISO code newer than this release.
  ///
  /// Prefer `CurrencyCode.parse` for real ISO codes so a typo stays an error.
  factory CurrencyCode.custom(String value, {int fractionDigits = 2}) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be empty');
    }
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be between 0 and 20',
      );
    }
    return CurrencyCode._(normalized, fractionDigits);
  }

  /// Parses [value] as an ISO-4217 code, or returns null if it is unknown.
  static CurrencyCode? tryParse(String value) {
    final normalized = value.trim().toUpperCase();
    final digits = _fractionDigits[normalized];
    if (digits == null) return null;
    return CurrencyCode._(normalized, digits);
  }

  /// The uppercase ISO-4217 alphabetic code, e.g. `AED`.
  final String code;

  /// Decimal places this currency is conventionally written with.
  final int fractionDigits;

  /// Whether [value] is an ISO-4217 code known to this package.
  static bool isKnown(String value) =>
      _fractionDigits.containsKey(value.trim().toUpperCase());

  /// Every ISO-4217 code this package knows, uppercase and sorted.
  static Iterable<String> get knownCodes => _fractionDigits.keys;

  /// United Arab Emirates dirham.
  static const aed = CurrencyCode._('AED', 2);

  /// United States dollar.
  static const usd = CurrencyCode._('USD', 2);

  /// Euro.
  static const eur = CurrencyCode._('EUR', 2);

  /// Pound sterling.
  static const gbp = CurrencyCode._('GBP', 2);

  /// Saudi riyal.
  static const sar = CurrencyCode._('SAR', 2);

  /// Syrian pound.
  static const syp = CurrencyCode._('SYP', 2);

  /// Kuwaiti dinar — three decimal places.
  static const kwd = CurrencyCode._('KWD', 3);

  /// Japanese yen — no decimal places.
  static const jpy = CurrencyCode._('JPY', 0);

  @override
  int compareTo(CurrencyCode other) => code.compareTo(other.code);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyCode &&
          other.code == code &&
          other.fractionDigits == fractionDigits;

  @override
  int get hashCode => Object.hash(code, fractionDigits);

  @override
  String toString() => code;
}

/// Codes with their ISO-4217 minor-unit count. Anything absent is unknown;
/// anything present without an override is the ISO default of 2.
final Map<String, int> _fractionDigits = {
  for (final code in _codes) code: _exponents[code] ?? 2,
};

const _codes = <String>[
  'AED',
  'AFN',
  'ALL',
  'AMD',
  'ANG',
  'AOA',
  'ARS',
  'AUD',
  'AWG',
  'AZN',
  'BAM',
  'BBD',
  'BDT',
  'BGN',
  'BHD',
  'BIF',
  'BMD',
  'BND',
  'BOB',
  'BRL',
  'BSD',
  'BTN',
  'BWP',
  'BYN',
  'BZD',
  'CAD',
  'CDF',
  'CHF',
  'CLP',
  'CNY',
  'COP',
  'CRC',
  'CUC',
  'CUP',
  'CVE',
  'CZK',
  'DJF',
  'DKK',
  'DOP',
  'DZD',
  'EGP',
  'ERN',
  'ETB',
  'EUR',
  'FJD',
  'FKP',
  'GBP',
  'GEL',
  'GGP',
  'GHS',
  'GIP',
  'GMD',
  'GNF',
  'GTQ',
  'GYD',
  'HKD',
  'HNL',
  'HRK',
  'HTG',
  'HUF',
  'IDR',
  'ILS',
  'IMP',
  'INR',
  'IQD',
  'IRR',
  'ISK',
  'JEP',
  'JMD',
  'JOD',
  'JPY',
  'KES',
  'KGS',
  'KHR',
  'KMF',
  'KPW',
  'KRW',
  'KWD',
  'KYD',
  'KZT',
  'LAK',
  'LBP',
  'LKR',
  'LRD',
  'LSL',
  'LYD',
  'MAD',
  'MDL',
  'MGA',
  'MKD',
  'MMK',
  'MNT',
  'MOP',
  'MRU',
  'MUR',
  'MVR',
  'MWK',
  'MXN',
  'MYR',
  'MZN',
  'NAD',
  'NGN',
  'NIO',
  'NOK',
  'NPR',
  'NZD',
  'OMR',
  'PAB',
  'PEN',
  'PGK',
  'PHP',
  'PKR',
  'PLN',
  'PYG',
  'QAR',
  'RON',
  'RSD',
  'RUB',
  'RWF',
  'SAR',
  'SBD',
  'SCR',
  'SDG',
  'SEK',
  'SGD',
  'SHP',
  'SLL',
  'SOS',
  'SRD',
  'STN',
  'SVC',
  'SYP',
  'SZL',
  'THB',
  'TJS',
  'TMT',
  'TND',
  'TOP',
  'TRY',
  'TTD',
  'TWD',
  'TZS',
  'UAH',
  'UGX',
  'USD',
  'UYU',
  'UZS',
  'VEF',
  'VND',
  'VUV',
  'WST',
  'XAF',
  'XCD',
  'XOF',
  'XPF',
  'YER',
  'ZAR',
  'ZMW',
  'ZWL',
];

/// The only ISO-4217 currencies whose minor unit is not 2.
const _exponents = <String, int>{
  'BIF': 0,
  'CLP': 0,
  'DJF': 0,
  'GNF': 0,
  'ISK': 0,
  'JPY': 0,
  'KMF': 0,
  'KRW': 0,
  'PYG': 0,
  'RWF': 0,
  'UGX': 0,
  'VND': 0,
  'VUV': 0,
  'XAF': 0,
  'XOF': 0,
  'XPF': 0,
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'KWD': 3,
  'LYD': 3,
  'OMR': 3,
  'TND': 3,
};
