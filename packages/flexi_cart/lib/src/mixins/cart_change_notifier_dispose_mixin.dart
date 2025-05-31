import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';

/// A mixin that adds a `disposed` flag to [ChangeNotifier], and ensures
/// `notifyListeners()` only works when the object hasn't been disposed.
///
/// Useful for preventing calls to `notifyListeners()` after the object
/// has already been disposed, which can cause runtime exceptions.
mixin CartChangeNotifierDisposeMixin on ChangeNotifier {
  /// Indicates whether this object has already been disposed.
  bool disposed = false;

  @override
  void notifyListeners() {
    if (!disposed) {
      super.notifyListeners();
    }
  }

  /// Checks if the object has been disposed before performing an action.
  void checkIfDisposed(ValueChanged<Exception> beforeThrow) {
    if (disposed) {
      final exception =
          CartDisposedException('Cannot perform action after dispose');
      beforeThrow(exception);
      throw exception;
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
