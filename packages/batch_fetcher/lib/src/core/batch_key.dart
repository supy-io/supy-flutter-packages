import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A batching key built from scalar parts, with real value equality.
///
/// Requests are grouped by key, so the key decides which ids can travel in
/// one request together — typically a location, a retailer and an as-of date.
///
/// ## Why this type exists
///
/// Dart compares `List`, `Set` and `Map` by identity. A hand-written key
/// class holding a collection field therefore produces a *different* key every
/// rebuild even when the contents are identical, which silently defeats every
/// part of a batching layer at once: a fresh queue, a fresh in-flight flag and
/// a fresh debounce timer per rebuild, none of them ever reclaimed, and
/// duplicate requests that the de-duplication logic should have collapsed.
///
/// [BatchKey] makes that mistake unrepresentable by rejecting non-scalar parts,
/// and normalises the two scalars whose equality is surprising:
///
/// - `DateTime` is reduced to its microseconds since epoch, so a UTC and a
///   local instance of the same instant are one key. (`DateTime.==` compares
///   the `isUtc` flag too, so they otherwise are not.)
/// - `Enum` is reduced to its type and index rather than relying on identity.
///
/// ```dart
/// BatchKey(['loc_1', 'ret_1', eventDate])   // grouped per location + date
/// BatchKey.none                             // one global scope
/// ```
@immutable
class BatchKey {
  /// Creates a key from [parts], which must all be scalar.
  ///
  /// Throws [ArgumentError] on a collection part — see the class docs for why
  /// that is a defect rather than a style preference.
  factory BatchKey(List<Object?> parts) =>
      BatchKey._(List<Object?>.unmodifiable(parts.map(_normalize)));

  const BatchKey._(this._parts);

  /// A single shared scope, for a fetcher whose requests need no grouping.
  static const BatchKey none = BatchKey._(<Object?>[]);

  final List<Object?> _parts;

  static const ListEquality<Object?> _equality = ListEquality<Object?>();

  static Object? _normalize(Object? part) {
    if (part is DateTime) return part.microsecondsSinceEpoch;
    if (part is Enum) return '${part.runtimeType}.${part.index}';
    if (part == null || part is num || part is String || part is bool) {
      return part;
    }
    if (part is BatchKey) return part;
    throw ArgumentError.value(
      part,
      'parts',
      'BatchKey parts must be scalar (null, num, String, bool, DateTime, Enum '
          'or another BatchKey). A collection compares by identity in Dart, so '
          'using one as a batching key mints a new key on every rebuild — see '
          'the BatchKey docs.',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BatchKey && _equality.equals(_parts, other._parts);

  @override
  int get hashCode => _equality.hash(_parts);

  @override
  String toString() => 'BatchKey($_parts)';
}
