import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/baseline_source.dart';

/// Adapts a [Stream] to a [Listenable], so stream-based state (a bloc) can
/// drive anything that expects a listenable.
///
/// Whoever creates one owns it. [streamBaseline] hands ownership to the
/// tracker, which disposes it along with itself.
class StreamSignal extends ChangeNotifier {
  /// Subscribes to [stream] and notifies on every event.
  StreamSignal(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// Builds a [BaselineSource] from stream-based state — a bloc, a
/// `ValueStream`, anything that republishes the saved copy.
///
/// The signal this creates is disposed with the tracker that consumes it.
BaselineSource<T> streamBaseline<T extends Object>({
  required T? Function() read,
  required Stream<Object?> stream,
  Object? Function(T value)? revisionOf,
}) {
  final signal = StreamSignal(stream);

  return BaselineSource<T>(
    read: read,
    signal: signal,
    revisionOf: revisionOf,
    onDispose: signal.dispose,
  );
}
