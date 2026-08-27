import 'package:flutter/foundation.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:unsaved_changes/unsaved_changes.dart';
import 'package:unsaved_changes_forms/unsaved_changes_forms.dart';

enum InvoiceChange { header, lines, notes }

class InvoiceSources {
  InvoiceSources(this.form);

  final FormGroup form;
}

void main() {
  final sources = InvoiceSources(
    FormGroup({
      'number': FormControl<String>(value: 'INV-1'),
      'date': FormControl<DateTime>(value: DateTime(2026)),
      'notes': FormControl<String>(),
      'searchQuery': FormControl<String>(),
      'lines': FormArray<Map<String, Object?>>([
        FormGroup({'qty': FormControl<int>(value: 1)}),
      ]),
    }),
  );

  // One detector covers the whole form: every leaf control becomes a dotted
  // path, and paths mapping to the same kind collapse into one change.
  final tracker = ChangeTracker<InvoiceSources, InvoiceChange>(
    sources: sources,
    detectors: [
      FormGroupDetector<InvoiceSources, InvoiceChange>(
        id: 'form',
        formOf: (s) => s.form,
        ignore: {'searchQuery'},
        equalsFor: (path) => path == 'notes' ? nullableStringEquals : null,
        kindOf: (path) => switch (path) {
          'number' || 'date' => InvoiceChange.header,
          'notes' => InvoiceChange.notes,
          _ when path.startsWith('lines.') => InvoiceChange.lines,
          _ => null,
        },
      ),
    ],
  );

  // No manual subscription: the detector already listens to valueChanges.
  sources.form.control('number').value = 'INV-2';

  // tracker.hasChanges guards a back navigation; tracker.changeCount drives a
  // banner; tracker.captureBaseline() runs after a successful save.
  debugPrint(tracker.describe());
}
