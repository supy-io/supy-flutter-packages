/// mixin CartHistoryMixin;
/// // A mixin that provides a history of actions or messages related to the cart.
mixin CartHistoryMixin {
  final List<String> _history = [];

  /// Returns the list of registered plugins.
  List<String> get history => List.unmodifiable(_history);

  /// gets the number of history entries.
  bool get hasHistory => _history.isNotEmpty;

  /// Adds a message to the history.
  void addHistory(String message, {bool notified = false}) {
    _history.add('$message - {notified: $notified}');
  }

  /// Removes the last entry from the history.
  void clearHistory() {
    _history.clear();
  }
}
