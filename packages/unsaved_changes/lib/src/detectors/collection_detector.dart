import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';
import 'package:unsaved_changes/src/detectors/equality.dart';
import 'package:unsaved_changes/src/detectors/facet.dart';

/// What a keyed collection captured for one item.
@immutable
class ItemSnapshot {
  /// Creates an item snapshot.
  const ItemSnapshot({required this.subject, required this.facetValues});

  /// How the item is named to a user.
  final String? subject;

  /// One entry per facet, in the detector's facet order.
  final List<List<Object?>> facetValues;
}

/// Reports items added to, removed from, or edited inside a keyed collection.
///
/// Only extracted values are captured, never the items themselves — a cart
/// item mutated in place would otherwise rewrite its own baseline and the edit
/// would go unreported.
class CollectionDetector<C, K extends Object, T>
    extends SnapshotChangeDetector<Map<Object, ItemSnapshot>, C, K> {
  /// Creates a detector over a keyed collection.
  CollectionDetector({
    required this.id,
    required this.itemsOf,
    required this.subjectOf,
    required this.facets,
    this.addedKind,
    this.removedKind,
    this.listenablesOf,
    this.streamsOf,
    this.role = DetectorRole.describing,
  });

  /// Creates a detector over an unkeyed iterable, keyed by [keyOf].
  factory CollectionDetector.keyed({
    required String id,
    required Iterable<T> Function(C sources) itemsOf,
    required Object Function(T item) keyOf,
    required String? Function(T item) subjectOf,
    required List<Facet<T, K>> facets,
    K? addedKind,
    K? removedKind,
    Iterable<Listenable> Function(C sources)? listenablesOf,
    Iterable<Stream<Object?>> Function(C sources)? streamsOf,
    DetectorRole role = DetectorRole.describing,
  }) =>
      CollectionDetector<C, K, T>(
        id: id,
        itemsOf: (sources) => {
          for (final item in itemsOf(sources)) keyOf(item): item,
        },
        subjectOf: subjectOf,
        facets: facets,
        addedKind: addedKind,
        removedKind: removedKind,
        listenablesOf: listenablesOf,
        streamsOf: streamsOf,
        role: role,
      );

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Reads the collection, keyed by whatever identifies an item.
  final Map<Object, T> Function(C sources) itemsOf;

  /// Names an item for a user.
  final String? Function(T item) subjectOf;

  /// The aspects of an item that are compared, each reporting its own kind.
  final List<Facet<T, K>> facets;

  /// Reported when an item appears. Omit to ignore additions.
  final K? addedKind;

  /// Reported when an item disappears. Omit to ignore removals.
  final K? removedKind;

  /// Listenables whose notifications mean the collection may have moved.
  final Iterable<Listenable> Function(C sources)? listenablesOf;

  /// Streams whose events mean the collection may have moved.
  final Iterable<Stream<Object?>> Function(C sources)? streamsOf;

  @override
  Map<Object, ItemSnapshot> capture(C sources) => {
        for (final entry in itemsOf(sources).entries)
          entry.key: ItemSnapshot(
            subject: subjectOf(entry.value),
            facetValues: [
              for (final facet in facets) facet.values(entry.value),
            ],
          ),
      };

  @override
  Iterable<TrackedChange<K>> compare(
    Map<Object, ItemSnapshot> baseline,
    C sources,
  ) {
    final current = capture(sources);
    final changes = <TrackedChange<K>>[];

    final removed = removedKind;
    if (removed != null) {
      for (final entry in baseline.entries) {
        if (!current.containsKey(entry.key)) {
          changes.add(TrackedChange(removed, subject: entry.value.subject));
        }
      }
    }

    for (final entry in current.entries) {
      final before = baseline[entry.key];
      if (before == null) {
        final added = addedKind;
        if (added != null) {
          changes.add(TrackedChange(added, subject: entry.value.subject));
        }
        continue;
      }

      for (var index = 0; index < facets.length; index++) {
        if (index >= before.facetValues.length) continue;
        if (defaultEquals(
          entry.value.facetValues[index],
          before.facetValues[index],
        )) {
          continue;
        }
        changes.add(
          TrackedChange(
            facets[index].kind,
            subject: facets[index].subject ?? entry.value.subject,
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
