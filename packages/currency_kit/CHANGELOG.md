## 0.0.1

- Initial release: `CurrencyCode`, `Money`, `ExchangeRate`, `MoneyFormatter`,
  `MoneyParser` and `CurrencyRegistry`, built around display-only conversion.
- Rounding defaults to half-up on the decimal a user typed
  (`RoundingMode.halfUpDecimal`), with `halfUpBinary` available for parity
  with systems that round the stored double.
