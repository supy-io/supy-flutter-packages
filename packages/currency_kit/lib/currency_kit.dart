/// Money, currency codes and exchange rates as value types.
///
/// The organising idea is **display-only conversion**: an amount you store is
/// always denominated in one canonical currency, and a second currency is a
/// *view* of it. Selecting a currency changes what a user reads, never what
/// you keep — so toggling a picker cannot move a saved number.
///
/// See `ExchangeRate` for the two boundaries where a rate is applied.
library;

export 'src/currency_code.dart';
export 'src/currency_registry.dart';
export 'src/errors.dart';
export 'src/exchange_rate.dart';
export 'src/money.dart';
export 'src/money_format.dart';
export 'src/money_formatter.dart';
export 'src/money_parser.dart';
export 'src/rounding.dart';
