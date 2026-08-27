# unsaved_changes

Detects unsaved changes on editable Flutter surfaces by diffing live state
against a captured baseline, and reports **what** changed — not just *that*
something did.

A `bool isDirty` is easy. What a user actually needs is "you have 3 unsaved
changes: the quantity on Tomatoes, the invoice date, and one attachment" — and
that is the part every app rewrites from scratch.

## What it does

- **Captures a baseline** when the saved state loads, and re-captures it when a
  save succeeds — without discarding in-progress edits on an unrelated rebuild.
- **Subscribes** to every `Listenable` and `Stream` its detectors declare,
  de-duplicated, so two detectors watching the same form subscribe once.
- **Coalesces** a burst of edits into a single diff — one recompute per frame,
  or per debounce window.
- **Republishes only on real change**, so a `select` on `changeCount` stays
  cheap under a stream of keystrokes.
- **Degrades instead of crashing**: a detector that throws is skipped and
  reported, and the rest keep working.

## Quick start

```dart
enum ProfileChange { name, email }

class ProfileDetector
    extends SnapshotChangeDetector<List<String>, ProfileForm, ProfileChange> {
  const ProfileDetector();

  @override
  String get id => 'profile';

  @override
  List<String> capture(ProfileForm form) => [form.name.text, form.email.text];

  @override
  Iterable<TrackedChange<ProfileChange>> compare(
    List<String> baseline,
    ProfileForm form,
  ) => [
    if (form.name.text != baseline[0])
      const TrackedChange(ProfileChange.name, subject: 'Name'),
    if (form.email.text != baseline[1])
      const TrackedChange(ProfileChange.email, subject: 'Email'),
  ];

  @override
  Iterable<Listenable> listenables(ProfileForm form) =>
      [form.name, form.email];
}

final tracker = ChangeTracker<ProfileForm, ProfileChange>(
  sources: form,
  detectors: const [ProfileDetector()],
);

if (tracker.hasChanges) { /* warn before leaving */ }
```

## Ready-made detectors

Most surfaces never write a detector class — they configure one.

| Detector | Use it for |
|---|---|
| `FieldGroupDetector` | Scalar fields grouped by what they mean to a user. Several fields moving in one group report **one** change. |
| `CollectionDetector` | A keyed collection: additions, removals, and per-`Facet` edits, each named by item. |
| `MembershipDetector` | Keys entering or leaving a set — staged resolutions, selected rows. |
| `PayloadDigestDetector` | A `fallback` safety net over the whole request payload, for edits no named detector knows. |
| `ValueStreamDetector` | A single value read from a bloc or view model, compared by `Facet`. |

```dart
FieldGroupDetector<Sources, Kind>(
  id: 'settings',
  listenablesOf: (s) => [s.stepThree],
  groups: [
    FieldGroup(
      kind: Kind.remarks,
      fields: {'remarks': (s) => s.remarks},
      equals: nullableStringEquals,   // a field cleared to '' was never edited
    ),
    FieldGroup(
      kind: Kind.flags,
      fields: {
        'dispute': (s) => s.dispute,
        'relock': (s) => s.relock,
        'closeOrder': (s) => s.closeOrder,
      },
    ),
  ],
)
```

A `Facet` groups the fields that mean one thing: quantity and received-quantity
are one facet, because "the quantity changed" is one thing to tell someone, not
two.

```dart
CollectionDetector<Sources, Kind, Line>(
  id: 'items',
  itemsOf: (s) => s.lines,          // Map<Object, Line>
  subjectOf: (line) => line.name,
  addedKind: Kind.itemsAdded,
  removedKind: Kind.itemsRemoved,
  facets: [
    Facet(kind: Kind.quantity, values: (l) => [l.qty, l.receivedQty]),
    Facet(kind: Kind.price,    values: (l) => [l.price, l.expectedPrice]),
  ],
)
```

## Concepts

| Type | Role |
|---|---|
| `ChangeTracker<C, K>` | The engine. A `ChangeNotifier` over a `ChangeSet<K>`. |
| `ChangeDetector<C, K>` | Knows how to snapshot one slice of state and diff it. |
| `SnapshotChangeDetector<S, C, K>` | The base class you almost always want. |
| `TrackedChange<K>` | One difference: a kind, and optionally a subject. |
| `ChangeSet<K>` | Read-model — count, kinds, `ofKind`, `subjectsByKind`. |
| `BaselineSource<T>` | Where "the saved state changed" comes from. |
| `TrackerOptions` | Debounce, observer, tracker id. |

