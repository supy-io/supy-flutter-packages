# batch_fetcher

Coalesces per-item value lookups into batched requests, with debouncing, per-id
caching, retry with backoff, and typed per-id state.

A list renders 120 rows. Each row needs a number only the server can compute — a
cost, an on-hand quantity, an order total — and the endpoint takes 50 ids per
call. You want 3 requests, not 120, and you want each row to render its own
loading, value, absent and failed states without rebuilding the list.

That is the whole problem this package solves.

```dart
final fetcher = BatchFetcher<String, double, BatchKey>(
  request: (ids, key) async =>
      BatchOutcome.resolved(await api.costs(ids, at: key)),
);

// Safe to call on every rebuild with the whole visible page.
fetcher.fetch(BatchScope(key: scopeKey, ids: visibleIds));

switch (fetcher.entryOf(id)) {
  FetchPresent(:final value) => Text('$value'),
  FetchLoading() => const Skeleton(),
  FetchFailed(:final willRetry) => RetryChip(enabled: !willRetry),
  FetchAbsent() || FetchIdle() => const Text('—'),
}
```

Pure Dart — no Flutter dependency, so it drives a bloc as readily as a
`ChangeNotifier`. For the Flutter bindings (`BatchFetchNotifier`,
`BatchFetchBuilder`) see
[`batch_fetcher_flutter`](https://pub.dev/packages/batch_fetcher_flutter).

## What it does

- **Coalesces** every id queued inside one debounce window into a single
  request, and splits at your API's `maxBatchSize`.
- **Groups** requests by a scope key, so ids needing different parameters (a
  location, an as-of date) never end up in the same call.
- **Skips** ids that are cached, in flight, or inside a retry backoff — so
  calling `fetch` on every rebuild is the intended usage, not a leak.
- **Retries** per id with exponential backoff and jitter, waking itself when the
  window elapses, and **stops** when the budget is spent.
- **Keeps a failed batch together**: the backoff delay is resolved once per
  attempt, not once per id, so fifty ids that failed together come back as one
  retry rather than fifty.
- **Distinguishes** never-fetched from fetched-and-empty from failed, so a
  nullable value type is not a problem and a UI can tell "—" from "retry".
- **Discards** a response that lands after the id was invalidated, or after the
  fetcher was disposed.
- **Reclaims** a scope's queue and timers once it goes quiet.

### Non-goals

Not an HTTP client (you supply the `Future`), not a persistent cache
(in-memory, process lifetime), not pagination (this fetches satellite values for
ids you already have).

## The five states

`entryOf(id)` returns a sealed `FetchEntry<TValue>`:

| State | Meaning |
|---|---|
| `FetchIdle` | never requested, or invalidated since |
| `FetchLoading(previous:)` | in flight; `previous` carries the value being refreshed |
| `FetchPresent(value)` | fetched, value exists — never null |
| `FetchAbsent` | fetched, and the source says there is no value |
| `FetchFailed(error, willRetry:)` | last attempt failed; `willRetry: false` means the policy gave up |

`FetchIdle` and `FetchAbsent` being different states is the point: a nullable
`value` field cannot tell "haven't asked" from "asked, nothing there", and
conflating them is why a nullable `TValue` cannot be cached correctly.

## Reporting results

Your `request` callback returns a `BatchOutcome`, which has room for all three
per-id answers:

```dart
request: (ids, key) async {
  final response = await api.costs(ids);
  return BatchOutcome(
    values: response.found,        // resolved
    failures: response.errors,     // failed, retry per policy
    absent: response.noSuchItem,   // fetched, no value, stop asking
  );
}
```

Throwing means the *whole batch* failed. Returning `failures` means those ids
failed and the rest succeeded — the distinction that otherwise pushes callers
into fabricating a neutral value (which hides real failures) or throwing for the
whole batch (which discards the ids that worked).

Ids you were asked for and mentioned in none of the three are handled by
`unlisted`, which defaults to `UnlistedIds.absent`. Set it to
`UnlistedIds.failed` for an endpoint that contracts to return every id, or
`UnlistedIds.ignore` for a partitioned fetch where a sibling request covers the
rest.

## Scope keys: read this one

Requests are grouped by key, and **Dart compares `List`, `Set` and `Map` by
identity**. A hand-written key class holding a collection field therefore mints
a *different* key on every rebuild even when the contents are identical, which
defeats every part of a batching layer at once: a fresh queue, a fresh
in-flight flag and a fresh debounce timer per rebuild, none of them reclaimed,
plus duplicate requests that de-duplication should have collapsed. It is silent,
and it presents as a slow leak.

Use `BatchKey`, which rejects non-scalar parts outright and normalises the two
scalars whose equality surprises people:

```dart
BatchKey(['loc_1', 'ret_1', eventDate])  // DateTime → epoch micros, so
                                         // UTC and local agree
BatchKey.none                            // one global scope
```

If you must write your own key type, give it value equality over scalar fields
only. As a backstop the fetcher asserts once live scopes exceed
`config.maxTrackedScopes` (32 by default), naming this bug — that tripwire is
there because it is the one failure mode with no other symptom.

## Retry, and "the server is still computing it"

Two separate policies, because they are two separate things:

```dart
BatchFetcher(
  request: ...,
  // The request failed. Try again, four more times, backing off.
  retry: const ExponentialBackoff(maxAttempts: 5),
  // The request succeeded and returned 0 — but for this endpoint 0 means
  // aggregation has not finished. Look twice more, then believe it.
  settle: const SettleWhen<double>(_isPriced, maxAttempts: 2),
);

bool _isPriced(double cost) => cost != 0;
```

An unsettled value is still cached and still shown — the row displays the 0 and
quietly corrects itself — rather than being hidden behind a spinner.

`maxAttempts` is **enforced**, not clamped: once `nextDelay` returns null the id
is marked `willRetry: false` and is never queued again until it is explicitly
invalidated. Pass `NoRetry()` to fail on the first error.

## Invalidating

```dart
fetcher.invalidate(ids: ['a', 'b']);  // clear these
fetcher.invalidate();                 // clear everything
fetcher.refresh(['a']);               // clear and re-request under the same scope
fetcher.trim(visibleIds);             // forget everything off-screen
```

A response already in flight for an invalidated id is discarded when it lands,
so a stale reply cannot overwrite state the user just changed.

## Awaiting

`fetch` returns a future that completes once every requested id has reached a
terminal state: a value the settle policy accepts, a confirmed absence, or a
failure the retry policy gave up on. So `await fetch(...)` means "done trying",
not "one request went out" — and it therefore waits out backoff and settle
delays. Callers that do not want to wait simply do not await it.

## Testing

`package:batch_fetcher/batch_fetcher_testing.dart` ships the doubles, and adds
no dependencies:

```dart
final clock = FakeClock();
final script = ScriptedRequest<String, int, BatchKey>([
  throwing(boom),          // first call fails
  resolveAll,              // second succeeds
]);
final observer = RecordingObserver<String>();

final fetcher = BatchFetcher(
  request: script.call,
  clock: clock,
  observer: observer,
);

fetcher.fetch(BatchScope(key: BatchKey.none, ids: ['a']));
await clock.advance(const Duration(seconds: 2));   // debounce + backoff

expect(script.callCount, 2);
expect(observer.retries.single.$2, 1);
```

Time is injected rather than slept through. That is not only about speed: a
widget test cannot wrap a real fetcher in `fakeAsync`, because the fake controls
the test's own futures while the fetcher's `Timer`s keep running on the real
clock, and the two deadlock.

`RecordingObserver` is how you assert the property this package exists to
guarantee — *how many requests went out*. A cache-only assertion cannot see the
difference between one request serving fifty ids and fifty serving one each.

## API surface

| Type | Role |
|---|---|
| `BatchFetcher<TId, TValue, TKey>` | the engine |
| `BatchScope<TId, TKey>` | the ids to fetch and the key grouping them |
| `BatchKey` | a scope key with real value equality |
| `BatchOutcome<TId, TValue>` | values / failures / absences from one request |
| `FetchEntry<TValue>` | the five per-id states |
| `RetryPolicy`, `ExponentialBackoff`, `NoRetry` | when to try again |
| `SettlePolicy`, `SettleWhen` | whether a fetched value is final |
| `BatchFetcherConfig` | debounce, batch size, TTL, scope tripwire |
| `BatchFetcherObserver` | what actually happened |
| `Clock`, `SystemClock` | injected time |
