part of 'cart_options.dart';

/// Behavior overrides for internal cart logic.
class BehaviorOptions {
  /// Controls how the cart behaves internally, including logging,
  /// item filtering, and price resolution.
  BehaviorOptions({
    this.enableLogging = false,
    this.logger,
    this.itemFilter,
    this.priceResolver,
  });

  /// Enable or disable debug logging.
  bool enableLogging;

  /// Function to log custom messages when logging is enabled.
  void Function(String message)? logger;

  /// Optional function to determine whether an item should be added.
  bool Function(ICartItem item)? itemFilter;

  /// Optional function to override price for a specific item.
  double Function(ICartItem item)? priceResolver;

  /// Logs a message if logging is enabled.
  void log(String message) {
    if (enableLogging) {
      logger?.call(message);
    }
  }

  /// Checks whether an item can be added based on filters and hooks.
  bool canAdd(ICartItem item) {
    if (itemFilter != null && !itemFilter!(item)) {
      return false;
    }
    return true;
  }

  /// Resolves the item's price based on [priceResolver] or
  /// defaults to the item's own price.
  double resolvePrice(ICartItem item) {
    return priceResolver?.call(item) ?? item.price;
  }
}
