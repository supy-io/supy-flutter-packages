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

## Testing

Use `settle()` (`Future.delayed(Duration.zero)`) in plain `test()` bodies. Under
`testWidgets`, the faked clock deadlocks against a real `Future.delayed` — use
`tester.pump(duration)`, or `fakeAsync` for a debounced tracker.

## License

MIT
