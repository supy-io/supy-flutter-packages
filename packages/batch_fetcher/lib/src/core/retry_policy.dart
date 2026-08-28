import 'dart:math';

/// Decides whether, and how long after, a failed id is tried again.
///
/// A policy that returns null has *given up* — and the fetcher honours that by
/// marking the entry `willRetry: false` and never queueing the id again until
/// it is explicitly invalidated. A retry budget that is merely clamped rather
/// than enforced is not a budget: the attempt counter stops growing while the
/// attempts continue forever.
// A one-member interface on purpose: a policy is swapped wholesale, and a
// caller may implement it to carry state across attempts.
// ignore: one_member_abstracts
abstract interface class RetryPolicy {
  /// The delay before attempt number [attempt] + 1, or null to give up.
  ///
  /// [attempt] is the number of failures recorded for this id so far, including
  /// the one being handled — so it is 1 the first time this is called.
  Duration? nextDelay(int attempt, Object error);
}

/// Exponential backoff with jitter and an enforced attempt budget.
class ExponentialBackoff implements RetryPolicy {
  /// Creates a backoff of `base * 2^(attempt-1)`, capped at [max], spread by
  /// +/- [jitter], for at most [maxAttempts] total attempts.
  ///
  /// Pass [random] to make the jitter deterministic in tests.
  const ExponentialBackoff({
    this.base = const Duration(milliseconds: 500),
    this.max = const Duration(seconds: 10),
    this.maxAttempts = 5,
    this.jitter = 0.2,
    Random? random,
  })  : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
        assert(jitter >= 0 && jitter < 1, 'jitter must be in [0, 1)'),
        _random = random;

  /// The delay before the second attempt, doubled for each attempt after that.
  final Duration base;

  /// The ceiling the doubling is clamped to.
  final Duration max;

  /// Total attempts allowed, including the first. Enforced, not clamped.
  final int maxAttempts;

  /// Fraction the delay is randomly spread by, to avoid a thundering herd.
  final double jitter;

  final Random? _random;

  @override
  Duration? nextDelay(int attempt, Object error) {
    if (attempt >= maxAttempts) return null;

    // 1, 2, 4, 8... capped before the shift can overflow on a pathological
    // maxAttempts.
    final exponent = min(attempt - 1, 30);
    final scaled = base.inMicroseconds * (1 << exponent);
    final random = _random ?? Random();
    final spread = 1 + ((random.nextDouble() * 2) - 1) * jitter;
    final micros = min((scaled * spread).round(), max.inMicroseconds);
    return Duration(microseconds: micros);
  }
}

/// Fails permanently on the first error.
class NoRetry implements RetryPolicy {
  /// Creates a policy that never retries.
  const NoRetry();

  @override
  Duration? nextDelay(int attempt, Object error) => null;
}
