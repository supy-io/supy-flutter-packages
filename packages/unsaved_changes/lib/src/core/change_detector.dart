import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';

/// How a tracker treats the changes a detector reports.
enum DetectorRole {
  /// Produces named changes that can be explained to a user.
  describing,

  /// A safety net for edits no describing detector recognises.
  ///
  /// Its changes are dropped whenever any describing detector fired, so a
  /// whole-payload digest never inflates the count for an edit that is
  /// already reported by name.
  fallback,
}

/// Captures a baseline from [C] and reports how the live state differs.
///
/// The captured snapshot type never appears here: [start] hides it inside a
/// [DetectorSession]. That keeps a heterogeneous `List<ChangeDetector<C, K>>`
/// genuinely type-safe, instead of relying on an unsound downcast when the
/// tracker hands a stored baseline back to the detector that made it.
///
/// Most detectors should extend [SnapshotChangeDetector] rather than
/// implementing this directly.
abstract class ChangeDetector<C, K extends Object> {
  /// Creates a detector.
  const ChangeDetector();

  /// Identifies this detector within a tracker. Must be unique.
  String get id;

  /// Whether this detector describes changes or backstops them.
  DetectorRole get role => DetectorRole.describing;

  /// Captures the baseline and returns a session that can diff against it.
  DetectorSession<C, K> start(C sources);

  /// Listenables whose notifications mean the live state may have moved.
  Iterable<Listenable> listenables(C sources) => const [];

  /// Streams whose events mean the live state may have moved.
  Iterable<Stream<Object?>> streams(C sources) => const [];
}

/// A baseline captured by a [ChangeDetector], able to diff against itself.
///
/// Single-method by design: it exists to hide the captured snapshot type,
/// not to group behaviour, so it cannot collapse into a function type.
// ignore: one_member_abstracts
abstract class DetectorSession<C, K extends Object> {
  /// Creates a session.
  const DetectorSession();

  /// Reports how [sources] now differs from the captured baseline.
  Iterable<TrackedChange<K>> diff(C sources);
}

/// A [ChangeDetector] that captures a value of type [S] and compares against
/// it — the shape almost every detector wants.
abstract class SnapshotChangeDetector<S, C, K extends Object>
    extends ChangeDetector<C, K> {
  /// Creates a snapshot detector.
  const SnapshotChangeDetector();

  /// Extracts the comparable state from [sources].
  ///
  /// Snapshots must hold extracted values, never the live objects — a source
  /// mutated in place would otherwise silently rewrite the baseline and the
  /// edit would go unreported.
  S capture(C sources);

  /// Reports how [sources] differs from [baseline].
  Iterable<TrackedChange<K>> compare(S baseline, C sources);

  @override
  DetectorSession<C, K> start(C sources) =>
      _SnapshotSession<S, C, K>(this, capture(sources));
}

class _SnapshotSession<S, C, K extends Object> extends DetectorSession<C, K> {
  const _SnapshotSession(this._detector, this._baseline);

  final SnapshotChangeDetector<S, C, K> _detector;
  final S _baseline;

  @override
  Iterable<TrackedChange<K>> diff(C sources) =>
      _detector.compare(_baseline, sources);
}
