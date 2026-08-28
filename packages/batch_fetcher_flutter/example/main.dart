import 'package:batch_fetcher_flutter/batch_fetcher_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _App());

/// 120 rows, each showing a cost the server computes, fetched 50 ids at a time.
class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late final BatchFetchNotifier<String, double, BatchKey> _costs;
  final List<String> _ids = [for (var i = 0; i < 120; i++) 'event_$i'];

  @override
  void initState() {
    super.initState();
    _costs = BatchFetchNotifier<String, double, BatchKey>(
      request: _fetchCosts,
      settle: const SettleWhen<double>(_isPriced, maxAttempts: 2),
    );
  }

  @override
  void dispose() {
    _costs.dispose();
    super.dispose();
  }

  Future<BatchOutcome<String, double>> _fetchCosts(
    List<String> ids,
    BatchKey key,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return BatchOutcome.resolved(<String, double>{
      for (final id in ids) id: id.hashCode.abs() % 5000 / 100,
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Event costs')),
          body: ListView.builder(
            itemCount: _ids.length,
            itemBuilder: (context, index) {
              final id = _ids[index];

              // Asking on every build is the intended usage: cached, in-flight
              // and backing-off ids are all skipped.
              _costs.fetch(
                BatchScope(key: BatchKey.none, ids: _visibleFrom(index)),
              );

              return ListTile(
                title: Text(id),
                trailing: BatchFetchBuilder<String, double>(
                  source: _costs,
                  id: id,
                  builder: (context, entry) => switch (entry) {
                    FetchPresent<double>(:final value) =>
                      Text(value.toStringAsFixed(2)),
                    FetchLoading<double>() => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    FetchFailed<double>() => const Icon(Icons.refresh),
                    FetchAbsent<double>() ||
                    FetchIdle<double>() =>
                      const Text('—'),
                  },
                ),
              );
            },
          ),
        ),
      );

  /// The rough screenful around [index], which is what a real list would pass.
  List<String> _visibleFrom(int index) =>
      _ids.sublist(index, (index + 20).clamp(0, _ids.length));
}

bool _isPriced(double cost) => cost != 0;
