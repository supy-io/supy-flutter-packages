# unsaved_changes_forms

[reactive_forms](https://pub.dev/packages/reactive_forms) adapter for
[unsaved_changes](https://pub.dev/packages/unsaved_changes).

Tracks a whole `FormGroup` for unsaved edits with no per-field configuration.
For a form-shaped surface this is often the only detector you need.

```dart
FormGroupDetector<Sources, InvoiceChange>(
  id: 'form',
  formOf: (s) => s.form,
  ignore: {'searchQuery', 'items.*.uiOnly'},
  equalsFor: (path) => path == 'notes' ? nullableStringEquals : null,
  kindOf: (path) => switch (path) {
    'number' || 'date' => InvoiceChange.header,
    'notes'            => InvoiceChange.notes,
    _ when path.startsWith('items.') => InvoiceChange.items,
    _ => null,   // ignored
  },
)
```

## How it works

Every leaf control becomes a dotted path — `number`, `supplier.id`,
`items.0.quantity` — and each path's value is compared against the baseline.

- **`kindOf`** maps a path to a change kind. Returning `null` ignores the path.
- Paths that map to the same `(kind, subject)` **collapse into one change**, so
  editing three header fields reports one change, not three.
- **`subjectOf`** splits a kind back apart when you want one change per row.
- **`ignore`** skips paths entirely. `*` stands for exactly one segment, so
  `items.*.uiOnly` skips a per-row UI flag on every row without spanning a dot.
- **`equalsFor`** overrides comparison per path — most usefully
  `nullableStringEquals`, so a text field cleared back to `''` when it started
  `null` is not reported as an edit.
- Adding or removing a control from a `FormArray` is a change, because its
  paths appear or disappear.

No manual subscription: the detector already returns the form's `valueChanges`,
and the tracker coalesces a typing burst into a single publish.

Disabled controls are included. A field the surface disables mid-edit still
holds a value the user may have set, and dropping it would under-report.

## License

MIT
