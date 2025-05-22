import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQuerySelection', () {
    test('creates instance with includes only', () {
      const selection = ApiQuerySelection(includes: ['id', 'name']);
      expect(selection.includes, ['id', 'name']);
      expect(selection.excludes, isEmpty);
    });

    test('creates instance with excludes only', () {
      const selection = ApiQuerySelection(excludes: ['password']);
      expect(selection.excludes, ['password']);
      expect(selection.includes, isEmpty);
    });

    test('cloneApiQuerySelection creates identical copy', () {
      const original = ApiQuerySelection(includes: ['id']);
      final clone = cloneApiQuerySelection(original);

      expect(clone.includes, original.includes);
      expect(clone.excludes, original.excludes);
      expect(clone, isNot(same(original))); // different instances
    });

    test('copyWith updates includes', () {
      const selection = ApiQuerySelection(includes: ['id']);
      final copy = selection.copyWith(includes: ['name', 'email']);
      expect(copy.includes, ['name', 'email']);
      expect(copy.excludes, isEmpty);
    });

    test('copyWith updates excludes', () {
      const selection = ApiQuerySelection(excludes: ['token']);
      final copy = selection.copyWith(excludes: ['password']);
      expect(copy.excludes, ['password']);
      expect(copy.includes, isEmpty);
    });

    test('toMap returns include key when includes is non-empty', () {
      const selection = ApiQuerySelection(includes: ['id', 'name']);
      final map = selection.toMap();
      expect(map.containsKey('include'), isTrue);
      expect(map['include'], ['id', 'name']);
      expect(map.containsKey('exclude'), isFalse);
    });

    test('toMap returns exclude key when excludes is non-empty', () {
      const selection = ApiQuerySelection(excludes: ['password']);
      final map = selection.toMap();
      expect(map.containsKey('exclude'), isTrue);
      expect(map['exclude'], ['password']);
      expect(map.containsKey('include'), isFalse);
    });

    test(
      'toMap throws assertion error if both includes and excludes non-empty',
      () {
        const selection = ApiQuerySelection(
          includes: ['id'],
          excludes: ['password'],
        );
        expect(() => selection.toMap(), throwsA(isA<AssertionError>()));
      },
    );

    test(
      'toMap throws assertion error if both includes and excludes empty',
      () {
        const selection = ApiQuerySelection();
        expect(() => selection.toMap(), throwsA(isA<AssertionError>()));
      },
    );
  });
}
