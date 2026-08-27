import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';
import 'package:unsaved_changes/src/detectors/equality.dart';
import 'package:unsaved_changes/src/detectors/facet.dart';

/// Compares facets of a single value read from [C] — a bloc state, a view
/// model, a controller — and subscribes to the stream that publishes it.
///
/// This is the path for surfaces built on bloc rather than [ChangeNotifier]:
/// there is nothing to wrap, because a bloc is already a `Stream`.
class ValueStreamDetector<C, S, K extends Object>
    extends SnapshotChangeDetector<List<List<Object?>>, C, K> {
  /// Creates a value detector.
  ValueStreamDetector({
    required this.id,
    required this.read,
    required this.facets,
    this.streamOf,
    this.listenablesOf,
    this.subjectOf,
    this.role = DetectorRole.describing,
  });

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Reads the current value.
  final S Function(C sources) read;

  /// The aspects of the value that are compared.
  final List<Facet<S, K>> facets;

  /// The stream that publishes new values.
  final Stream<Object?> Function(C sources)? streamOf;

  /// Listenables that also mean the value may have moved.
  final Iterable<Listenable> Function(C sources)? listenablesOf;

  /// Names the value for a user.
  final String? Function(S value)? subjectOf;

  @override
  List<List<Object?>> capture(C sources) {
    final value = read(sources);

    return [for (final facet in facets) facet.values(value)];
  }

  @override
  Iterable<TrackedChange<K>> compare(
    List<List<Object?>> baseline,
    C sources,
  ) {
    final value = read(sources);
    final changes = <TrackedChange<K>>[];

    for (var index = 0; index < facets.length; index++) {
      if (index >= baseline.length) continue;
      final facet = facets[index];
      if (defaultEquals(facet.values(value), baseline[index])) continue;
      changes.add(
        TrackedChange(
          facet.kind,
          subject: facet.subject ?? subjectOf?.call(value),
        ),
      );
    }

    return changes;
  }

  @override
  Iterable<Listenable> listenables(C sources) =>
      listenablesOf?.call(sources) ?? const [];

  @override
  Iterable<Stream<Object?>> streams(C sources) => [
        if (streamOf != null) streamOf!(sources),
      ];
}
