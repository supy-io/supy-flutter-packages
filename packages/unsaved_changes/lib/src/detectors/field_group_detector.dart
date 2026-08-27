import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';
import 'package:unsaved_changes/src/detectors/equality.dart';

/// A set of fields that report one change kind between them.
class FieldGroup<C, K extends Object> {
  /// Creates a field group.
  const FieldGroup({
    required this.kind,
    required this.fields,
    this.subject,
    this.equals,
  });

  /// The kind reported when any field in this group moves.
  final K kind;

  /// The fields, by name. Names only have to be unique within the group.
  final Map<String, Object? Function(C sources)> fields;

  /// The subject reported alongside [kind].
  final String? subject;

  /// How to compare this group's values. Defaults to [defaultEquals].
  final bool Function(Object? a, Object? b)? equals;
}

/// Reports a change per [FieldGroup] whose fields no longer match the
/// baseline.
///
/// This replaces the hand-written "snapshot a record of fields, compare them
/// field by field, emit a kind" detector that most surfaces would otherwise
/// write once per section.
class FieldGroupDetector<C, K extends Object>
    extends SnapshotChangeDetector<Map<String, Object?>, C, K> {
  /// Creates a field-group detector.
  FieldGroupDetector({
    required this.id,
    required this.groups,
    this.listenablesOf,
    this.streamsOf,
    this.role = DetectorRole.describing,
  }) : assert(
          groups.isNotEmpty,
          'A detector with no groups reports nothing',
        );

  @override
  final String id;

  @override
  final DetectorRole role;

  /// The groups this detector watches.
  final List<FieldGroup<C, K>> groups;

  /// Listenables whose notifications mean these fields may have moved.
  final Iterable<Listenable> Function(C sources)? listenablesOf;

  /// Streams whose events mean these fields may have moved.
  final Iterable<Stream<Object?>> Function(C sources)? streamsOf;

  @override
  Map<String, Object?> capture(C sources) {
    final captured = <String, Object?>{};
    for (var index = 0; index < groups.length; index++) {
      for (final field in groups[index].fields.entries) {
        captured['$index.${field.key}'] = field.value(sources);
      }
    }

    return captured;
  }

  @override
  Iterable<TrackedChange<K>> compare(
    Map<String, Object?> baseline,
    C sources,
  ) {
    final changes = <TrackedChange<K>>[];
    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final equals = group.equals ?? defaultEquals;
      final moved = group.fields.entries.any(
        (field) =>
            !equals(field.value(sources), baseline['$index.${field.key}']),
      );
      if (moved) {
        changes.add(TrackedChange(group.kind, subject: group.subject));
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
