import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

void main() {
  group('defaultEquals', () {
    test('descends into lists, maps, and sets', () {
      expect(defaultEquals([1, 2], [1, 2]), isTrue);
      expect(defaultEquals([1, 2], [2, 1]), isFalse);
      expect(defaultEquals({'a': 1}, {'a': 1}), isTrue);
      expect(defaultEquals({1, 2}, {2, 1}), isTrue);
    });

    test('treats 1 and 1.0 as equal, following Dart num equality', () {
      expect(defaultEquals(1, 1.0), isTrue);
    });
  });

  group('nullableStringEquals', () {
    test('treats null and empty as the same', () {
      expect(nullableStringEquals(null, ''), isTrue);
      expect(nullableStringEquals('', null), isTrue);
      expect(nullableStringEquals(null, null), isTrue);
    });

    test('still separates real values', () {
      expect(nullableStringEquals('note', ''), isFalse);
      expect(nullableStringEquals('a', 'b'), isFalse);
    });
  });
}
