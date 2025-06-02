import 'package:flexi_cart/src/mixins/mixins.dart';

/// mixin for change notifier dispose
mixin CartMetadataMixin on CartChangeNotifierDisposeMixin, CartHistoryMixin {
  /// Custom metadata storage.
  final Map<String, dynamic> _metadata = {};

  /// Returns a read-only view of the metadata.
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  /// Adds multiple metadata entries.
  /// If [shouldNotifyListeners] is true, notifies listeners after the update.
  void addMetadataEntries(
    Map<String, dynamic> entries, {
    bool shouldNotifyListeners = false,
  }) {
    if (entries.isEmpty) {
      return;
    }
    _metadata.addAll(entries);
    addHistory(
      'Metadata entries added: ${entries.keys.join(', ')}',
      notified: shouldNotifyListeners,
    );

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Sets a single metadata key-value pair.
  void setMetadataEntry(
    String key,
    dynamic value, {
    bool shouldNotifyListeners = true,
  }) {
    _metadata[key] = value;
    addHistory('Metadata set: $key = $value', notified: shouldNotifyListeners);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Retrieves a metadata value by key.
  /// Returns null if key is not found or type cast fails.
  S? getMetadataEntry<S>(String key) => _metadata[key] as S?;

  /// Removes a metadata entry by key.
  void removeMetadataEntry(String key, {bool shouldNotifyListeners = true}) {
    if (!_metadata.containsKey(key)) {
      return;
    }
    _metadata.remove(key);
    addHistory('Metadata removed: $key', notified: shouldNotifyListeners);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Sets a metadata key-value pair.
  /// Deprecated: Use [setMetadataEntry] instead.
  @Deprecated('Use setMetadataEntry instead')
  void setMetadata(
    String key,
    dynamic value, {
    bool shouldNotifyListeners = true,
  }) {
    setMetadataEntry(key, value, shouldNotifyListeners: shouldNotifyListeners);
  }

  /// get metadata value by key
  /// Deprecated: Use [getMetadataEntry] instead.
  @Deprecated('Use getMetadataEntry instead')
  S? getMetadata<S>(String key) => getMetadataEntry(key);

  /// Removes a metadata entry.
  @Deprecated('Use removeMetadataEntry instead')
  void removeMetadata(String key, {bool shouldNotifyListeners = true}) {
    removeMetadataEntry(key, shouldNotifyListeners: shouldNotifyListeners);
  }

  /// Clears all metadata entries.
  void clearAllMetadata({bool shouldNotifyListeners = false}) {
    if (_metadata.isNotEmpty) {
      _metadata.clear();
      addHistory('All metadata cleared', notified: shouldNotifyListeners);

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    }
  }
}
