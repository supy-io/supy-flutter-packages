import 'package:batch_fetcher/src/core/observer.dart';

/// A [BatchFetcherObserver] that records what happened, for assertions.
class RecordingObserver<TId> extends BatchFetcherObserver<TId> {
  /// Creates an empty recorder.
  RecordingObserver();

  /// One entry per request started, holding the ids it carried.
  final List<List<TId>> batches = [];

  /// One entry per request that finished, with the error if it threw.
  final List<Object?> batchErrors = [];

  /// Retries scheduled, as `(id, attempt, delay)`.
  final List<(TId, int, Duration)> retries = [];

  /// Ids the retry policy gave up on.
  final List<TId> gaveUp = [];

  /// Unsettled values re-queued, as `(id, attempt, delay)`.
  final List<(TId, int, Duration)> unsettled = [];

  @override
  void onBatchStart(Object? key, List<TId> ids) =>
      batches.add(List<TId>.unmodifiable(ids));

  @override
  void onBatchEnd(Object? key, List<TId> ids, {Object? error}) =>
      batchErrors.add(error);

  @override
  void onRetryScheduled(TId id, int attempt, Duration delay) =>
      retries.add((id, attempt, delay));

  @override
  void onGaveUp(TId id, Object error) => gaveUp.add(id);

  @override
  void onUnsettled(TId id, int attempt, Duration delay) =>
      unsettled.add((id, attempt, delay));
}
