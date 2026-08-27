import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:unsaved_changes/unsaved_changes.dart';
import 'package:unsaved_changes/unsaved_changes_testing.dart';
import 'package:unsaved_changes_forms/unsaved_changes_forms.dart';

enum Edit { header, notes, items, ignored }

class Sources {
  Sources(this.form);

  final FormGroup form;
}

FormGroup buildForm() => FormGroup({
      'number': FormControl<String>(value: 'INV-1'),
      'date': FormControl<DateTime>(value: DateTime(2026)),
      'notes': FormControl<String>(),
      'searchQuery': FormControl<String>(value: ''),
      'items': FormArray<Map<String, Object?>>([
        FormGroup({
          'qty': FormControl<int>(value: 1),
          'uiOnly': FormControl<bool>(value: false),
        }),
      ]),
    });

void main() {
  late Sources sources;

  setUp(() => sources = Sources(buildForm()));

  FormGroupDetector<Sources, Edit> build() => FormGroupDetector<Sources, Edit>(
        id: 'form',
        formOf: (s) => s.form,
        ignore: {'searchQuery', 'items.*.uiOnly'},
        equalsFor: (path) => path == 'notes' ? nullableStringEquals : null,
        kindOf: (path) => switch (path) {
          'number' || 'date' => Edit.header,
          'notes' => Edit.notes,
          _ when path.startsWith('items.') => Edit.items,
          _ => null,
        },
      );

  test('reports nothing on a freshly loaded form', () {
    final session = build().start(sources);

    expect(session.diff(sources), isEmpty);
  });

  test('collapses several paths of the same kind into one change', () {
    final session = build().start(sources);

    sources.form.control('number').value = 'INV-2';
    sources.form.control('date').value = DateTime(2027);

    final changes = session.diff(sources).toList();
    expect(changes, hasLength(1));
    expect(changes.single.kind, Edit.header);
  });

  test('keeps different kinds separate', () {
    final session = build().start(sources);

    sources.form.control('number').value = 'INV-2';
    sources.form.control('notes').value = 'late';

    expect(session.diff(sources).map((c) => c.kind), [
      Edit.header,
      Edit.notes,
    ]);
  });

  test('reaches into arrays', () {
    final session = build().start(sources);

    (sources.form.control('items') as FormArray).control('0').value = {
      'qty': 9,
      'uiOnly': false,
    };

    expect(session.diff(sources).map((c) => c.kind), [Edit.items]);
  });

  test('ignores exact paths in the ignore set', () {
    final session = build().start(sources);

    sources.form.control('searchQuery').value = 'tomato';

    expect(session.diff(sources), isEmpty);
  });

  test('ignores wildcard paths in the ignore set', () {
    final session = build().start(sources);

    (sources.form.control('items') as FormArray).control('0').value = {
      'qty': 1,
      'uiOnly': true,
    };

    expect(session.diff(sources), isEmpty);
  });

  test('a null kind ignores the path even when it moved', () {
    final detector = FormGroupDetector<Sources, Edit>(
      id: 'form',
      formOf: (s) => s.form,
      kindOf: (path) => path == 'number' ? Edit.header : null,
    );
    final session = detector.start(sources);

    sources.form.control('notes').value = 'anything';

    expect(session.diff(sources), isEmpty);
  });

  test('equalsFor treats notes cleared back to empty as unedited', () {
    final session = build().start(sources);

    sources.form.control('notes').value = '';

    expect(
      session.diff(sources),
      isEmpty,
      reason: 'the control started null; clearing it is not an edit',
    );
  });

  test('subjectOf splits one kind into one change per subject', () {
    final detector = FormGroupDetector<Sources, Edit>(
      id: 'form',
      formOf: (s) => s.form,
      kindOf: (path) => path == 'number' || path == 'date' ? Edit.header : null,
      subjectOf: (path) => path,
    );
    final session = detector.start(sources);

    sources.form.control('number').value = 'INV-2';
    sources.form.control('date').value = DateTime(2027);

    expect(session.diff(sources).map((c) => c.subject), ['number', 'date']);
  });

  test('reports a control added to an array', () {
    final session = build().start(sources);

    (sources.form.control('items') as FormArray<Map<String, Object?>>).add(
      FormGroup({
        'qty': FormControl<int>(value: 3),
        'uiOnly': FormControl<bool>(value: false),
      }),
    );

    expect(session.diff(sources).map((c) => c.kind), [Edit.items]);
  });

  test('reports a control removed from an array', () {
    final session = build().start(sources);

    (sources.form.control('items') as FormArray<Map<String, Object?>>)
        .removeAt(0);

    expect(session.diff(sources).map((c) => c.kind), [Edit.items]);
  });

  test('subscribes to the form valueChanges', () {
    expect(build().streams(sources), hasLength(1));
  });

  test('drives a tracker end to end off valueChanges alone', () async {
    final tracker = ChangeTracker<Sources, Edit>(
      sources: sources,
      detectors: [build()],
    );
    addTearDown(tracker.dispose);

    expect(tracker.hasChanges, isFalse);

    sources.form.control('number').value = 'INV-2';
    await settle();

    expect(tracker.changeCount, 1);
    expect(tracker.kinds, {Edit.header});

    sources.form.control('number').value = 'INV-1';
    await settle();

    expect(tracker.hasChanges, isFalse);
  });

  test('a typing burst produces one publish, not one per keystroke', () async {
    final observer = RecordingObserver();
    final tracker = ChangeTracker<Sources, Edit>(
      sources: sources,
      detectors: [build()],
      options: TrackerOptions(observer: observer),
    );
    addTearDown(tracker.dispose);

    for (final value in ['l', 'la', 'lat', 'late']) {
      sources.form.control('notes').value = value;
    }
    await settle();

    expect(observer.published, hasLength(1));
    expect(tracker.kinds, {Edit.notes});
  });
}
