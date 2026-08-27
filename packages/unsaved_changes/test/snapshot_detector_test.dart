import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

import 'helpers.dart';

/// The shape almost every real detector takes: capture extracted values, then
/// compare them.
class TitleDetector extends SnapshotChangeDetector<String, Sources, Kind> {
  const TitleDetector();

  @override
  String get id => 'title';

  @override
  String capture(Sources sources) => sources.title;

  @override
  Iterable<TrackedChange<Kind>> compare(String baseline, Sources sources) => [
        if (sources.title != baseline)
          TrackedChange(Kind.title, subject: sources.title),
      ];

  @override
  Iterable<Listenable> listenables(Sources sources) => [sources.ticker];
}

void main() {
  late Sources sources;

  setUp(() => sources = Sources());

  ChangeTracker<Sources, Kind> build({TrackerOptions? options}) =>
      ChangeTracker<Sources, Kind>(
        sources: sources,
        detectors: const [TitleDetector()],
        options: options ?? const TrackerOptions(),
      );

  test('reports nothing while the value matches the baseline', () async {
    final tracker = build();
    addTearDown(tracker.dispose);

    sources.ticker.tick();
    await settle();

    expect(tracker.hasChanges, isFalse);
  });

  test('reports a change once the value moves', () async {
    final tracker = build();
    addTearDown(tracker.dispose);

    sources.title = 'edited';
    sources.ticker.tick();
    await settle();

    expect(tracker.changeCount, 1);
    expect(tracker.changes.changes.single.subject, 'edited');
  });

  test('stops reporting when the value is edited back', () async {
    final tracker = build();
    addTearDown(tracker.dispose);

    sources.title = 'edited';
    sources.ticker.tick();
    await settle();
    expect(tracker.hasChanges, isTrue);

    sources.title = 'draft';
    sources.ticker.tick();
    await settle();
    expect(tracker.hasChanges, isFalse);
  });

  test('re-baselining adopts the edited value as the new truth', () async {
    final tracker = build();
    addTearDown(tracker.dispose);

    sources.title = 'saved';
    sources.ticker.tick();
    await settle();
    expect(tracker.hasChanges, isTrue);

    tracker.captureBaseline();
    expect(tracker.hasChanges, isFalse);
  });

  test('debounce collapses a burst into a single publish', () {
    fakeAsync((async) {
      final tracker = build(
        options: const TrackerOptions(debounce: Duration(milliseconds: 300)),
      );

      var notifications = 0;
      tracker.addListener(() => notifications++);

      sources.title = 'e';
      sources.ticker.tick();
      async.elapse(const Duration(milliseconds: 100));
      sources.title = 'ed';
      sources.ticker.tick();
      async.elapse(const Duration(milliseconds: 100));
      sources.title = 'edited';
      sources.ticker.tick();

      expect(notifications, 0, reason: 'still inside the debounce window');

      async.elapse(const Duration(milliseconds: 300));

      expect(notifications, 1);
      expect(tracker.changes.changes.single.subject, 'edited');

      tracker.dispose();
    });
  });
}
