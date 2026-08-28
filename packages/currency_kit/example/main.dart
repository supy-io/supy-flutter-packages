// An example prints its output; that is the point of it. It also catches a
// CurrencyMismatchError to show what a currency mix-up looks like — real code
// should fix the call site rather than catch it.
// ignore_for_file: avoid_print, avoid_catching_errors

import 'package:currency_kit/currency_kit.dart';

void main() {
  // The retailer keeps its books in AED; a supplier quotes in USD.
  const local = CurrencyCode.aed;
  const display = CurrencyCode.usd;
  final rate = ExchangeRate(base: display, quote: local, rate: 3.69);

  print(rate); // 1 USD = 3.69 AED

  // 1. The user is reading USD and types 10 into a price field.
  //    Convert once, at the input boundary, and store the canonical amount.
  const typed = Money(10, display);
  final stored = rate.toQuote(typed).rounded();
  print('stored: ${stored.format()}'); // stored: AED 36.90

  // 2. They switch the picker to AED. Nothing is recomputed — the same
  //    stored amount is simply rendered in a different currency.
  print('as AED: ${stored.format()}'); // as AED: AED 36.90
  print('as USD: ${rate.toBase(stored).format()}'); // as USD: USD 10.00

  // 3. Toggling the picker cannot move the stored value, because switching
  //    currency never writes to it.
  var round = stored;
  for (var i = 0; i < 20; i++) {
    round = rate.toQuote(rate.toBase(round));
  }
  print('still ${stored.format()}? ${round.rounded() == stored}'); // true

  // Arithmetic across currencies throws CurrencyMismatchError rather than
  // silently producing a number that means nothing.
  try {
    print(stored + typed);
  } on CurrencyMismatchError catch (error) {
    print(error);
  }

  // Precision follows the currency, not the app.
  print(const Money(1234.5, CurrencyCode.jpy).format()); // JPY 1,235
  print(const Money(1234.5, CurrencyCode.kwd).format()); // KWD 1,234.500

  // Reading a typed string back.
  const parser = MoneyParser();
  print(parser.tryParse('AED 1,234.50', local)); // Money(1234.5, AED)
}
