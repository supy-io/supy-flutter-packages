import 'package:flutter/material.dart';

mixin ChangeNotifierDisposeMixin on ChangeNotifier {
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
