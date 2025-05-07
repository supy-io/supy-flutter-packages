/// Interface defining a generic map representation.
abstract interface class IMap<V> {
  ///
  Map<String, V> toMap({bool encode = true});
}
