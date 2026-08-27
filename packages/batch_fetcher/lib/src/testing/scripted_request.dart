import 'dart:async';

import 'package:batch_fetcher/src/core/batch_fetcher.dart';
import 'package:batch_fetcher/src/core/batch_outcome.dart';

/// A [BatchRequest] that replays a script of outcomes, one per call.
///
/// Lets a test say "first call throws, second returns 0, third returns 12.5"
/// without a mock, and records exactly which ids each call was asked for — the
/// property a batching layer exists to control and the one a cache-only
/// assertion cannot see.
class ScriptedRequest<TId, TValue, TKey> {
  /// Creates a request that returns [steps] in order.
  ///
  /// Once the script runs out the last step repeats, so a test only scripts the
  /// calls it cares about.
  ScriptedRequest(this.steps)
      : assert(steps.isNotEmpty, 'a script needs at least one step');

  /// Creates a request that always resolves ids through [resolve].
  factory ScriptedRequest.always(TValue Function(TId id) resolve) =>
      ScriptedRequest<TId, TValue, TKey>([
        (ids, key) => BatchOutcome<TId, TValue>.resolved(<TId, TValue>{
              for (final id in ids) id: resolve(id),
            }),
      ]);

  /// Creates a request that always throws [error].
  factory ScriptedRequest.alwaysFailing(Object error) =>
      ScriptedRequest<TId, TValue, TKey>([
        // A test must be able to script a non-Error throw, because a real
        // request callback can produce one.
        // ignore: only_throw_errors
        (ids, key) => throw error,
      ]);

  /// The scripted steps, each producing an outcome or throwing.
  ///
  /// A step may return a `Future`, which is how a test holds a request open
  /// long enough to assert on in-flight behaviour.
  final List<
          FutureOr<BatchOutcome<TId, TValue>> Function(List<TId> ids, TKey key)>
      steps;

  /// The ids each call was asked for, in call order.
  final List<List<TId>> calls = [];

  /// The keys each call was made under, in call order.
  final List<TKey> keys = [];

  /// How many requests have been made.
  int get callCount => calls.length;

  /// The total number of ids across every call — equal to [callCount] times the
  /// batch size only if no de-duplication happened.
  int get idCount => calls.fold(0, (sum, ids) => sum + ids.length);

  /// The [BatchRequest] to hand to a fetcher.
  Future<BatchOutcome<TId, TValue>> call(List<TId> ids, TKey key) async {
    final index = calls.length;
    calls.add(List<TId>.unmodifiable(ids));
    keys.add(key);
    final step = steps[index < steps.length ? index : steps.length - 1];
    return step(ids, key);
  }
}
