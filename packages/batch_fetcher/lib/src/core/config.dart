import 'package:meta/meta.dart';

/// Timing and sizing knobs for a `BatchFetcher`.
@immutable
class BatchFetcherConfig {
  /// Creates a configuration. Every value has a working default.
  const BatchFetcherConfig({
    this.debounce = const Duration(milliseconds: 60),
    this.maxBatchSize = 50,
    this.staleAfter,
    this.maxTrackedScopes = 32,
  })  : assert(maxBatchSize > 0, 'maxBatchSize must be positive'),
        assert(maxTrackedScopes > 0, 'maxTrackedScopes must be positive');

  /// How long to wait for more ids before sending a request.
  ///
  /// Sized for one frame's worth of list-item builds, not for user input.
  final Duration debounce;

  /// The most ids one request may carry. Usually an API limit.
  final int maxBatchSize;

  /// How long a resolved value stays fresh.
  ///
  /// Null means cached for the fetcher's lifetime — the right default for the
  /// values this layer exists to fetch, which change only when the user changes
  /// something and are invalidated explicitly at that point.
  final Duration? staleAfter;

  /// The number of distinct scope keys tolerated before the fetcher asserts.
  ///
  /// A batching layer normally has a handful of live scopes: one per location,
  /// per as-of date. Unbounded scope growth means keys are not comparing equal
  /// when they should — nearly always a key holding a collection, which Dart
  /// compares by identity. This is a debug-only tripwire for that specific bug,
  /// which is otherwise silent and presents as a slow leak plus duplicate
  /// requests.
  final int maxTrackedScopes;
}
