import 'package:flutter/material.dart';
///
mixin CartChangeNotifierDisposeMixin on ChangeNotifier {
  /// Whether this object has been disposed.
  bool disposed = false;

  @override
  void notifyListeners() {
    if (!disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
