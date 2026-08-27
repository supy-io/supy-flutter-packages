import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';

/// An immutable read-model over the changes a tracker currently reports.
///
/// Exposes the queries a UI actually needs — a count for a banner, the kinds
/// for an icon row, the subjects for a summary sentence — without callers
/// re-deriving them from the raw list on every rebuild.
@immutable
class ChangeSet<K extends Object> {
  /// Wraps [changes] as a read-model.
  const ChangeSet(this.changes);

  /// An empty set.
  const ChangeSet.empty() : changes = const [];

  /// Every change, in detector-registration order.
  final List<TrackedChange<K>> changes;

  /// Whether nothing differs from the baseline.
  bool get isEmpty => changes.isEmpty;

  /// Whether anything differs from the baseline.
  bool get isNotEmpty => changes.isNotEmpty;

  /// How many changes are reported.
  int get length => changes.length;

  /// The distinct kinds present, preserving first-seen order.
  Set<K> get kinds => {for (final change in changes) change.kind};

  /// Every change of [kind].
  List<TrackedChange<K>> ofKind(K kind) => [
        for (final change in changes)
          if (change.kind == kind) change
      ];

  /// How many changes of [kind] are reported.
  int countOfKind(K kind) =>
      changes.where((change) => change.kind == kind).length;

  /// Subjects grouped by kind, for building summary sentences.
  Map<K, List<String?>> get subjectsByKind {
    final grouped = <K, List<String?>>{};
    for (final change in changes) {
      (grouped[change.kind] ??= []).add(change.subject);
    }

    return grouped;
  }

  @override
  bool operator ==(Object other) =>
      other is ChangeSet<K> && listEquals(other.changes, changes);

  @override
  int get hashCode => Object.hashAll(changes);

  @override
  String toString() => 'ChangeSet($changes)';
}
