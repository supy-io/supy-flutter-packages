import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryOrdering', () {
    test('ApiQueryOrdering toMap should produce correct JSON', () {
      const ordering = ApiQueryOrdering(
        field: 'name',
        dir: QueryOrderDirection.desc,
      );

      final expectedJson = {'field': 'name', 'dir': 'desc'};

      expect(ordering.toMap(), equals(expectedJson));
    });
    test('constructor sets field and direction correctly', () {
      const ordering = ApiQueryOrdering(
        field: 'name',
        dir: QueryOrderDirection.asc,
      );

      expect(ordering.field, 'name');
      expect(ordering.dir, QueryOrderDirection.asc);
    });

    test('toMap returns correct map representation', () {
      const ordering = ApiQueryOrdering(
        field: 'date',
        dir: QueryOrderDirection.desc,
      );
      final map = ordering.toMap();

      expect(map, {'field': 'date', 'dir': 'desc'});
    });
  });

  group('cloneApiQueryOrdering', () {
    test('clone creates a new identical instance', () {
      const original = ApiQueryOrdering(
        field: 'price',
        dir: QueryOrderDirection.asc,
      );
      final cloned = cloneApiQueryOrdering(original);

      expect(
        cloned,
        isNot(same(original)),
        reason: 'Clone should not be same instance',
      );
      expect(cloned.field, original.field);
      expect(cloned.dir, original.dir);
    });
  });
}
