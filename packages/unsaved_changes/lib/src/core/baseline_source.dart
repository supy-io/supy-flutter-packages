import 'package:flutter/foundation.dart';

/// Where a tracker learns that the saved state it should compare against has
/// been replaced — typically the provider or bloc holding the server's copy.
@immutable
class BaselineSource<T extends Object> {
  /// Creates a baseline source.
  const BaselineSource({
    required this.read,
    required this.signal,
    this.revisionOf,
  });

  /// Reads the current saved state, or `null` before it has loaded.
  final T? Function() read;

  /// Notifies whenever [read] might return something new.
  final Listenable signal;

  /// Identifies a revision of the saved state.
  ///
  /// Two reads with equal revisions share a baseline, so a rebuild does not
  /// discard the user's in-progress edits while a successful save does.
  /// Defaults to object identity.
  final Object? Function(T value)? revisionOf;

  /// The revision of [value] under this source's policy.
  Object? revisionFor(T value) => revisionOf?.call(value) ?? value;

  /// Whether [a] and [b] are the same revision.
  bool isSameRevision(T? a, T? b) {
    if (a == null || b == null) return identical(a, b);
    if (revisionOf == null) return identical(a, b);

    return revisionFor(a) == revisionFor(b);
  }
}
