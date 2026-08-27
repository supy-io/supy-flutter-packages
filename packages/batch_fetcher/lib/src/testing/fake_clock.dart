import 'dart:async';

import 'package:batch_fetcher/src/core/clock.dart';

/// A [Clock] whose time only moves when a test moves it.
///
/// Timers scheduled through it fire during [advance], in due order, and a
/// callback that schedules another timer inside the window is honoured — so
/// one `advance` can carry a debounce, the request it triggers, and the
/// backoff that follows.
///
/// Unlike wrapping the fetcher in `fakeAsync`, this leaves the test's own
/// `Future`s on the real microtask queue, so `await` still works normally.
class FakeClock implements Clock {
  /// Creates a clock starting at [start], or at an arbitrary fixed instant.
  FakeClock({DateTime? start}) : _now = start ?? DateTime.utc(2026);

  DateTime _now;
  final List<_FakeTimer> _timers = [];

  @override
  DateTime now() => _now;

  @override
  Timer timer(Duration duration, void Function() callback) {
    final timer = _FakeTimer(
      _now.add(duration < Duration.zero ? Duration.zero : duration),
      callback,
      _timers.remove,
    );
    _timers.add(timer);
    return timer;
  }

  /// Timers scheduled and not yet fired or cancelled.
  int get pendingTimers => _timers.length;

  /// Moves time forward by [duration], firing every timer that comes due.
  ///
  /// Yields to the microtask queue between timers so an `async` callback can
  /// make progress, which is what lets a single call drive debounce → request →
  /// retry.
  Future<void> advance(Duration duration) async {
    final target = _now.add(duration);
    while (true) {
      final due = _timers.where((timer) => !timer.due.isAfter(target)).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      if (due.isEmpty) break;
      final next = due.first;
      _now = next.due;
      _timers.remove(next);
      next.fire();
      await pumpMicrotasks();
    }
    _now = target;
    await pumpMicrotasks();
  }

  /// Lets already-scheduled microtasks and completed futures run, without
  /// moving time.
  ///
  /// Deliberately microtasks only, never `Future.delayed`. Under
  /// `testWidgets` the binding fakes real `Timer`s and only advances them when
  /// the tester pumps, so awaiting a zero-duration delay there deadlocks: the
  /// await blocks the test, and only the test could unblock it. Microtasks are
  /// not faked, so they drain in both zones.
  Future<void> pumpMicrotasks([int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.microtask(() {});
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.due, this._callback, this._onCancel);

  final DateTime due;
  final void Function() _callback;
  final void Function(_FakeTimer) _onCancel;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() {
    _active = false;
    _onCancel(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
