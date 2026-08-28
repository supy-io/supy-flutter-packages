import 'package:batch_fetcher/batch_fetcher_testing.dart';
import 'package:batch_fetcher_flutter/batch_fetcher_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _debounce = Duration(milliseconds: 61);

void main() {
  group('BatchFetchNotifier', () {
    test('notifies when an entry changes', () async {
      final clock = FakeClock();
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => BatchOutcome.resolved(<String, int>{
          for (final id in ids) id: id.length,
        }),
        clock: clock,
      );
      addTearDown(notifier.dispose);

      var notifications = 0;
      notifier.addListener(() => notifications++);

      final future = notifier.fetch(
        BatchScope(key: BatchKey.none, ids: const ['abc']),
      );
      await clock.advance(_debounce);
      await future;

      expect(notifications, 2, reason: 'loading, then resolved');
      expect(notifier.entryOf('abc'), const FetchPresent<int>(3));
    });

    test('forwards the read surface', () async {
      final clock = FakeClock();
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => BatchOutcome.resolved(<String, int>{
          for (final id in ids) id: id.length,
        }),
        clock: clock,
      );
      addTearDown(notifier.dispose);

      expect(notifier.isBusy, isFalse);
      final future = notifier.fetch(
        BatchScope(key: BatchKey.none, ids: const ['abc']),
      );
      expect(notifier.isBusy, isTrue);

      await clock.advance(_debounce);
      await future;

      expect(notifier.values, {'abc': 3});
      expect(notifier.loadingIds, isEmpty);
    });

    test('refresh, invalidate and trim reach the fetcher', () async {
      final clock = FakeClock();
      final script = ScriptedRequest<String, int, BatchKey>.always(
        (id) => id.length,
      );
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: script.call,
        clock: clock,
      );
      addTearDown(notifier.dispose);

      await _settle(notifier, clock, const ['abc']);
      expect(script.callCount, 1);

      notifier.invalidate(ids: const ['abc']);
      expect(notifier.entryOf('abc'), const FetchIdle<int>());

      await _settle(notifier, clock, const ['abc']);
      final refresh = notifier.refresh(const ['abc']);
      await clock.advance(_debounce);
      await refresh;
      expect(script.callCount, 3);

      notifier.trim(const <String>[]);
      expect(notifier.values, isEmpty);
    });

    test('disposes the fetcher it created', () async {
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => const BatchOutcome.resolved({}),
      );
      final fetcher = notifier.fetcher;

      notifier.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(fetcher.isDisposed, isTrue);
    });

    test('leaves a borrowed fetcher alone', () async {
      final fetcher = BatchFetcher<String, int, BatchKey>(
        request: (ids, key) async => const BatchOutcome.resolved({}),
      );
      addTearDown(fetcher.dispose);

      BatchFetchNotifier<String, int, BatchKey>.wrapping(
        fetcher,
        owns: false,
      ).dispose();
      await Future<void>.delayed(Duration.zero);

      expect(fetcher.isDisposed, isFalse);
    });
  });

  group('BatchFetchBuilder', () {
    testWidgets('rebuilds only for the id it renders', (tester) async {
      final clock = FakeClock();
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => BatchOutcome.resolved(<String, int>{
          for (final id in ids) id: id.length,
        }),
        clock: clock,
      );
      addTearDown(notifier.dispose);

      final builds = <String, int>{'a': 0, 'bb': 0};
      await tester.pumpWidget(
        _Host(
          notifier: notifier,
          ids: const ['a', 'bb'],
          onBuild: (id) => builds[id] = builds[id]! + 1,
        ),
      );
      expect(builds, {'a': 1, 'bb': 1});

      // Resolve only 'a'. 'bb' must not rebuild.
      final future = notifier.fetch(
        BatchScope(key: BatchKey.none, ids: const ['a']),
      );
      await clock.advance(_debounce);
      await future;
      await tester.pump();

      expect(builds['a'], greaterThan(1));
      expect(builds['bb'], 1, reason: 'an unrelated id resolving is not news');
      expect(find.text('a=1'), findsOneWidget);
      expect(find.text('bb=idle'), findsOneWidget);
    });

    testWidgets('renders each of the five states', (tester) async {
      final clock = FakeClock();
      final script = ScriptedRequest<String, int, BatchKey>([
        (ids, key) => const BatchOutcome<String, int>(absent: {'gone'}),
        (ids, key) => throw Exception('boom'),
      ]);
      final notifier = BatchFetchNotifier<String, int, BatchKey>(
        request: script.call,
        clock: clock,
        retry: const NoRetry(),
      );
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        _Host(notifier: notifier, ids: const ['gone', 'bad', 'never']),
      );
      expect(find.text('gone=idle'), findsOneWidget);

      final absent = notifier.fetch(
        BatchScope(key: BatchKey.none, ids: const ['gone']),
      );
      await clock.advance(_debounce);
      await absent;
      await tester.pump();
      expect(find.text('gone=absent'), findsOneWidget);

      final failed = notifier.fetch(
        BatchScope(key: BatchKey.none, ids: const ['bad']),
      );
      await clock.advance(_debounce);
      await failed;
      await tester.pump();
      expect(find.text('bad=failed'), findsOneWidget);
      expect(find.text('never=idle'), findsOneWidget);
    });

    testWidgets('follows a changed id or source', (tester) async {
      final clock = FakeClock();
      final first = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => const BatchOutcome.resolved({'a': 7}),
        clock: clock,
      );
      final second = BatchFetchNotifier<String, int, BatchKey>(
        request: (ids, key) async => const BatchOutcome.resolved({'a': 9}),
        clock: clock,
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await _settle(first, clock, const ['a']);
      await _settle(second, clock, const ['a']);
      await _settle(first, clock, const ['b']);

      await tester.pumpWidget(_Host(notifier: first, ids: const ['a']));
      expect(find.text('a=7'), findsOneWidget);

      // Same widget position, different id.
      await tester.pumpWidget(_Host(notifier: first, ids: const ['b']));
      expect(find.text('b=absent'), findsOneWidget);

      // Same id, different source.
      await tester.pumpWidget(_Host(notifier: second, ids: const ['a']));
      expect(find.text('a=9'), findsOneWidget);
    });
  });
}

Future<void> _settle(
  BatchFetchNotifier<String, int, BatchKey> notifier,
  FakeClock clock,
  List<String> ids,
) async {
  final future = notifier.fetch(BatchScope(key: BatchKey.none, ids: ids));
  await clock.advance(_debounce);
  await future;
}

class _Host extends StatelessWidget {
  const _Host({required this.notifier, required this.ids, this.onBuild});

  final BatchFetchNotifier<String, int, BatchKey> notifier;
  final List<String> ids;
  final void Function(String id)? onBuild;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Column(
          children: [
            for (final id in ids)
              BatchFetchBuilder<String, int>(
                source: notifier,
                id: id,
                builder: (context, entry) {
                  onBuild?.call(id);
                  return Text('$id=${_label(entry)}');
                },
              ),
          ],
        ),
      );

  static String _label(FetchEntry<int> entry) => switch (entry) {
        FetchIdle<int>() => 'idle',
        FetchLoading<int>() => 'loading',
        FetchPresent<int>(:final value) => '$value',
        FetchAbsent<int>() => 'absent',
        FetchFailed<int>() => 'failed',
      };
}
