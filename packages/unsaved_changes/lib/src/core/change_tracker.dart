import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/baseline_source.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/change_set.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';
import 'package:unsaved_changes/src/core/tracker_options.dart';

/// Reports whether an editable surface still matches the state it was loaded
/// with, and what differs.
///
/// A tracker captures a baseline through its [ChangeDetector]s, subscribes to
/// everything those detectors say can move the live state, and republishes a
/// [ChangeSet] whenever the set of differences actually changes. It notifies
/// listeners only on a real change, so a `select` on [changeCount] stays cheap
/// under a stream of keystrokes.
///
/// [C] is whatever the detectors read from — a struct of providers, a bloc, a
/// form. [K] is the consumer's own change-kind enum.
class ChangeTracker<C, K extends Object> extends ChangeNotifier {
  /// Creates a tracker over [sources].
  ///
  /// When [baseline] is supplied the tracker re-captures automatically as the
  /// saved state is replaced; otherwise call [captureBaseline] directly.
  ChangeTracker({
    required this.sources,
    required List<ChangeDetector<C, K>> detectors,
    BaselineSource<Object>? baseline,
    this.options = const TrackerOptions(),
  })  : assert(
          detectors.map((detector) => detector.id).toSet().length ==
              detectors.length,
          'Detector ids must be unique',
        ),
        _detectors = List.unmodifiable(detectors),
        _baselineSource = baseline {
    final source = _baselineSource;
    if (source == null) {
      captureBaseline();
      return;
    }
    source.signal.addListener(_syncWithBaselineSource);
    _syncWithBaselineSource();
  }

  /// What the detectors read from.
  final C sources;

  /// Tuning for this tracker.
  final TrackerOptions options;

  final List<ChangeDetector<C, K>> _detectors;
  final BaselineSource<Object>? _baselineSource;

  final Map<String, DetectorSession<C, K>> _sessions = {};
  final Set<String> _degraded = {};
  final List<VoidCallback> _unsubscribes = [];

  Object? _baselineOf;
  bool _recomputeScheduled = false;
  Timer? _debounceTimer;
  ChangeSet<K> _changes = ChangeSet<K>.empty();

  /// Everything that currently differs from the baseline.
  ChangeSet<K> get changes => _changes;

  /// Whether anything differs from the baseline.
  bool get hasChanges => _changes.isNotEmpty;

  /// How many differences are reported.
  int get changeCount => _changes.length;

  /// The distinct kinds currently reported.
  Set<K> get kinds => _changes.kinds;

  /// Whether a baseline has been captured. While `false` nothing is reported,
  /// because there is nothing to compare against.
  bool get isTracking => _sessions.isNotEmpty;

  /// Detectors that threw and are being skipped.
  Set<String> get degradedDetectors => Set.unmodifiable(_degraded);

  /// Re-captures the baseline, discarding every currently reported change.
  ///
  /// Pass [detectorId] to re-baseline a single detector — "the user accepted
  /// this one edit, stop reporting it" — leaving the rest untouched.
  void captureBaseline({String? detectorId}) {
    if (detectorId != null) {
      final detector = _detectors.firstWhere(
        (candidate) => candidate.id == detectorId,
        orElse: () => throw ArgumentError.value(
          detectorId,
          'detectorId',
          'No detector with this id is registered',
        ),
      );
      _startSession(detector);
      _scheduleRecompute();
      return;
    }

    _sessions.clear();
    _degraded.clear();
    for (final detector in _detectors) {
      _startSession(detector);
    }

    _subscribe();
    options.observer?.onBaselineCaptured(options.trackerId, _sessions.keys);
    _publish(ChangeSet<K>.empty());
  }

  void _startSession(ChangeDetector<C, K> detector) {
    try {
      _sessions[detector.id] = detector.start(sources);
      _degraded.remove(detector.id);
    } on Object catch (error, stackTrace) {
      _sessions.remove(detector.id);
      _markDegraded(detector.id, error, stackTrace);
    }
  }

