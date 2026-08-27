## 0.0.3

- Add the `unsaved_changes_testing` library: `ScriptedDetector`, `TestTicker`,
  `RecordingObserver`, and `settle()`. No new dependencies — it works under
  both `test` and `flutter_test`.

## 0.0.2

- Add the detector library: `FieldGroupDetector`, `CollectionDetector`,
  `MembershipDetector`, `PayloadDigestDetector`, `ValueStreamDetector`, and the
  shared `Facet`.
- Add `StreamSignal` and `streamBaseline` so bloc-shaped state can drive a
  tracker without a `ChangeNotifier`.
- Add `BaselineSource.onDispose`, released with the tracker.
- Add `defaultEquals` / `nullableStringEquals`.

## 0.0.1

- Initial release: `ChangeTracker`, `ChangeDetector` / `SnapshotChangeDetector`,
  `TrackedChange`, `ChangeSet`, `BaselineSource`, `TrackerOptions`, and
  `ChangeTrackerObserver`.
