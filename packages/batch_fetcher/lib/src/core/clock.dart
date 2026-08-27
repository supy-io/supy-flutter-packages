import 'dart:async';

/// The fetcher's only source of time.
///
/// Injected rather than called directly so tests can advance time explicitly.
/// A batching layer is almost entirely timing behaviour — debounce windows,
/// backoff delays, settle delays — and testing that against the real clock
/// means sleeping, which is slow and flaky. It also means a widget test cannot
/// use a faked clock at all: the fake controls the test's own `Future`s while
/// the fetcher's `Timer`s keep running on the real clock, and the two deadlock.
abstract interface class Clock {
  /// The current instant.
  DateTime now();

  /// Schedules [callback] to run after [duration].
  Timer timer(Duration duration, void Function() callback);
}

/// The real clock. The default everywhere outside tests.
class SystemClock implements Clock {
  /// Creates a clock backed by `DateTime.now` and `Timer`.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Timer timer(Duration duration, void Function() callback) =>
      Timer(duration, callback);
}
