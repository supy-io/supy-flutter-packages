import 'package:flutter/foundation.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:unsaved_changes/unsaved_changes.dart';
import 'package:unsaved_changes_forms/src/control_paths.dart';

/// Tracks a whole `FormGroup` for unsaved edits, with no per-field
/// configuration.
///
/// Every leaf control becomes a dotted path; [kindOf] maps a path to a change
/// kind, and paths that map to the same `(kind, subject)` collapse into one
/// change. Returning `null` from [kindOf] ignores a path entirely.
///
/// For a form-shaped surface this is often the only detector needed, which is
/// the difference between tracking being a project and tracking being one
/// registration.
class FormGroupDetector<C, K extends Object>
    extends SnapshotChangeDetector<Map<String, Object?>, C, K> {
  /// Creates a form detector.
  FormGroupDetector({
    required this.id,
    required this.formOf,
    required this.kindOf,
    this.subjectOf,
    this.ignore = const {},
    this.equalsFor,
    this.listenablesOf,
    this.role = DetectorRole.describing,
  });

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Reads the form to track.
  final FormGroup Function(C sources) formOf;

  /// Maps a leaf control path to a change kind, or `null` to ignore it.
  final K? Function(String path) kindOf;

  /// Names a path for a user. Paths sharing a `(kind, subject)` collapse into
  /// one change, so returning `null` here reports one change per kind.
  final String? Function(String path)? subjectOf;

  /// Paths never compared. Supports `*` for one whole segment, so
  /// `items.*.uiOnly` skips a per-row UI flag on every row.
  final Set<String> ignore;

  /// Overrides how a path's value is compared — most usefully
  /// [nullableStringEquals] for a text field cleared back to empty.
  final bool Function(Object? a, Object? b)? Function(String path)? equalsFor;

  /// Listenables beyond the form's own `valueChanges`.
  final Iterable<Listenable> Function(C sources)? listenablesOf;

  @override
  Map<String, Object?> capture(C sources) {
    return flattenControls(formOf(sources))
      ..removeWhere((path, _) => _isIgnored(path));
  }

  @override
  Iterable<TrackedChange<K>> compare(
    Map<String, Object?> baseline,
    C sources,
  ) {
    final current = capture(sources);
    // A LinkedHashSet, so paths collapsing to the same (kind, subject) report
    // one change while first-seen order is preserved.
    final changes = <TrackedChange<K>>{};

    for (final path in {...baseline.keys, ...current.keys}) {
      final equals = equalsFor?.call(path) ?? defaultEquals;
      if (equals(current[path], baseline[path])) continue;

      final kind = kindOf(path);
      if (kind == null) continue;
      changes.add(TrackedChange(kind, subject: subjectOf?.call(path)));
    }

    return changes;
  }

  bool _isIgnored(String path) =>
      ignore.any((pattern) => matchesControlPath(path, pattern));

  @override
  Iterable<Listenable> listenables(C sources) =>
      listenablesOf?.call(sources) ?? const [];

  @override
  Iterable<Stream<Object?>> streams(C sources) =>
      [formOf(sources).valueChanges];
}
