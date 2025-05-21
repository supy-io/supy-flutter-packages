/// Exception thrown when an operation is attempted on a locked cart.
///
/// This can be used to indicate that the cart is currently not available
/// for modification due to some locking mechanism (e.g., being processed
/// in checkout or awaiting a network response).
class CartLockedException implements Exception {
  /// Creates a [CartLockedException] with an optional error [message].
  CartLockedException([this.message = 'Cart is locked.']);

  /// Description of the error.
  ///
  /// Defaults to `'Cart is locked.'` if no message is provided.
  final String message;
}

/// Exception thrown when an operation is attempted on a disposed cart.
///
/// This typically means the cart has been explicitly removed or destroyed,
/// and can no longer be interacted with.
class CartDisposedException implements Exception {
  /// Creates a [CartDisposedException] with an optional error [message].
  CartDisposedException([this.message = 'Cart has been disposed.']);

  /// Description of the error.
  ///
  /// Defaults to `'Cart has been disposed.'` if no message is provided.
  final String message;
}
