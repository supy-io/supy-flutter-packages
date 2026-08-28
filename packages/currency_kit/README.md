# currency_kit

Money, currency codes and exchange rates as value types — built around one rule:

> **An amount you store is always in one canonical currency. A second currency
> is a view of it.** Selecting a currency changes what a user reads, never what
> you keep.

Get that rule wrong and a user changes a dropdown and your data moves. This
package makes the right thing the easy thing, and the wrong thing hard to
express.

## The problem

The usual approach converts state when the user switches currency, and converts
back when saving. It looks symmetrical. It isn't — because the value is rounded
to the *display* currency's precision while it sits there:

```
AED 0.03  →  shown as USD 0.01  →  saved back as AED 0.04
```

Across the first 2,000 dirham at a rate of 3.69, **more than 70% of amounts do
not survive a single currency toggle.** The package's test suite pins that
number, because it is the reason the package exists.

## The rule

A rate is applied at exactly two boundaries, and nowhere else:

| Boundary | Direction | Method |
|---|---|---|
| The user typed an amount in the currency they are reading | display → canonical | `rate.toQuote(typed)` |
| An amount is stored canonically and must be shown | canonical → display | `rate.toBase(stored)` |

Between them, everything stays canonical. There is deliberately no API for
re-basing stored state.

## Usage

```dart
import 'package:currency_kit/currency_kit.dart';

// The books are kept in AED; a supplier quotes in USD.
final rate = ExchangeRate(
  base: CurrencyCode.usd,
  quote: CurrencyCode.aed,
  rate: 3.69,
);
print(rate); // 1 USD = 3.69 AED

// The user is reading USD and types 10. Convert once, then store.
final stored = rate.toQuote(const Money(10, CurrencyCode.usd)).rounded();
print(stored.format()); // AED 36.90

// They switch the picker to AED, then back to USD. Nothing is recomputed —
// the same stored amount is simply rendered differently.
print(stored.format());                    // AED 36.90
print(rate.toBase(stored).rounded().format()); // USD 10.00

// The stored amount never moved.
```

### Money

`Money` carries its currency, so "which currency is this number in?" is a type
rather than a comment. Mixing currencies throws instead of quietly producing a
meaningless number:

```dart
const aed = Money(36.90, CurrencyCode.aed);
const usd = Money(10, CurrencyCode.usd);
aed + usd; // throws CurrencyMismatchError
aed.copyWith(currency: CurrencyCode.usd); // relabels — does NOT convert
```

### Precision follows the currency

`CurrencyCode` carries its ISO-4217 minor-unit count, so JPY gets 0 decimals and
KWD gets 3 without anyone remembering to ask:

```dart
const Money(1234.5, CurrencyCode.jpy).format(); // JPY 1,235
const Money(1234.5, CurrencyCode.kwd).format(); // KWD 1,234.500
```

Apps that need one precision everywhere (to match a back office, say) override
it in the registry rather than at 60 call sites:

```dart
const formatter = MoneyFormatter(
  registry: CustomCurrencyRegistry(fractionDigitsForAll: 2),
);
```

### Parsing never guesses

An unknown code is an error, not a silent fallback — a mislabelled amount is
worse than a failed parse:

```dart
CurrencyCode.parse('XYZ');    // throws UnknownCurrencyCode
CurrencyCode.tryParse('XYZ'); // null
CurrencyCode.custom('PTS', fractionDigits: 0); // for codes we don't ship
```

`MoneyParser` reads back anything `MoneyFormatter` writes, plus what people
actually type — affixes, grouping separators, Arabic-Indic digits, and a minus
sign on either side of the currency code.

### Rounding

Money rounds the **decimal a person typed**, half away from zero:

```dart
const Money(412.565, CurrencyCode.aed).format(); // AED 412.57
```

That is not what rounding the double gives you. `412.565` is stored as
`412.56499…`, so `toStringAsFixed` — and `intl`, and most naive
implementations — round it *down* to `412.56`. The difference shows up on
about **5% of typed amounts**, which is far too often to leave to chance.

`roundToFractionDigits` gets the humane answer without an epsilon fudge, by
rounding the shortest decimal string that round-trips to the same double. If
you need to match a system that rounds the binary value instead:

```dart
roundToFractionDigits(412.565, 2, mode: RoundingMode.halfUpBinary); // 412.56
money.rounded(2, RoundingMode.halfUpBinary);
const MoneyFormat(rounding: RoundingMode.halfUpBinary);
```

Amounts are `double`. That is a documented compromise matching the JSON and
model types this package was extracted to serve; `Money` is the seam that makes
a later move to integer minor units possible without touching call sites.

## Not in this package

- **No network.** Rates come from wherever your app gets them.
- **No widgets.** This is pure Dart.
- **No re-basing API.** By design — see the rule.
