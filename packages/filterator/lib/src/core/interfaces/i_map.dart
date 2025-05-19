/// Interface defining a generic map representation.
abstract interface class IMap<V> {
  /// Converts the object to a map representation.
  Map<String, V> toMap();
}
