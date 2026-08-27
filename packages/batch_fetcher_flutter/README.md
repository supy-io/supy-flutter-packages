# batch_fetcher_flutter

Flutter bindings for [`batch_fetcher`](https://pub.dev/packages/batch_fetcher):
a `ChangeNotifier` facade and a builder that rebuilds one row at a time.

The engine is pure Dart on purpose, so it can drive a bloc without a
`ChangeNotifier` in the middle. This package is for the case where you do want
one.

```dart
final costs = BatchFetchNotifier<String, double, BatchKey>(
  request: (ids, key) async =>
      BatchOutcome.resolved(await api.costs(ids, at: key)),
);

// In a row, rebuilding only when *this* id changes:
BatchFetchBuilder<String, double>(
  source: costs,
  id: event.id,
  builder: (context, entry) => switch (entry) {
    FetchPresent(:final value) => Text(format(value)),
    FetchLoading() => const CostSkeleton(),
    FetchFailed(:final willRetry) => RetryChip(enabled: !willRetry),
    FetchAbsent() || FetchIdle() => const Text('—'),
  },
);
```

## Why the builder, and not `AnimatedBuilder`

A notifier fires once per change, and a batch changes many ids at once. An
`AnimatedBuilder` over the notifier therefore rebuilds all 120 rows whenever any
one id resolves. `BatchFetchBuilder` compares the entry for its own id and
rebuilds only on a real change — the selector pattern, packaged, so no feature
has to remember it.

Entries have value equality precisely so this works.

## Ownership

`BatchFetchNotifier(...)` builds the fetcher and owns it: disposing the
notifier disposes the fetcher. When the fetcher outlives the notifier — it is
registered in a service locator, say — wrap it instead and say so:

```dart
BatchFetchNotifier.wrapping(sharedFetcher, owns: false);
```

## `BatchFetchListenable`

`BatchFetchBuilder` takes a `BatchFetchListenable<TId, TValue>` rather than a
`BatchFetchNotifier<TId, TValue, TKey>`. A widget needs the state of one id and
a signal when it changes; neither depends on how requests are grouped. Erasing
`TKey` at that boundary is what lets one widget serve fetchers with different
key types — the alternative people reach for is an interface that erases the
value type to `dynamic` too, which throws away the type safety that made the
generics worth having.

Implement it directly if you have a source that is not a `BatchFetcher`.
