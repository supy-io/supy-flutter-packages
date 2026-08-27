import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum Draft { header, notes }

/// A bloc-shaped state: immutable, republished on a stream.
class State {
  const State({required this.reference, required this.date, this.notes});

  final String reference;
  final DateTime date;
  final String? notes;
}

/// The smallest thing that behaves like a bloc.
class FakeBloc {
  FakeBloc(this._state);

  State _state;
  final StreamController<State> _controller =
      StreamController<State>.broadcast();

  State get state => _state;
  Stream<State> get stream => _controller.stream;

  void emit(State next) {
    _state = next;
    _controller.add(next);
  }

  Future<void> close() => _controller.close();
}

void main() {
  late FakeBloc bloc;

  setUp(() {
    bloc = FakeBloc(State(reference: 'REQ-1', date: DateTime(2026)));
    addTearDown(bloc.close);
  });

  ValueStreamDetector<FakeBloc, State, Draft> build() =>
      ValueStreamDetector<FakeBloc, State, Draft>(
        id: 'draft',
        read: (b) => b.state,
        streamOf: (b) => b.stream,
        facets: [
          Facet(
            kind: Draft.header,
            values: (s) => [s.reference, s.date],
          ),
          Facet(kind: Draft.notes, values: (s) => [s.notes]),
        ],
      );

  test('reports nothing while the state matches', () {
    final session = build().start(bloc);

    expect(session.diff(bloc), isEmpty);
  });

  test('reports one change per moved facet', () {
    final session = build().start(bloc);

    bloc.emit(State(reference: 'REQ-2', date: DateTime(2027), notes: 'hi'));

    expect(session.diff(bloc).map((c) => c.kind), [
      Draft.header,
      Draft.notes,
    ]);
  });

  test('collapses several fields in one facet into one change', () {
    final session = build().start(bloc);

    bloc.emit(State(reference: 'REQ-2', date: DateTime(2027)));

    expect(session.diff(bloc), hasLength(1));
  });

  test('exposes the bloc stream so a tracker can subscribe', () {
    expect(build().streams(bloc), hasLength(1));
  });

  test('drives a tracker end to end', () async {
    final tracker = ChangeTracker<FakeBloc, Draft>(
      sources: bloc,
      detectors: [build()],
    );
    addTearDown(tracker.dispose);

    expect(tracker.hasChanges, isFalse);

    bloc.emit(State(reference: 'REQ-2', date: DateTime(2026)));
    await Future<void>.delayed(Duration.zero);

    expect(tracker.changeCount, 1);
    expect(tracker.kinds, {Draft.header});
  });

  test('streamBaseline re-baselines the tracker when saved state moves',
      () async {
    final saved = FakeBloc(State(reference: 'REQ-1', date: DateTime(2026)));
    addTearDown(saved.close);

    final tracker = ChangeTracker<FakeBloc, Draft>(
      sources: bloc,
      detectors: [build()],
      baseline: streamBaseline<State>(
        read: () => saved.state,
        stream: saved.stream,
        revisionOf: (state) => state.reference,
      ),
    );
    addTearDown(tracker.dispose);

    bloc.emit(State(reference: 'REQ-2', date: DateTime(2026)));
    await Future<void>.delayed(Duration.zero);
    expect(tracker.hasChanges, isTrue);

    // The save lands: the server's copy now matches what the user typed.
    saved.emit(State(reference: 'REQ-2', date: DateTime(2026)));
    await Future<void>.delayed(Duration.zero);

    expect(tracker.hasChanges, isFalse);
  });
}
