import 'package:collection/collection.dart';

const DeepCollectionEquality _deep = DeepCollectionEquality();

/// Compares two captured values, descending into lists, maps, and sets.
bool defaultEquals(Object? a, Object? b) => _deep.equals(a, b);

/// Treats `null` and the empty string as the same value.
///
/// A text field cleared back to empty usually reads as `''` where the saved
/// state held `null`; without this, clearing a field you never filled in is
/// reported as an edit.
bool nullableStringEquals(Object? a, Object? b) => (a ?? '') == (b ?? '');
