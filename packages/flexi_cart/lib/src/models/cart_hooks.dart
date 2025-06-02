import 'package:flexi_cart/flexi_cart.dart';

/// Hooks for cart operations, allowing for custom actions on add, delete,
/// and checkout.
class CartHooks {
  /// Creates a [CartHooks] instance with the provided callbacks.
  CartHooks({
     this.onDisposed,
     this.onItemAdded,
     this.onItemDeleted,
  });

  /// Creates a [CartHooks] instance with no callbacks.
  /// Useful for default behavior.
  final void Function()? onDisposed;

  /// Callback for when an item is added to the cart.
  final void Function(ICartItem item)? onItemAdded;

  /// Callback for when an item is deleted from the cart.
  final void Function(ICartItem item)? onItemDeleted;
}
