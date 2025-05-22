import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryFilteringGroup', () {
    late ApiQueryFilter filter1;
    late ApiQueryFilter filter2;
    late ApiQueryFilteringGroup nestedGroup;

    setUp(() {
      filter1 = ApiQueryFilter(
        field: 'age',
        operation: QueryOperation.greaterThan,
        value: 30,
      );
      filter2 = ApiQueryFilter(
        field: 'status',
        operation: QueryOperation.equals,
        value: 'active',
      );
      nestedGroup = ApiQueryFilteringGroup.and([filter2]);
    });

    test('ApiQueryFilteringGroup toMap should handle empty group', () {
      final emptyGroup = ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filters: [],
        groups: [],
      );

      final expectedJson = {
        'filtering': {
          'condition': 'and',
          'filters': <dynamic>[],
          'groups': <dynamic>[],
        },
      };

      expect(emptyGroup.toMap(), equals(expectedJson));
    });

    test('constructs correctly with required fields', () {
      final group = ApiQueryFilteringGroup(
        condition: FilterConditionType.or,
        filters: [filter1],
        groups: [nestedGroup],
      );

      expect(group.condition, FilterConditionType.or);
      expect(group.filters.length, 1);
      expect(group.groups?.length, 1);
    });

    test('shortcut constructors set correct condition', () {
      final andGroup = ApiQueryFilteringGroup.and([filter1]);
      final orGroup = ApiQueryFilteringGroup.or([filter1]);
      final notGroup = ApiQueryFilteringGroup.not([filter1]);

      expect(andGroup.condition, FilterConditionType.and);
      expect(orGroup.condition, FilterConditionType.or);
      expect(notGroup.condition, FilterConditionType.not);
    });

    test('toMap serializes correctly with nested groups', () {
      final group = ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filters: [filter1],
        groups: [nestedGroup],
      );

      final map = group.toMap();

      expect(map, contains('filtering'));
      final filtering = map['filtering'] as Map<String, dynamic>;

      expect(filtering['condition'], 'and');

      final filtersList = filtering['filters'] as List<dynamic>;
      expect(filtersList.length, 1);
      expect((filtersList.first as Map<String, dynamic>)['field'], 'age');

      final groupsList = filtering['groups'] as List<dynamic>;
      expect(groupsList.length, 1);

      final nested = groupsList.first as Map<String, dynamic>;
      expect(nested['condition'], 'and');
      final nestedFilters = nested['filters'] as List<dynamic>;
      expect(nestedFilters.length, 1);
      expect((nestedFilters.first as Map<String, dynamic>)['field'], 'status');
    });

    test('toMap returns empty groups list if no groups provided', () {
      final group = ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filters: [filter1],
      );

      final map = group.toMap();
      final filtering = map['filtering'] as Map<String, dynamic>;

      expect(filtering['groups'], isEmpty);
    });
  });

  group('cloneApiQueryFilteringGroup', () {
    test('clones deeply with nested filters and groups', () {
      final filter1 = ApiQueryFilter(
        field: 'field1',
        operation: QueryOperation.equals,
        value: 'value1',
      );
      final filter2 = ApiQueryFilter(
        field: 'field2',
        operation: QueryOperation.notEquals,
        value: 'value2',
      );
      final nestedGroup = ApiQueryFilteringGroup.and([filter2]);

      final original = ApiQueryFilteringGroup(
        condition: FilterConditionType.or,
        filters: [filter1],
        groups: [nestedGroup],
      );

      final clone = cloneApiQueryFilteringGroup(original);

      expect(clone, isNot(same(original)));
      expect(clone.condition, original.condition);
      expect(clone.filters.length, original.filters.length);
      expect(clone.filters.first.field, original.filters.first.field);
      expect(clone.filters.first, isNot(same(original.filters.first)));

      expect(clone.groups?.length, original.groups?.length);
      expect(clone.groups?.first.condition, original.groups?.first.condition);
      expect(
        clone.groups?.first.filters.length,
        original.groups?.first.filters.length,
      );
      expect(
        clone.groups?.first.filters.first,
        isNot(same(original.groups?.first.filters.first)),
      );
    });

    test(
      'ApiQueryFilteringGroup with nested groups should produce correct JSON',
      () {
        final nestedGroup = ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [
            ApiQueryFilter(
              field: 'field1',
              operation: QueryOperation.equals,
              value: 'value1',
            ),
            ApiQueryFilter(
              field: 'field2',
              operation: QueryOperation.notEquals,
              value: 'value2',
            ),
          ],
          groups: [
            ApiQueryFilteringGroup(
              condition: FilterConditionType.or,
              filters: [
                ApiQueryFilter(
                  field: 'nestedField1',
                  operation: QueryOperation.contains,
                  value: 'nestedValue1',
                ),
                ApiQueryFilter(
                  field: 'nestedField2',
                  operation: QueryOperation.notContains,
                  value: 'nestedValue2',
                ),
              ],
              groups: [],
            ),
          ],
        );

        final expectedJson = {
          'filtering': {
            'condition': 'and',
            'filters': [
              {'field': 'field1', 'operation': 'equals', 'value': 'value1'},
              {'field': 'field2', 'operation': 'notEquals', 'value': 'value2'},
            ],
            'groups': [
              {
                'condition': 'or',
                'filters': [
                  {
                    'field': 'nestedField1',
                    'operation': 'contains',
                    'value': 'nestedValue1',
                  },
                  {
                    'field': 'nestedField2',
                    'operation': 'notContains',
                    'value': 'nestedValue2',
                  },
                ],
                'groups': <dynamic>[],
              },
            ],
          },
        };

        expect(nestedGroup.toMap(), equals(expectedJson));
      },
    );
  });
}