`C` is whatever your detectors read from — a struct of providers, a bloc, a
form. `K` is **your own** change-kind enum, so the `switch` that turns a change
into a sentence stays exhaustive.

### Snapshots hold values, never live objects

`capture` must extract comparable values. Storing the live object means a
mutation in place silently rewrites the baseline and the edit goes unreported.

### Describing vs. fallback detectors

Give a whole-payload digest `DetectorRole.fallback` and its changes are dropped
whenever any named detector fired — so the banner says "1 unsaved change", not
"2", when one edit is reported both by name and by digest.

### Re-baselining

Call `captureBaseline()` after a successful save, or supply a `BaselineSource`
to have it happen automatically. Pass `captureBaseline(detectorId: 'items')` to
accept one detector's changes while leaving the rest reported.

### Diagnostics

`tracker.describe()` dumps each detector, its role, and what it reported — the
answer to "why does it say I have unsaved changes?". Wire a
`ChangeTrackerObserver` to turn that into breadcrumbs.

## Adding tracking to a surface

Five steps, and only the first two are specific to your feature.

**1. Declare the kinds.** Your own enum, so the `switch` that turns a change
into a sentence stays exhaustive.

```dart
enum InvoiceChange { header, attachments, lines, notes }

typedef InvoiceTracker  = ChangeTracker<InvoiceSources, InvoiceChange>;
typedef InvoiceDetector = ChangeDetector<InvoiceSources, InvoiceChange>;
```

**2. Name the sources.** Whatever your detectors read from — a struct of
providers, a bloc, a form. There is no base class to extend.

```dart
class InvoiceSources {
  const InvoiceSources({required this.form, required this.lines});
  final FormGroup form;
  final LinesProvider lines;
}
```

**3. Configure the detectors.** Reach for a hand-written
`SnapshotChangeDetector` only when none of the ready-made ones fit.

```dart
List<InvoiceDetector> invoiceDetectors() => [
  FieldGroupDetector(id: 'header', /* … */),
  CollectionDetector(id: 'lines', /* … */),
];
```

**4. Build the tracker** and register it where the surface can read it.

```dart
ChangeNotifierProvider<InvoiceTracker>(
  lazy: false,
  create: (_) => InvoiceTracker(
    sources: sources,
    detectors: invoiceDetectors(),
    baseline: BaselineSource<Invoice>(read: () => provider.saved, signal: provider),
  ),
);
```

**5. Use it.** `hasChanges` guards leaving, `changeCount` drives a banner, and
`captureBaseline()` runs after a successful save.

### Choosing a revision key

`BaselineSource.revisionOf` decides when the saved state has genuinely been
replaced. Its result is compared with `==`, so **never return a collection**:
Dart compares `Set`, `List` and `Map` by identity, and a rebuilt-but-equal one
reads as a new revision. The tracker then re-baselines and silently reports
nothing — the worst failure this package has, because it looks like "no unsaved
changes" rather than an error.

```dart
// Wrong: a new Set instance every rebuild is a new revision.
revisionOf: (state) => state.initialKeys,

// Right: compare the contents.
revisionOf: (state) => (state.initialKeys.toList()..sort()).join('\u0000'),
```

Return an id, a timestamp, a version number, or a string built from contents.
Omit `revisionOf` entirely to fall back to object identity, which is correct
when the saved state is replaced wholesale on every save.

## Testing

`package:unsaved_changes/unsaved_changes_testing.dart` ships the doubles this
package's own engine tests use, so adopters do not rewrite them:
`ScriptedDetector` (scripted findings, counts `start`/`diff` calls, can be made
to throw), `TestTicker` (a pokeable `Listenable` that can report whether
anything subscribed), `RecordingObserver`, and `settle()`. It adds no
dependencies and works under both `test` and `flutter_test`.

Use `settle()` (`Future.delayed(Duration.zero)`) in plain `test()` bodies. Under
`testWidgets`, the faked clock deadlocks against a real `Future.delayed` — use
`tester.pump(duration)`, or `fakeAsync` for a debounced tracker.

## License

MIT
