import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';

/// Which side of a membership change to report.
enum MembershipDelta {
  /// Only keys that appeared.
  added,

  /// Only keys that disappeared.
  removed,

  /// Both.
  both,
}

/// Reports keys entering or leaving a set — "which items has the user staged
/// a resolution for", "which rows are selected".
class MembershipDetector<C, K extends Object>
    extends SnapshotChangeDetector<Set<Object>, C, K> {
  /// Creates a membership detector.
  MembershipDetector({
    required this.id,
    required this.kind,
    required this.keysOf,
    this.subjectOf,
    this.removedKind,
    this.emitOn = MembershipDelta.added,
    this.listenablesOf,
    this.streamsOf,
    this.role = DetectorRole.describing,
  });

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Reported for a key that appeared.
  final K kind;

  /// Reported for a key that disappeared. Defaults to [kind].
  final K? removedKind;

  /// Reads the current membership.
  final Iterable<Object> Function(C sources) keysOf;

  /// Names a key for a user.
  final String? Function(C sources, Object key)? subjectOf;

  /// Which deltas to report.
  final MembershipDelta emitOn;

  /// Listenables whose notifications mean membership may have moved.
  final Iterable<Listenable> Function(C sources)? listenablesOf;

  /// Streams whose events mean membership may have moved.
  final Iterable<Stream<Object?>> Function(C sources)? streamsOf;

  @override
  Set<Object> capture(C sources) => keysOf(sources).toSet();

  @override
  Iterable<TrackedChange<K>> compare(Set<Object> baseline, C sources) {
    final current = capture(sources);
    final changes = <TrackedChange<K>>[];

    if (emitOn != MembershipDelta.removed) {
      for (final key in current) {
        if (baseline.contains(key)) continue;
        changes
            .add(TrackedChange(kind, subject: subjectOf?.call(sources, key)));
      }
    }
    if (emitOn != MembershipDelta.added) {
      for (final key in baseline) {
        if (current.contains(key)) continue;
        changes.add(
          TrackedChange(
            removedKind ?? kind,
            subject: subjectOf?.call(sources, key),
          ),
        );
      }
    }

    return changes;
  }

  @override
  Iterable<Listenable> listenables(C sources) =>
      listenablesOf?.call(sources) ?? const [];

  @override
  Iterable<Stream<Object?>> streams(C sources) =>
      streamsOf?.call(sources) ?? const [];
}
