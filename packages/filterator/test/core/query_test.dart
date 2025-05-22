import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQuery', () {
    test('default constructor', () {
      final filteringGroup = ApiQueryFilteringGroup.and([]);
      final paging = ApiQueryPaging.noLimit();

      final query = ApiQuery(
        filtering: filteringGroup,
        ordering: [],
        paging: paging,
      );
      expect(query.filtering, filteringGroup);
      expect(query.paging, paging);
    });

    test('factory from copies correctly', () {
      final original = ApiQuery(
        filtering: ApiQueryFilteringGroup.and([]),
        ordering: [],
        paging: ApiQueryPaging.noLimit(),
      );

      final copy = ApiQuery.from(original);

      expect(copy.filtering, isNotNull);
      expect(copy.ordering, isNotNull);
      expect(copy.paging, isNotNull);
    });

    test('private constructor _ initializes default values', () {
      final query = ApiQuery(
        filtering: ApiQueryFilteringGroup.and([]),
        ordering: const [],
      );
      expect(query.paging, isNull);

      expect(query.filtering, isNotNull);
      expect(query.filtering!.filters, isEmpty);
      expect(query.ordering, isEmpty);
    });

    test('toMap serializes correctly', () {
      final query = ApiQuery(
        filtering: ApiQueryFilteringGroup.and([]),
        ordering: [],
        paging: ApiQueryPaging.noLimit(),
      );

      final map = query.toMap();

      expect(map, contains('filtering'));
      expect(map, contains('paging'));
      expect(map, contains('ordering'));
      expect(map['filtering'], isNotNull);
    });
    test('ApiQuery toMap should produce correct JSON', () {
      final query = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [
            ApiQueryFilter(
              field: 'name.en',
              operation: QueryOperation.like,
              value: 'apple',
            ),
            ApiQueryFilter(
              field: 'name.ar',
              operation: QueryOperation.like,
              value: 'apple',
            ),
          ],
          groups: [
            ApiQueryFilteringGroup(
              condition: FilterConditionType.or,
              filters: [
                ApiQueryFilter(
                  field: 'G1',
                  operation: QueryOperation.like,
                  value: 'G1',
                ),
                ApiQueryFilter(
                  field: 'G1',
                  operation: QueryOperation.like,
                  value: 'G1',
                ),
              ],
              groups: [
                ApiQueryFilteringGroup(
                  condition: FilterConditionType.and,
                  filters: [
                    ApiQueryFilter(
                      field: 'G2',
                      operation: QueryOperation.like,
                      value: 'G2',
                    ),
                    ApiQueryFilter(
                      field: 'G2',
                      operation: QueryOperation.like,
                      value: 'G2',
                    ),
                  ],
                  groups: [],
                ),
              ],
            ),
          ],
        ),
        ordering: [
          const ApiQueryOrdering(field: 'name', dir: QueryOrderDirection.asc),
        ],
        paging: const ApiQueryPaging(limit: 0, offset: 20),
      );

      final expectedJson = {
        'filtering': {
          'condition': 'and',
          'filters': [
            {'field': 'name.en', 'operation': 'like', 'value': 'apple'},
            {'field': 'name.ar', 'operation': 'like', 'value': 'apple'},
          ],
          'groups': [
            {
              'condition': 'or',
              'filters': [
                {'field': 'G1', 'operation': 'like', 'value': 'G1'},
                {'field': 'G1', 'operation': 'like', 'value': 'G1'},
              ],
              'groups': [
                {
                  'condition': 'and',
                  'filters': [
                    {'field': 'G2', 'operation': 'like', 'value': 'G2'},
                    {'field': 'G2', 'operation': 'like', 'value': 'G2'},
                  ],
                  'groups': <dynamic>[],
                },
              ],
            },
          ],
        },
        'paging': {'offset': 20, 'limit': 0},
        'ordering': [
          {'field': 'name', 'dir': 'asc'},
        ],
      };

      expect(query.toMap(), equals(expectedJson));
    });
    test('ApiQuery with null values should produce correct JSON', () {
      final queryWithNulls = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [
            ApiQueryFilter(
              field: 'field1',
              operation: QueryOperation.equals,
              value: 'value1',
            ),
          ],
        ),
      );

      final expectedJson = {
        'filtering': {
          'condition': 'and',
          'filters': [
            {'field': 'field1', 'operation': 'equals', 'value': 'value1'},
          ],
          'groups': <dynamic>[],
        },
      };

      expect(queryWithNulls.toMap(), equals(expectedJson));
    });
    test(
      'ApiQuery with empty ordering and paging should produce correct JSON',
      () {
        final queryWithEmptyValues = ApiQuery(
          filtering: ApiQueryFilteringGroup(
            condition: FilterConditionType.and,
            filters: [
              ApiQueryFilter(
                field: 'field1',
                operation: QueryOperation.equals,
                value: 'value1',
              ),
            ],
            groups: [],
          ),
          ordering: [],
          paging: ApiQueryPaging.noLimit(),
        );

        final expectedJson = {
          'filtering': {
            'condition': 'and',
            'filters': [
              {'field': 'field1', 'operation': 'equals', 'value': 'value1'},
            ],
            'groups': <dynamic>[],
          },
          'paging': {'offset': 0, 'limit': -1},
          'ordering': <dynamic>[],
        };

        expect(queryWithEmptyValues.toMap(), equals(expectedJson));
      },
    );
  });
}
