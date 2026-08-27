import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

import 'helpers.dart';

void main() {
  late Sources sources;

  setUp(() => sources = Sources());

  ChangeTracker<Sources, Kind> build(
    List<ChangeDetector<Sources, Kind>> detectors, {
    BaselineSource<Object>? baseline,
    TrackerOptions options = const TrackerOptions(),
  }) =>
      ChangeTracker<Sources, Kind>(
        sources: sources,
        detectors: detectors,
        baseline: baseline,
        options: options,
      );

  group('baseline capture', () {
    test('captures immediately when there is no baseline source', () {
      final detector = Scripted('a');
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      expect(detector.startCount, 1);
      expect(tracker.isTracking, isTrue);
      expect(tracker.hasChanges, isFalse);
    });

    test('waits for the baseline source to produce saved state', () {
      final signal = Ticker();
      Doc? saved;
      final detector = Scripted('a');
      final tracker = build(
        [detector],
        baseline: BaselineSource<Object>(read: () => saved, signal: signal),
      );
      addTearDown(tracker.dispose);

      expect(tracker.isTracking, isFalse);
      expect(detector.startCount, 0);

      saved = Doc(title: 'saved');
      signal.tick();

      expect(tracker.isTracking, isTrue);
      expect(detector.startCount, 1);
    });

    test('does not re-baseline when the same revision is re-read', () {
      final signal = Ticker();
      final saved = Doc(title: 'saved');
      final detector = Scripted('a');
      final tracker = build(
        [detector],
        baseline: BaselineSource<Object>(read: () => saved, signal: signal),
      );
      addTearDown(tracker.dispose);

      expect(detector.startCount, 1);

      signal
        ..tick()
        ..tick();

      expect(
        detector.startCount,
        1,
        reason: 'a rebuild must not discard in-progress edits',
      );
    });

    test('re-baselines when a new revision arrives', () {
      final signal = Ticker();
      var saved = Doc(title: 'saved');
      final detector = Scripted('a');
      final tracker = build(
        [detector],
        baseline: BaselineSource<Object>(read: () => saved, signal: signal),
      );
      addTearDown(tracker.dispose);

      saved = Doc(title: 'saved again');
      signal.tick();

      expect(detector.startCount, 2);
    });

    test('revisionOf lets equal-but-not-identical state share a baseline', () {
      final signal = Ticker();
      var saved = Doc(title: 'saved');
      final detector = Scripted('a');
      final tracker = build(
        [detector],
        baseline: BaselineSource<Object>(
          read: () => saved,
          signal: signal,
          revisionOf: (value) => (value as Doc).revision,
        ),
      );
      addTearDown(tracker.dispose);

      saved = Doc(title: 'rebuilt, same revision');
      signal.tick();
      expect(detector.startCount, 1);

      saved = Doc(title: 'saved', revision: 2);
      signal.tick();
      expect(detector.startCount, 2);
    });

    test('captureBaseline(detectorId:) re-baselines only that detector',
        () async {
      final ticker = Ticker();
      final a = Scripted(
        'a',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title, subject: 'a')],
      );
      final b = Scripted(
        'b',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title, subject: 'b')],
      );
      final tracker = build([a, b]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();
      expect(tracker.changeCount, 2);

      a.changes = const [];
      tracker.captureBaseline(detectorId: 'a');
      await settle();

      expect(tracker.changeCount, 1);
      expect(tracker.changes.changes.single.subject, 'b');
    });

    test('rejects an unknown detectorId', () {
      final tracker = build([Scripted('a')]);
      addTearDown(tracker.dispose);

      expect(
        () => tracker.captureBaseline(detectorId: 'nope'),
        throwsArgumentError,
      );
    });

    test('asserts detector ids are unique', () {
      expect(
        () => build([Scripted('a'), Scripted('a')]),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('subscriptions', () {
    test('subscribes to a listenable shared by two detectors only once',
        () async {
      final ticker = Ticker();
      final a = Scripted('a', listenable: ticker);
      final b = Scripted('b', listenable: ticker);
      final tracker = build([a, b]);
      addTearDown(tracker.dispose);

      expect(
        ticker.isSubscribed,
        isTrue,
        reason: 'the shared listenable must be wired',
      );

      ticker.tick();
      await settle();

      expect(a.diffCount, 1);
      expect(b.diffCount, 1);
    });

    test('coalesces a burst of notifications into one diff', () async {
      final ticker = Ticker();
      final detector = Scripted('a', listenable: ticker);
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      for (var i = 0; i < 20; i++) {
        ticker.tick();
      }
      await settle();

      expect(detector.diffCount, 1);
    });

    test('recomputes from a stream event', () async {
      final controller = StreamController<Object?>.broadcast();
      addTearDown(controller.close);
      final detector = Scripted('a', stream: controller.stream);
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      controller.add('typed');
      await settle();

      expect(detector.diffCount, 1);
    });

    test('releases every subscription on dispose', () async {
      final ticker = Ticker();
      final detector = Scripted('a', listenable: ticker);
      build([detector]).dispose();

      expect(ticker.isSubscribed, isFalse);

      ticker.tick();
      await settle();
      expect(detector.diffCount, 0);
    });
  });

  group('publishing', () {
    test('does not notify when the change list is unchanged', () async {
      final ticker = Ticker();
      final detector = Scripted(
        'a',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title, subject: 'Tomatoes')],
      );
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      var notifications = 0;
      tracker.addListener(() => notifications++);

      ticker.tick();
      await settle();
      expect(notifications, 1);

      ticker.tick();
      await settle();
      expect(
        notifications,
        1,
        reason: 'same changes must not churn listeners',
      );
    });

    test('notifies when the change list actually changes', () async {
      final ticker = Ticker();
      final detector = Scripted('a', listenable: ticker);
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      var notifications = 0;
      tracker.addListener(() => notifications++);

      detector.changes = const [TrackedChange(Kind.title)];
      ticker.tick();
      await settle();
      expect(notifications, 1);

      detector.changes = const [];
      ticker.tick();
      await settle();
      expect(notifications, 2);
      expect(tracker.hasChanges, isFalse);
    });

    test('tags each change with the detector that produced it', () async {
      final ticker = Ticker();
      final detector = Scripted(
        'documents',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title)],
      );
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      expect(tracker.changes.changes.single.detectorId, 'documents');
    });

    test('detectorId does not affect equality, so tagging never churns', () {
      const a = TrackedChange(Kind.title, subject: 'x');
      final b = a.taggedWith('items');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('fallback role', () {
    test('fallback changes are dropped when a describing detector fired',
        () async {
      final ticker = Ticker();
      final named = Scripted(
        'named',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title)],
      );
      final digest = Scripted(
        'digest',
        listenable: ticker,
        role: DetectorRole.fallback,
        changes: const [TrackedChange(Kind.other)],
      );
      final tracker = build([named, digest]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      expect(tracker.changeCount, 1);
      expect(tracker.kinds, {Kind.title});
    });

    test('fallback changes surface when nothing else fired', () async {
      final ticker = Ticker();
      final named = Scripted('named', listenable: ticker);
      final digest = Scripted(
        'digest',
        listenable: ticker,
        role: DetectorRole.fallback,
        changes: const [TrackedChange(Kind.other)],
      );
      final tracker = build([named, digest]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      expect(tracker.changeCount, 1);
      expect(tracker.kinds, {Kind.other});
    });
  });

  group('degradation', () {
    test('a detector that throws on start is skipped, others keep working',
        () async {
      final ticker = Ticker();
      final broken = Scripted(
        'broken',
        listenable: ticker,
        throwOnStart: true,
      );
      final healthy = Scripted(
        'healthy',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title)],
      );
      final observer = RecordingObserver();
      final tracker = build(
        [broken, healthy],
        options: TrackerOptions(observer: observer),
      );
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      expect(tracker.degradedDetectors, {'broken'});
      expect(observer.failures, ['broken']);
      expect(tracker.changeCount, 1);
    });

    test('a detector that throws on diff is dropped, others keep working',
        () async {
      final ticker = Ticker();
      final broken = Scripted(
        'broken',
        listenable: ticker,
        throwOnDiff: true,
      );
      final healthy = Scripted(
        'healthy',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title)],
      );
      final tracker = build([broken, healthy]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      expect(tracker.degradedDetectors, {'broken'});
      expect(tracker.changeCount, 1);
    });
  });

  group('observer', () {
    test('reports baseline captures and published changes', () async {
      final ticker = Ticker();
      final detector = Scripted('a', listenable: ticker);
      final observer = RecordingObserver();
      final tracker = build(
        [detector],
        options: TrackerOptions(observer: observer),
      );
      addTearDown(tracker.dispose);

      expect(observer.baselines, [
        ['a'],
      ]);

      detector.changes = const [TrackedChange(Kind.title)];
      ticker.tick();
      await settle();

      expect(observer.published.last, hasLength(1));
    });
  });

  group('describe', () {
    test('names each detector, its role, and what it reported', () async {
      final ticker = Ticker();
      final detector = Scripted(
        'documents',
        listenable: ticker,
        changes: const [TrackedChange(Kind.title, subject: 'Invoice no.')],
      );
      final tracker = build([detector]);
      addTearDown(tracker.dispose);

      ticker.tick();
      await settle();

      final described = tracker.describe();
      expect(described, contains('documents'));
      expect(described, contains('describing'));
      expect(described, contains('Invoice no.'));
    });
  });
}
