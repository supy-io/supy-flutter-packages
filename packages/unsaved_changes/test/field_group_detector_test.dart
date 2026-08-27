import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum Doc { header, attachments }

class Form {
  String? number;
  DateTime? date;
  double? amount;
  List<String> attachments = [];
  String? remarks;
}

void main() {
  late Form form;

  setUp(() => form = Form()..number = 'INV-1');

  FieldGroupDetector<Form, Doc> build({
    bool Function(Object? a, Object? b)? equals,
  }) =>
      FieldGroupDetector<Form, Doc>(
        id: 'document',
        groups: [
          FieldGroup(
            kind: Doc.header,
            fields: {
              'number': (f) => f.number,
              'date': (f) => f.date,
              'amount': (f) => f.amount,
            },
            equals: equals,
          ),
          FieldGroup(
            kind: Doc.attachments,
            fields: {'keys': (f) => f.attachments},
          ),
        ],
      );

  List<TrackedChange<Doc>> diff(FieldGroupDetector<Form, Doc> detector) =>
      detector.start(form).diff(form).toList();

  test('reports nothing while every field matches', () {
    expect(diff(build()), isEmpty);
  });

  test('collapses several moved fields in one group into one change', () {
    final detector = build();
    final session = detector.start(form);

    form
      ..number = 'INV-2'
      ..date = DateTime(2026)
      ..amount = 99;

    final changes = session.diff(form).toList();
    expect(changes, hasLength(1));
    expect(changes.single.kind, Doc.header);
  });

  test('keeps groups independent', () {
    final detector = build();
    final session = detector.start(form);

    form.attachments = ['a.pdf'];

    final changes = session.diff(form).toList();
    expect(changes.map((c) => c.kind), [Doc.attachments]);
  });

  test('compares lists deeply, so order and contents both count', () {
    form.attachments = ['a.pdf', 'b.pdf'];
    final detector = build();
    final session = detector.start(form);

    form.attachments = ['b.pdf', 'a.pdf'];
    expect(session.diff(form), hasLength(1));

    form.attachments = ['a.pdf', 'b.pdf'];
    expect(session.diff(form), isEmpty);
  });

  test('a custom equals can treat null and empty as the same', () {
    form.number = null;
    final detector = build(equals: nullableStringEquals);
    final session = detector.start(form);

    form.number = '';
    expect(
      session.diff(form),
      isEmpty,
      reason: 'clearing a field that was never filled in is not an edit',
    );

    form.number = 'INV-9';
    expect(session.diff(form), hasLength(1));
  });

  test('carries the group subject onto the change', () {
    final detector = FieldGroupDetector<Form, Doc>(
      id: 'document',
      groups: [
        FieldGroup(
          kind: Doc.header,
          fields: {'number': (f) => f.number},
          subject: 'Invoice number',
        ),
      ],
    );
    final session = detector.start(form);

    form.number = 'INV-2';
    expect(session.diff(form).single.subject, 'Invoice number');
  });

  test('rejects a detector with no groups', () {
    expect(
      () => FieldGroupDetector<Form, Doc>(id: 'empty', groups: const []),
      throwsA(isA<AssertionError>()),
    );
  });

  test('exposes the listenables and streams it was configured with', () {
    final notifier = ValueNotifier<int>(0);
    addTearDown(notifier.dispose);
    final detector = FieldGroupDetector<Form, Doc>(
      id: 'document',
      groups: [
        FieldGroup(kind: Doc.header, fields: {'number': (f) => f.number}),
      ],
      listenablesOf: (_) => [notifier],
      streamsOf: (_) => [const Stream<Object?>.empty()],
    );

    expect(detector.listenables(form), [notifier]);
    expect(detector.streams(form), hasLength(1));
  });
}
