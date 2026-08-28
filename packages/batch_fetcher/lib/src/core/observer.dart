/// Hooks for watching what a `BatchFetcher` actually does.
///
/// The property a batching layer exists to guarantee is *how many requests went
/// out*, and that is invisible from the outside — the cache looks identical
/// whether one request served fifty ids or fifty requests served one each. An
/// observer makes it assertable in tests and loggable in production.
abstract class BatchFetcherObserver<TId> {
  /// Creates an observer.
  const BatchFetcherObserver();

  /// A request is about to be sent for [ids] under [key].
  void onBatchStart(Object? key, List<TId> ids) {}

  /// A request finished. [error] is set if the whole batch threw.
  void onBatchEnd(Object? key, List<TId> ids, {Object? error}) {}

  /// [id] is being retried after a failure, after [delay].
  void onRetryScheduled(TId id, int attempt, Duration delay) {}

  /// The retry policy has given up on [id].
  void onGaveUp(TId id, Object error) {}

  /// [id] resolved to a value its settle policy considers non-final, and will
  /// be re-fetched.
  void onUnsettled(TId id, int attempt, Duration delay) {}
}
