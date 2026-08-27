import 'package:flutter/foundation.dart';

/// A single difference between the captured baseline and the live state.
///
/// [kind] is the consumer's own enum, so a feature keeps an exhaustive
/// `switch` when it maps a change to a sentence — adding a kind without
/// translating it becomes a compile error rather than a runtime fallback.
@immutable
class TrackedChange<K extends Object> {
  /// Creates a change of [kind], optionally naming the thing that changed.
  const TrackedChange(this.kind, {this.subject, this.detectorId});

  /// What kind of change this is.
  final K kind;

  /// The thing that changed, identified for a human — an item name, a label.
  ///
  /// Never localized: turning `(kind, subject)` into a sentence is the
  /// consumer's job.
  final String? subject;

  /// Which detector produced this change. Set by the tracker; used only for
  /// diagnostics, and deliberately excluded from equality so that moving a
  /// change between detectors does not churn the published list.
  final String? detectorId;

  /// Returns a copy tagged with [id].
  TrackedChange<K> taggedWith(String id) =>
      TrackedChange<K>(kind, subject: subject, detectorId: id);

  @override
  bool operator ==(Object other) =>
      other is TrackedChange<K> &&
      other.kind == kind &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(kind, subject);

  @override
  String toString() =>
      'TrackedChange($kind${subject == null ? '' : ', $subject'})';
}
