import 'package:meta/meta.dart';

/// How to treat ids that a request was asked for but did not mention in its
/// outcome.
enum UnlistedIds {
  /// The id has no value. Cached as `FetchAbsent`, never retried.
  ///
  /// The default, because it is the reading that does not invent an error. Most
  /// endpoints that omit an id are saying "nothing here", not "something
  /// broke".
  absent,

  /// The id failed. Recorded as `FetchFailed` and retried per the retry
  /// policy.
  ///
  /// Choose this for an endpoint that contracts to return every id it is asked
  /// for, so an omission really is a fault.
  failed,

  /// Leave the id's cached state exactly as it was.
  ///
  /// For a request that deliberately answers about a subset — a partitioned
  /// fetch where a sibling request covers the rest.
  ignore,
}

/// What one batched request found.
///
/// Three outcomes per id, because two are not enough. The distinction the
/// caller could not previously express is between "this id failed, retry it"
/// and "this id has no value, stop asking" — without it, callers are pushed
/// into fabricating a neutral value (which hides real failures) or throwing for
/// the whole batch (which discards the ids that succeeded).
///
/// A thrown exception from the request callback still means "the entire batch
/// failed", which is the right shape for a transport-level error.
@immutable
class BatchOutcome<TId, TValue> {
  /// Creates an outcome from any combination of the three per-id results.
  const BatchOutcome({
    this.values = const {},
    this.failures = const {},
    this.absent = const {},
    this.unlisted = UnlistedIds.absent,
  });

  /// The common case: every id that resolved, and nothing else to say.
  const BatchOutcome.resolved(
    this.values, {
    this.unlisted = UnlistedIds.absent,
  })  : failures = const {},
        absent = const {};

  /// Ids that resolved to a value.
  final Map<TId, TValue> values;

  /// Ids that failed, with the error to report and retry against.
  final Map<TId, Object> failures;

  /// Ids the source confirmed have no value.
  final Set<TId> absent;

  /// How to treat requested ids that appear in none of the three.
  final UnlistedIds unlisted;

  @override
  String toString() => 'BatchOutcome(values: ${values.length}, '
      'failures: ${failures.length}, absent: ${absent.length}, '
      'unlisted: ${unlisted.name})';
}
