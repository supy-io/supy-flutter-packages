import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryFilter', () {
    test('constructor initializes fields correctly', () {
      final filter = ApiQueryFilter(
        field: 'age',
        operation: QueryOperation.equals,
        value: 30,
      );

      expect(filter.field, 'age');
      expect(filter.operation, QueryOperation.equals);
      expect(filter.value, 30);
      expect(filter.values, isNull);
    });

    test('ApiQueryFiltering toMap should produce correct JSON', () {
      final filtering = ApiQueryFilter(
        field: 'name.en',
        operation: QueryOperation.like,
        value: 'apple',
      );

      final expectedJson = {
        'field': 'name.en',
        'operation': 'like',
        'value': 'apple',
      };

      expect(filtering.toMap(), equals(expectedJson));
    });

    test(
      'constructor asserts if operation is invalid',
      () {
        expect(
          () => ApiQueryFilter(
            field: 'age',
            operation: QueryOperation.values.firstWhere(
              (op) => op.name == 'invalid',
              orElse: () => throw Exception('Invalid op'),
            ),
            value: 10,
          ),
          throwsException,
        );
      },
      skip: true,
    ); // Skip this test because invalid op can't be constructed easily.

    test('toMap includes all fields properly', () {
      final filter = ApiQueryFilter(
        field: 'status',
        operation: QueryOperation.inList,
        values: ['active', 'pending'],
      );

      final map = filter.toMap();

      expect(map['field'], 'status');
      expect(map['operation'], 'inList');
      expect(map.containsKey('value'), isFalse);
      expect(map['values'], ['active', 'pending']);
    });

    test('toMap includes value if set', () {
      final filter = ApiQueryFilter(
        field: 'score',
        operation: QueryOperation.greaterThan,
        value: 50,
      );

      final map = filter.toMap();

      expect(map['field'], 'score');
      expect(map['operation'], 'greaterThan');
      expect(map['value'], 50);
      expect(map.containsKey('values'), isFalse);
    });
  });

  group('cloneApiQueryFilter', () {
    test('creates exact clone of ApiQueryFilter', () {
      final original = ApiQueryFilter(
        field: 'price',
        operation: QueryOperation.lessThan,
        value: 100,
      );

      final clone = cloneApiQueryFilter(original);

      expect(clone.field, original.field);
      expect(clone.operation, original.operation);
      expect(clone.value, original.value);
      expect(clone.values, original.values);
      expect(clone, isNot(same(original))); // different instance
    });
  });
}
