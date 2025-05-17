import 'dart:async';
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

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// A mixin that provides a reactive stream interface for emitting
/// state changes or values of type [T].
///
/// It uses a [StreamController.broadcast] so that multiple listeners
/// can subscribe to the stream. This is useful for reactive programming
/// or plugin/event-based systems.
mixin CartStreamMixin<T> {
  /// Internal stream controller for broadcasting changes.
  final _controller = StreamController<T>.broadcast();

  /// A stream of events or state updates of type [T].
  ///
  /// Consumers can listen to this stream to react to changes.
  Stream<T> get stream => _controller.stream;

  /// Emits a new value to the stream.
  ///
  /// This sends the value to all current listeners, unless the stream
  /// has been closed.
  void emit(T value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  /// Closes the internal stream controller.
  ///
  /// Call this during disposal to clean up resources.
  void disposeStream() {
    _controller.close();
  }
}
