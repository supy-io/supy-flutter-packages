import 'dart:async';

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
