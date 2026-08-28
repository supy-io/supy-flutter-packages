// An example is a script: printing is how it shows its work.
// ignore_for_file: avoid_print

import 'package:batch_fetcher/batch_fetcher.dart';

/// A list of 120 inventory events is on screen. Each row shows a cost that only
/// the server can compute, and the endpoint takes at most 50 ids per call.
///
/// Run with: dart run example/main.dart
Future<void> main() async {
  final api = _FakeCostsApi();

  final fetcher = BatchFetcher<String, double, BatchKey>(
    // The only thing the fetcher needs to know about your domain.
    request: (ids, key) async => BatchOutcome.resolved(
      await api.costs(ids, locationId: key.toString()),
    ),
    // A cost of 0 means the server is still aggregating; give it two more
    // looks, three seconds apart, then believe it.
    settle: const SettleWhen<double>(_isPriced, maxAttempts: 2),
    observer: _PrintObserver(),
  );

  final visibleIds = [for (var i = 0; i < 120; i++) 'event_$i'];
  final scope = BatchScope<String, BatchKey>(
    key: BatchKey(const ['loc_dubai_marina']),
    ids: visibleIds,
  );

  // Safe to call on every rebuild: cached, in-flight and backing-off ids are
  // all skipped.
  await fetcher.fetch(scope);
  await fetcher.fetch(scope);

  print('\nrequests sent: ${api.callCount} for ${visibleIds.length} ids');
  print('event_0  -> ${fetcher.entryOf('event_0')}');
  print('event_7  -> ${fetcher.entryOf('event_7')}');
  print('resolved -> ${fetcher.values.length}');

  await fetcher.dispose();
}

bool _isPriced(double cost) => cost != 0;

class _PrintObserver extends BatchFetcherObserver<String> {
  @override
  void onBatchStart(Object? key, List<String> ids) =>
      print('-> request for ${ids.length} ids under $key');

  @override
  void onRetryScheduled(String id, int attempt, Duration delay) =>
      print('   retry $id (attempt $attempt) in ${delay.inMilliseconds}ms');
}

/// Fails id 7 once, then resolves everything.
class _FakeCostsApi {
  int callCount = 0;

  Future<Map<String, double>> costs(
    List<String> ids, {
    required String locationId,
  }) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (callCount == 1 && ids.contains('event_7')) {
      throw StateError('transient upstream failure');
    }
    return <String, double>{
      for (final id in ids) id: 10.0 + ids.indexOf(id),
    };
  }
}
