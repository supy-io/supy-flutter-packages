import 'package:flexi_cart/flexi_cart.dart';

/// Mixin for managing cart plugins that respond to cart events.
mixin CartPluginsMixin<T extends ICartItem> {
  /// Registered plugins for cart event hooks.
  final List<ICartPlugin<T>> _plugins = [];

  /// Returns the list of registered plugins.
  List<ICartPlugin<T>> get plugins => List.unmodifiable(_plugins);

  /// Returns whether there are any registered plugins.
  bool get hasPlugins => _plugins.isNotEmpty;

  /// Registers a plugin to be notified on cart changes.
  void registerPlugin(ICartPlugin<T> plugin) {
    _plugins.add(plugin);
    // addHistory('Plugin registered: ${plugin.runtimeType}');
  }

  /// Unregisters a plugin so it no longer receives updates.
  void unregisterPlugin(ICartPlugin<T> plugin) {
    _plugins.remove(plugin);
    // addHistory('Plugin unregistered: ${plugin.runtimeType}');
  }

  /// Unregisters all plugins.
  void clearPlugins() {
    _plugins.clear();
  }
}
