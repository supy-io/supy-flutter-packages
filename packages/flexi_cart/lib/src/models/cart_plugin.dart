import 'package:flexi_cart/flexi_cart.dart';

/// Interface for plugins that want to be notified when the cart changes.
abstract class ICartPlugin<T extends ICartItem> {
  /// Called whenever a [onChange] occurs in any [cart]
  /// A [onChange] occurs when a new value is emitted.
  /// [onChange] is called before a cart's state has been updated.
  void onChange(FlexiCart<T> cart) {}

  /// Called whenever an [error] is thrown in the cart.
  /// The [stackTrace] argument may be [StackTrace.empty] if an error
  /// was received without a stack trace.
  void onError(FlexiCart<T> cart, Object error, StackTrace stackTrace) {}

  /// Called whenever a [cart] is closed.
  /// [onClose] is called just before the [cart] is closed
  /// and indicates that the particular instance will no longer
  /// emit new states.
  void onClose(FlexiCart<T> cart) {}
}
