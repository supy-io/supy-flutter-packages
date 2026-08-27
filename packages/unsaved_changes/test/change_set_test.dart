import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

import 'helpers.dart';

void main() {
  const changes = [
    TrackedChange(Kind.title, subject: 'Tomatoes'),
    TrackedChange(Kind.title, subject: 'Onions'),
    TrackedChange(Kind.other),
  ];

  test('empty set reports nothing', () {
    const set = ChangeSet<Kind>.empty();

    expect(set.isEmpty, isTrue);
    expect(set.isNotEmpty, isFalse);
    expect(set.length, 0);
    expect(set.kinds, isEmpty);
  });

  test('exposes length, kinds, and emptiness', () {
    const set = ChangeSet(changes);

    expect(set.isEmpty, isFalse);
    expect(set.isNotEmpty, isTrue);
    expect(set.length, 3);
    expect(set.kinds, {Kind.title, Kind.other});
  });

  test('ofKind and countOfKind filter by kind', () {
    const set = ChangeSet(changes);

    expect(set.ofKind(Kind.title), hasLength(2));
    expect(set.countOfKind(Kind.title), 2);
    expect(set.countOfKind(Kind.other), 1);
  });

  test('subjectsByKind groups subjects for summary sentences', () {
    const set = ChangeSet(changes);

    expect(set.subjectsByKind, {
      Kind.title: ['Tomatoes', 'Onions'],
      Kind.other: [null],
    });
  });

  test('equality is by content, so publishing can skip no-op updates', () {
    const a = ChangeSet(changes);
    const b = ChangeSet(changes);
    const c = ChangeSet<Kind>([TrackedChange(Kind.title)]);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });

  test('toString names its changes', () {
    expect(
      const ChangeSet<Kind>([TrackedChange(Kind.title, subject: 'x')])
          .toString(),
      contains('x'),
    );
  });
}
