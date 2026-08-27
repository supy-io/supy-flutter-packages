import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';
import 'package:unsaved_changes/src/core/tracker_options.dart';

/// A [Listenable] a test can poke, standing in for a provider notifying.
class TestTicker extends ChangeNotifier {
  /// Notifies every listener.
  void tick() => notifyListeners();

  /// Whether anything is subscribed.
  ///
  /// `hasListeners` is protected and can only be surfaced from a subclass, so
  /// asserting "the tracker actually wired this up" needs this.
  bool get isSubscribed => hasListeners;
}

/// A detector whose findings the test scripts, so a tracker's own behaviour —
/// not any real detector's — is what is under test.
class ScriptedDetector<C, K extends Object> extends ChangeDetector<C, K> {
  /// Creates a scripted detector.
  ScriptedDetector(
    this.id, {
    this.listenable,
    this.stream,
    this.changes = const [],
    this.role = DetectorRole.describing,
    this.throwOnStart = false,
    this.throwOnDiff = false,
  });

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Subscribed by the tracker, if given.
  final Listenable? listenable;

  /// Subscribed by the tracker, if given.
  final Stream<Object?>? stream;

  /// What [DetectorSession.diff] reports. Reassign between diffs to script a
  /// sequence.
  List<TrackedChange<K>> changes;

  /// Makes [start] throw, to exercise degradation.
  bool throwOnStart;

  /// Makes `diff` throw, to exercise degradation.
  bool throwOnDiff;

  /// How many times a baseline was captured.
  int startCount = 0;

  /// How many times a diff ran.
  int diffCount = 0;

  @override
  DetectorSession<C, K> start(C sources) {
    startCount++;
    if (throwOnStart) throw StateError('ScriptedDetector($id).start');

    return _ScriptedSession<C, K>(this);
  }

  @override
  Iterable<Listenable> listenables(C sources) => [
        if (listenable != null) listenable!,
      ];

  @override
  Iterable<Stream<Object?>> streams(C sources) => [if (stream != null) stream!];
}

class _ScriptedSession<C, K extends Object> extends DetectorSession<C, K> {
  _ScriptedSession(this.detector);

  final ScriptedDetector<C, K> detector;

  @override
  Iterable<TrackedChange<K>> diff(C sources) {
    detector.diffCount++;
    if (detector.throwOnDiff) {
      throw StateError('ScriptedDetector(${detector.id}).diff');
    }

    return detector.changes;
  }
}

/// Records everything a tracker reports, for asserting on afterwards.
class RecordingObserver implements ChangeTrackerObserver {
  /// One entry per baseline capture: the detector ids that started.
  final List<List<String>> baselines = [];

  /// One entry per published change list.
  final List<List<TrackedChange<Object>>> published = [];

  /// Detector ids that failed, in order.
  final List<String> failures = [];

  @override
  void onBaselineCaptured(String trackerId, Iterable<String> detectorIds) =>
      baselines.add(detectorIds.toList());

  @override
  void onChanges(String trackerId, List<TrackedChange<Object>> changes) =>
      published.add(changes);

  @override
  void onDetectorFailed(
    String trackerId,
    String detectorId,
    Object error,
    StackTrace stackTrace,
  ) =>
      failures.add(detectorId);
}

/// Lets the microtask a tracker schedules run.
///
/// Use this in plain `test()` bodies. Under `testWidgets` the faked clock
/// deadlocks against a real `Future.delayed` — drive the tracker with
/// `tester.pump(duration)` there, or use `fakeAsync` for a debounced tracker.
Future<void> settle() => Future<void>.delayed(Duration.zero);
