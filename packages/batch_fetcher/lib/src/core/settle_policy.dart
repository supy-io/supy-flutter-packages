import 'package:meta/meta.dart';

/// Decides whether a *successfully fetched* value is final, or whether the
/// source is still computing it.
///
/// This is the generic form of "the request succeeded and returned 0, but 0
/// means the server has not finished aggregating yet". That is a fact about a
/// particular endpoint, so it belongs in a policy the caller supplies — a
/// fetcher that assumes it has no way to be right for the endpoints where 0
/// is a real answer, and every caller that disagrees has to switch the
/// behaviour off.
///
/// Unsettled values are still cached and still shown; they are simply
/// re-fetched after [retryDelay], up to [maxAttempts] times, after which the
/// value is accepted as final.
@immutable
abstract interface class SettlePolicy<TValue> {
  /// Whether [value] is final.
  bool isSettled(TValue value);

  /// How long to wait before re-fetching an unsettled value.
  Duration get retryDelay;

  /// How many re-fetches to attempt before accepting the value as final.
  int get maxAttempts;
}

/// A [SettlePolicy] from a predicate.
///
/// ```dart
/// // An inventory cost of 0 means aggregation is still running; give it two
/// // more looks, three seconds apart, then believe it.
/// SettleWhen<double>((cost) => cost != 0, maxAttempts: 2)
/// ```
class SettleWhen<TValue> implements SettlePolicy<TValue> {
  /// Creates a policy that treats a value as final when [predicate] holds.
  const SettleWhen(
    this.predicate, {
    this.retryDelay = const Duration(seconds: 3),
    this.maxAttempts = 1,
  }) : assert(maxAttempts >= 0, 'maxAttempts cannot be negative');

  /// Returns true when the value is final.
  final bool Function(TValue value) predicate;

  @override
  final Duration retryDelay;

  @override
  final int maxAttempts;

  @override
  bool isSettled(TValue value) => predicate(value);
}
