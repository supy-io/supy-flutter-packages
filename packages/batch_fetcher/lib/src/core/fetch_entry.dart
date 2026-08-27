import 'package:meta/meta.dart';

/// The state of one id in a `BatchFetcher`'s cache.
///
/// A sealed hierarchy rather than a `value + isLoading + error` record, because
/// four of the five states are mutually exclusive and the fifth
/// ([FetchLoading]) legitimately carries a stale value. Notably, "fetched, and
/// there is no value" ([FetchAbsent]) is a distinct state from "never fetched"
/// ([FetchIdle]) — a nullable `value` field cannot tell those apart, and
/// conflating them is why a nullable `TValue` cannot be cached correctly.
///
/// Every subtype has value equality, so a widget that rebuilds on
/// `entryOf(id)` changing does not rebuild when an unrelated id resolves.
@immutable
sealed class FetchEntry<TValue> {
  const FetchEntry();

  /// Whether a request covering this id is in flight right now.
  bool get isLoading => false;

  /// The value if one is known, including a stale one during a refresh.
  ///
  /// Returns null for [FetchIdle] and [FetchAbsent]. Prefer a `switch` over
  /// this getter when the difference matters.
  TValue? get valueOrNull => null;

  /// The error if the last attempt for this id failed.
  Object? get errorOrNull => null;
}

/// Never requested, or invalidated since the last request.
final class FetchIdle<TValue> extends FetchEntry<TValue> {
  /// Creates an entry for an id that has not been requested.
  const FetchIdle();

  @override
  bool operator ==(Object other) => other is FetchIdle<TValue>;

  @override
  int get hashCode => (FetchIdle<TValue>).hashCode;

  @override
  String toString() => 'FetchIdle()';
}

/// A request covering this id is in flight.
///
/// [previous] carries the last known value when this is a refresh rather than a
/// first load, so a list can keep showing the old number instead of flashing a
/// skeleton on every revalidation.
final class FetchLoading<TValue> extends FetchEntry<TValue> {
  /// Creates a loading entry, optionally carrying the value being refreshed.
  const FetchLoading({this.previous});

  /// The last known value, if this is a refresh rather than a first load.
  final TValue? previous;

  @override
  bool get isLoading => true;

  @override
  TValue? get valueOrNull => previous;

  @override
  bool operator ==(Object other) =>
      other is FetchLoading<TValue> && other.previous == previous;

  @override
  int get hashCode => Object.hash(FetchLoading<TValue>, previous);

  @override
  String toString() => 'FetchLoading(previous: $previous)';
}

/// Fetched, and a value exists.
final class FetchPresent<TValue> extends FetchEntry<TValue> {
  /// Creates an entry holding a fetched [value].
  const FetchPresent(this.value);

  /// The fetched value. Never null, by construction.
  final TValue value;

  @override
  TValue? get valueOrNull => value;

  @override
  bool operator ==(Object other) =>
      other is FetchPresent<TValue> && other.value == value;

  @override
  int get hashCode => Object.hash(FetchPresent<TValue>, value);

  @override
  String toString() => 'FetchPresent($value)';
}

/// Fetched, and the source says this id legitimately has no value.
///
/// Distinct from [FetchFailed]: nothing went wrong, so this is cached and not
/// retried.
final class FetchAbsent<TValue> extends FetchEntry<TValue> {
  /// Creates an entry for an id the source says has no value.
  const FetchAbsent();

  @override
  bool operator ==(Object other) => other is FetchAbsent<TValue>;

  @override
  int get hashCode => (FetchAbsent<TValue>).hashCode;

  @override
  String toString() => 'FetchAbsent()';
}

/// The last attempt for this id failed.
///
/// [willRetry] is false once the `RetryPolicy` has given up, which is the
/// signal a UI needs to offer a manual retry affordance instead of a spinner.
final class FetchFailed<TValue> extends FetchEntry<TValue> {
  /// Creates a failed entry for [error].
  const FetchFailed(this.error, {this.willRetry = false, this.previous});

  /// What went wrong on the last attempt.
  final Object error;

  /// Whether the fetcher has scheduled another attempt.
  final bool willRetry;

  /// The last known value, if this id had resolved before it started failing.
  final TValue? previous;

  @override
  TValue? get valueOrNull => previous;

  @override
  Object? get errorOrNull => error;

  @override
  bool operator ==(Object other) =>
      other is FetchFailed<TValue> &&
      other.error == error &&
      other.willRetry == willRetry &&
      other.previous == previous;

  @override
  int get hashCode =>
      Object.hash(FetchFailed<TValue>, error, willRetry, previous);

  @override
  String toString() =>
      'FetchFailed($error, willRetry: $willRetry, previous: $previous)';
}
