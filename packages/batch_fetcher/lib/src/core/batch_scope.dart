import 'package:meta/meta.dart';

/// The ids to fetch, and the key that groups them into a request.
///
/// This replaces the untyped `dynamic context` that a caller would otherwise
/// hand to the fetcher for it to pull ids and a key back out of: the extraction
/// happens at the call site, where the concrete type is still known, so a
/// mismatch is a compile error rather than a runtime cast failure.
@immutable
class BatchScope<TId, TKey> {
  /// Creates a scope for [ids] under [key].
  BatchScope({required this.key, required Iterable<TId> ids})
      : ids = List<TId>.unmodifiable(ids);

  /// Groups requests. Must have value equality — prefer `BatchKey`, and never a
  /// type holding a collection field.
  final TKey key;

  /// The ids the caller wants values for. Already-cached ids are skipped by the
  /// fetcher, so passing the whole visible page every rebuild is the intended
  /// usage.
  final List<TId> ids;

  @override
  String toString() => 'BatchScope(key: $key, ids: ${ids.length})';
}
