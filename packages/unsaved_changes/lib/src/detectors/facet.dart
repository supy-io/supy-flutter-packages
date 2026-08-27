import 'package:unsaved_changes/src/core/change_detector.dart';

/// One comparable aspect of a value, and the change kind it reports.
///
/// A facet groups the fields that mean the same thing to a user: quantity and
/// received-quantity are one facet, because "the quantity changed" is one
/// thing to tell someone, not two.
class Facet<T, K extends Object> {
  /// Creates a facet reporting [kind] when any of [values] moves.
  const Facet({required this.kind, required this.values, this.subject});

  /// The kind reported when this facet differs.
  final K kind;

  /// Extracts the values that make up this facet.
  ///
  /// Must return extracted primitives, not live objects — see
  /// [SnapshotChangeDetector.capture].
  final List<Object?> Function(T value) values;

  /// Overrides the subject reported for this facet.
  final String? subject;
}
