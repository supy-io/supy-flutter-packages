import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:unsaved_changes_forms/unsaved_changes_forms.dart';

void main() {
  group('flattenControls', () {
    test('flattens a plain group', () {
      final form = FormGroup({
        'number': FormControl<String>(value: 'INV-1'),
        'amount': FormControl<double>(value: 10),
      });

      expect(flattenControls(form), {'number': 'INV-1', 'amount': 10.0});
    });

    test('flattens nested groups with dotted paths', () {
      final form = FormGroup({
        'supplier': FormGroup({'id': FormControl<String>(value: 's1')}),
      });

      expect(flattenControls(form), {'supplier.id': 's1'});
    });

    test('addresses array elements by index', () {
      final form = FormGroup({
        'items': FormArray<Map<String, Object?>>([
          FormGroup({'qty': FormControl<int>(value: 1)}),
          FormGroup({'qty': FormControl<int>(value: 2)}),
        ]),
      });

      expect(flattenControls(form), {'items.0.qty': 1, 'items.1.qty': 2});
    });

    test('includes disabled controls', () {
      final form = FormGroup({
        'locked': FormControl<String>(value: 'kept', disabled: true),
        'open': FormControl<String>(value: 'x'),
      });

      expect(
        flattenControls(form),
        {'locked': 'kept', 'open': 'x'},
        reason: 'a field disabled mid-edit still holds a value the user set',
      );
    });
  });

  group('matchesControlPath', () {
    test('matches an exact path', () {
      expect(matchesControlPath('a.b', 'a.b'), isTrue);
      expect(matchesControlPath('a.b', 'a.c'), isFalse);
    });

    test('a wildcard stands for exactly one segment', () {
      expect(matchesControlPath('items.0.uiOnly', 'items.*.uiOnly'), isTrue);
      expect(matchesControlPath('items.12.uiOnly', 'items.*.uiOnly'), isTrue);
      expect(
        matchesControlPath('items.0.packaging.uiOnly', 'items.*.uiOnly'),
        isFalse,
        reason: 'a wildcard must not span a dot',
      );
    });

    test('requires the same segment count', () {
      expect(matchesControlPath('items.0', 'items.*.uiOnly'), isFalse);
    });
  });
}
