import 'dart:async';

import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:batch_fetcher/batch_fetcher_testing.dart';

/// The default debounce, plus a hair, so one advance always opens the window.
const debounceWindow = Duration(milliseconds: 61);

/// A fetcher plus everything a test needs to drive and inspect it.
typedef Harness = ({
  BatchFetcher<String, int, BatchKey> fetcher,
  ScriptedRequest<String, int, BatchKey> script,
  FakeClock clock,
  RecordingObserver<String> observer,
});

/// A fetcher over `String` ids and `int` values, wired to a fake clock.
///
/// Defaults to [NoRetry] so a test that is not about retrying does not have to
/// think about backoff windows.
Harness harness({
  List<Step>? steps,
  BatchFetcherConfig config = const BatchFetcherConfig(),
  RetryPolicy retry = const NoRetry(),
  SettlePolicy<int>? settle,
}) {
  final clock = FakeClock();
  final observer = RecordingObserver<String>();
  final script = steps == null
      ? ScriptedRequest<String, int, BatchKey>.always((id) => id.length)
      : ScriptedRequest<String, int, BatchKey>(steps);
  final fetcher = BatchFetcher<String, int, BatchKey>(
    request: script.call,
    config: config,
    retry: retry,
    settle: settle,
    clock: clock,
    observer: observer,
  );
  return (fetcher: fetcher, script: script, clock: clock, observer: observer);
}

/// One scripted request step.
typedef Step = FutureOr<BatchOutcome<String, int>> Function(
  List<String> ids,
  BatchKey key,
);

/// Shorthand for an outcome step that resolves every requested id.
BatchOutcome<String, int> resolveAll(List<String> ids, BatchKey key) =>
    BatchOutcome<String, int>.resolved(<String, int>{
      for (final id in ids) id: id.length,
    });

/// Shorthand for a step that resolves every requested id to [value].
Step resolveTo(int value) =>
    (ids, key) => BatchOutcome<String, int>.resolved(<String, int>{
          for (final id in ids) id: value,
        });

/// Shorthand for a step that throws [error].
Step throwing(Exception error) => (ids, key) => throw error;

/// A step that never completes until [gate] is completed by the test.
Step gated(Completer<BatchOutcome<String, int>> gate) =>
    (ids, key) => gate.future;

/// The error the failing steps throw, so assertions can name it.
final boom = Exception('boom');
