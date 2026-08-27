## 0.1.0

- Initial release: `BatchFetcher`, `BatchScope`, `BatchKey`, `BatchOutcome`,
  the sealed `FetchEntry` states, `RetryPolicy` / `ExponentialBackoff` /
  `NoRetry`, `SettlePolicy` / `SettleWhen`, `BatchFetcherConfig`,
  `BatchFetcherObserver` and the injected `Clock`.
- Adds the `batch_fetcher_testing` library: `FakeClock`, `ScriptedRequest` and
  `RecordingObserver`. No new dependencies — it works under both `test` and
  `flutter_test`.
