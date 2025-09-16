/// Optional: an abstraction over
/// storage so users can provide their own provider
abstract class CartCacheProvider {
  /// Writes a key-value pair to the cache.
  Future<void> write(String key, String value);

  /// Reads a value from the cache by key.
  /// Returns null if the key does not exist.
  Future<String?> read(String key);

  /// Deletes a key-value pair from the cache by key.
  Future<void> delete(String key);
}
