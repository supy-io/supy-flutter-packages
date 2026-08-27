import 'package:reactive_forms/reactive_forms.dart';

/// Flattens a control tree into `path -> value`, one entry per leaf.
///
/// Paths are dotted, with array elements addressed by index:
/// `documentNumber`, `items.0.quantity`, `items.1.packaging.id`.
///
/// Walks the control tree rather than reading `rawValue`, so disabled controls
/// are included — a field the surface disables mid-edit still holds a value the
/// user may have changed, and dropping it would silently under-report.
Map<String, Object?> flattenControls(AbstractControl<dynamic> control) {
  final flattened = <String, Object?>{};
  _walk(control, '', flattened);

  return flattened;
}

void _walk(
  AbstractControl<dynamic> control,
  String path,
  Map<String, Object?> into,
) {
  if (control is FormGroup) {
    for (final entry in control.controls.entries) {
      _walk(entry.value, _join(path, entry.key), into);
    }

    return;
  }
  if (control is FormArray) {
    final controls = control.controls;
    for (var index = 0; index < controls.length; index++) {
      _walk(controls[index], _join(path, '$index'), into);
    }

    return;
  }

  into[path] = control.value;
}

String _join(String path, String segment) =>
    path.isEmpty ? segment : '$path.$segment';

/// Whether [path] matches [pattern], where `*` stands for one whole segment.
///
/// `items.*.uiOnly` matches `items.0.uiOnly` and `items.12.uiOnly`, but not
/// `items.0.packaging.uiOnly`.
bool matchesControlPath(String path, String pattern) {
  if (!pattern.contains('*')) return path == pattern;

  final pathSegments = path.split('.');
  final patternSegments = pattern.split('.');
  if (pathSegments.length != patternSegments.length) return false;

  for (var index = 0; index < patternSegments.length; index++) {
    final expected = patternSegments[index];
    if (expected == '*') continue;
    if (expected != pathSegments[index]) return false;
  }

  return true;
}
