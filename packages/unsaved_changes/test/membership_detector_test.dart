import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum Staging { resolved, unresolved }

class Staged {
  Staged(this.keys, this.names);

  Set<String> keys;
  final Map<String, String> names;
}

void main() {
  late Staged staged;

  setUp(
    () => staged = Staged({
      'a'
    }, {
      'a': 'Tomatoes',
      'b': 'Onions',
      'c': 'Garlic',
    }),
  );

  MembershipDetector<Staged, Staging> build({
    MembershipDelta emitOn = MembershipDelta.added,
  }) =>
      MembershipDetector<Staged, Staging>(
        id: 'unresolved',
        kind: Staging.resolved,
        removedKind: Staging.unresolved,
        keysOf: (s) => s.keys,
        subjectOf: (s, key) => s.names[key],
        emitOn: emitOn,
      );

  test('reports nothing while membership matches', () {
    final session = build().start(staged);

    expect(session.diff(staged), isEmpty);
  });

  test('reports a key that appeared, named', () {
    final session = build().start(staged);

    staged.keys.add('b');

    final changes = session.diff(staged).toList();
    expect(changes, hasLength(1));
    expect(changes.single.kind, Staging.resolved);
    expect(changes.single.subject, 'Onions');
  });

  test('ignores a key that disappeared when only additions are reported', () {
    final session = build().start(staged);

    staged.keys.remove('a');

    expect(session.diff(staged), isEmpty);
  });

  test('reports removals when asked', () {
    final session = build(emitOn: MembershipDelta.removed).start(staged);

    staged.keys.remove('a');

    final changes = session.diff(staged).toList();
    expect(changes.single.kind, Staging.unresolved);
    expect(changes.single.subject, 'Tomatoes');
  });

  test('reports both sides when asked', () {
    final session = build(emitOn: MembershipDelta.both).start(staged);

    staged.keys = {'b'};

    expect(session.diff(staged).map((c) => c.kind), [
      Staging.resolved,
      Staging.unresolved,
    ]);
  });

  test('falls back to the added kind when no removedKind is given', () {
    final detector = MembershipDetector<Staged, Staging>(
      id: 'unresolved',
      kind: Staging.resolved,
      keysOf: (s) => s.keys,
      emitOn: MembershipDelta.both,
    );
    final session = detector.start(staged);

    staged.keys = <String>{};

    expect(session.diff(staged).single.kind, Staging.resolved);
  });
}
