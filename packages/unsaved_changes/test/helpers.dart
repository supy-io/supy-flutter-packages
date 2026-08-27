import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

/// A synthetic domain, so the engine tests never need a real app's models.
class Doc {
  Doc({required this.title, this.revision = 1});

  String title;
  final int revision;
}

/// Live state the detectors read from.
class Sources {
  Sources({this.title = 'draft'});

  String title;
  final Ticker ticker = Ticker();
}

/// A [Listenable] a test can poke, standing in for a provider notifying.
class Ticker extends ChangeNotifier {
  void tick() => notifyListeners();

  /// Whether anything is subscribed. `hasListeners` is protected, so it can
  /// only be surfaced from inside a subclass like this one.
  bool get isSubscribed => hasListeners;
}

enum Kind { title, other }

/// A detector whose findings the test scripts, so the tracker's own behaviour
/// — not any real detector's — is what is under test.
class ScriptedDetector extends ChangeDetector<Sources, Kind> {
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

  final Listenable? listenable;
  final Stream<Object?>? stream;

  List<TrackedChange<Kind>> changes;
  bool throwOnStart;
  bool throwOnDiff;

  int startCount = 0;
  int diffCount = 0;

  @override
  DetectorSession<Sources, Kind> start(Sources sources) {
    startCount++;
    if (throwOnStart) throw StateError('start failed: $id');

    return _ScriptedSession(this);
  }

  @override
  Iterable<Listenable> listenables(Sources sources) => [
        if (listenable != null) listenable!,
      ];

  @override
  Iterable<Stream<Object?>> streams(Sources sources) => [
        if (stream != null) stream!,
      ];
}

class _ScriptedSession extends DetectorSession<Sources, Kind> {
  _ScriptedSession(this.detector);

  final ScriptedDetector detector;

  @override
  Iterable<TrackedChange<Kind>> diff(Sources sources) {
    detector.diffCount++;
    if (detector.throwOnDiff) throw StateError('diff failed: ${detector.id}');

    return detector.changes;
  }
}

/// Records everything a tracker reports.
class RecordingObserver implements ChangeTrackerObserver {
  final List<String> baselines = [];
  final List<List<TrackedChange<Object>>> published = [];
  final List<String> failures = [];

  @override
  void onBaselineCaptured(String trackerId, Iterable<String> detectorIds) =>
      baselines.add(detectorIds.join(','));

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

/// Lets the microtask the tracker schedules run.
///
/// Use this in plain `test()` bodies only. Under `testWidgets` the faked clock
/// deadlocks against a real `Future.delayed`; drive a debounced tracker with
/// `tester.pump(duration)` instead.
Future<void> settle() => Future<void>.delayed(Duration.zero);
