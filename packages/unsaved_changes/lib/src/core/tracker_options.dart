import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';

/// Observes a tracker's lifecycle — for logging, breadcrumbs, or tests.
abstract class ChangeTrackerObserver {
  /// Called whenever a baseline is captured.
  void onBaselineCaptured(String trackerId, Iterable<String> detectorIds);

  /// Called whenever the published change list actually changes.
  void onChanges(String trackerId, List<TrackedChange<Object>> changes);

  /// Called when a detector throws. The detector is marked degraded and the
  /// rest of the tracker keeps working.
  void onDetectorFailed(
    String trackerId,
    String detectorId,
    Object error,
    StackTrace stackTrace,
  );
}

/// Tuning for a tracker.
@immutable
class TrackerOptions {
  /// Creates tracker options.
  const TrackerOptions({
    this.debounce = Duration.zero,
    this.observer,
    this.trackerId = 'tracker',
  });

  /// How long to wait for the edit burst to settle before diffing.
  ///
  /// [Duration.zero] coalesces into a single microtask — one diff per frame,
  /// which is right for anything cheaper than a large collection diff.
  final Duration debounce;

  /// Optional lifecycle observer.
  final ChangeTrackerObserver? observer;

  /// Names this tracker in observer callbacks and [Object.toString].
  final String trackerId;
}
