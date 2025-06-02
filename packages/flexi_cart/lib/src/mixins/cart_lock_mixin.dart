import 'package:flexi_cart/src/mixins/mixins.dart';

/// A mixin that provides lock/unlock functionality to a cart.
///
/// This mixin adds a boolean lock state to a class and notifies listeners
/// if specified. Useful for preventing modifications to a cart during
/// critical operations.
mixin CartLockMixin on CartChangeNotifierDisposeMixin, CartHistoryMixin {
  /// Indicates whether the cart is currently locked.
  bool _isLocked = false;

  /// Returns whether the cart is locked.
  bool get isLocked => _isLocked;

  /// Sets the lock state of the cart directly.
  ///
  /// Note: This does **not** trigger [notifyListeners].
  set isLocked(bool value) {
    _isLocked = value;
  }

  /// Locks the cart.
  ///
  /// If [shouldNotifyListeners] is true, notifies listeners after locking.
  void lock({bool shouldNotifyListeners = false}) {
    if (_isLocked) {
      return;
    }

    _isLocked = true;
    addHistory('Cart locked', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Unlocks the cart.
  ///
  /// If [shouldNotifyListeners] is true, notifies listeners after unlocking.
  void unlock({bool shouldNotifyListeners = false}) {
    if (!_isLocked) {
      return;
    }

    _isLocked = false;
    addHistory('Cart unlocked', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Toggles the current lock state.
  ///
  /// If locked, it will unlock; if unlocked, it will lock.
  /// Notifies listeners if [shouldNotifyListeners] is true.
  void toggleLock({bool shouldNotifyListeners = false}) {
    _isLocked = !_isLocked;
    final action = _isLocked ? 'locked' : 'unlocked';
    addHistory('Cart $action', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Resets the lock to an unlocked state.
  ///
  /// This is equivalent to calling [unlock], but does not check the current
  /// state.
  /// Notifies listeners if [shouldNotifyListeners] is true.
  void resetLock({bool shouldNotifyListeners = false}) {
    _isLocked = false;
    addHistory('Cart lock reset', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