  void _syncWithBaselineSource() {
    final source = _baselineSource!;
    final saved = source.read();
    if (saved == null) return;
    if (source.isSameRevision(saved, _baselineOf)) return;

    _baselineOf = saved;
    captureBaseline();
  }

  void _subscribe() {
    _unsubscribeAll();

    final listenables = <Listenable>{};
    final streams = <Stream<Object?>>{};
    for (final detector in _detectors) {
      if (_degraded.contains(detector.id)) continue;
      try {
        listenables.addAll(detector.listenables(sources));
        streams.addAll(detector.streams(sources));
      } on Object catch (error, stackTrace) {
        _markDegraded(detector.id, error, stackTrace);
      }
    }

    for (final listenable in listenables) {
      listenable.addListener(_scheduleRecompute);
      _unsubscribes.add(() => listenable.removeListener(_scheduleRecompute));
    }
    for (final stream in streams) {
      final subscription = stream.listen((_) => _scheduleRecompute());
      _unsubscribes.add(subscription.cancel);
    }
  }

  void _unsubscribeAll() {
    for (final unsubscribe in _unsubscribes) {
      unsubscribe();
    }
    _unsubscribes.clear();
  }

  void _scheduleRecompute() {
    if (_sessions.isEmpty) return;

    if (options.debounce > Duration.zero) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(options.debounce, _recompute);
      return;
    }

    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    scheduleMicrotask(() {
      _recomputeScheduled = false;
      _recompute();
    });
  }

  void _recompute() {
    final describing = <TrackedChange<K>>[];
    final fallback = <TrackedChange<K>>[];

    for (final detector in _detectors) {
      final session = _sessions[detector.id];
      if (session == null) continue;

      final Iterable<TrackedChange<K>> found;
      try {
        found = session.diff(sources).toList(growable: false);
      } on Object catch (error, stackTrace) {
        _sessions.remove(detector.id);
        _markDegraded(detector.id, error, stackTrace);
        continue;
      }

      (detector.role == DetectorRole.fallback ? fallback : describing)
          .addAll(found.map((change) => change.taggedWith(detector.id)));
    }

    _publish(
      ChangeSet<K>(
        List.unmodifiable(describing.isNotEmpty ? describing : fallback),
      ),
    );
  }

  void _publish(ChangeSet<K> next) {
    if (next == _changes) return;
    _changes = next;
    options.observer?.onChanges(
      options.trackerId,
      next.changes.cast<TrackedChange<Object>>(),
    );
    notifyListeners();
  }

  void _markDegraded(String detectorId, Object error, StackTrace stackTrace) {
    _degraded.add(detectorId);
    options.observer?.onDetectorFailed(
      options.trackerId,
      detectorId,
      error,
      stackTrace,
    );
    assert(() {
      debugPrint(
        'ChangeTracker(${options.trackerId}): detector "$detectorId" failed '
        'and is now skipped. $error',
      );

      return true;
    }(), 'debug-only reporting of a degraded detector');
  }

  /// A human-readable dump of what each detector reports — the answer to
  /// "why does it say I have unsaved changes?".
  String describe() {
    final buffer = StringBuffer('ChangeTracker(${options.trackerId})\n')
      ..writeln('  tracking: $isTracking')
      ..writeln('  changes: ${_changes.length}');
    for (final detector in _detectors) {
      final tag = _degraded.contains(detector.id)
          ? 'DEGRADED'
          : _sessions.containsKey(detector.id)
              ? detector.role.name
              : 'not started';
      final owned = _changes.changes
          .where((change) => change.detectorId == detector.id)
          .toList();
      buffer.writeln('  - ${detector.id} [$tag]: $owned');
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _baselineSource?.signal.removeListener(_syncWithBaselineSource);
    _unsubscribeAll();
    _sessions.clear();
    super.dispose();
  }

  @override
  String toString() =>
      'ChangeTracker(${options.trackerId}, changes: ${_changes.length})';
}
