## 0.1.1

- Fix `trim()` resurrecting the ids it was asked to forget. It dropped an id's
  cache entry but left the id in its scope's queue, so an id awaiting a retry
  was re-requested and re-created on the next drain — leaking the memory the
  call was meant to free. It also now drops ids queued but not yet requested,
  and completes any caller awaiting an id it removed, which would otherwise
  wait for a request that is never sent.

## 0.1.0

- Initial release: `BatchFetcher`, `BatchScope`, `BatchKey`, `BatchOutcome`,
  the sealed `FetchEntry` states, `RetryPolicy` / `ExponentialBackoff` /
  `NoRetry`, `SettlePolicy` / `SettleWhen`, `BatchFetcherConfig`,
  `BatchFetcherObserver` and the injected `Clock`.
- Adds the `batch_fetcher_testing` library: `FakeClock`, `ScriptedRequest` and
  `RecordingObserver`. No new dependencies — it works under both `test` and
  `flutter_test`.
