import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  test('ApiQueryResponse empty should produce correct JSON', () {
    final emptyResponse = ApiQueryResponse.empty();

    final expectedJson = {
      'data': <dynamic>[],
      'metadata': {'count': 0, 'total': 0},
    };

    expect(emptyResponse.toMap(), equals(expectedJson));
  });

  test('ApiQueryFilteringGroup toMap should handle empty group', () {
    final emptyGroup = ApiQueryFilteringGroup(
      condition: FilterConditionType.and,
      filters: [],
      groups: [],
    );

    final expectedJson = {
      'filtering': {'condition': 'and', 'filters': [], 'groups': []},
    };

    expect(emptyGroup.toMap(), equals(expectedJson));
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

  test('ApiQueryPaging toMap should produce correct JSON', () {
    const paging = ApiQueryPaging(offset: 10, limit: 5);

    final expectedJson = {'offset': 10, 'limit': 5};

    expect(paging.toMap(), equals(expectedJson));
  });

  test('ApiQueryOrdering toMap should produce correct JSON', () {
    const ordering = ApiQueryOrdering(
      field: 'name',
      dir: QueryOrderDirection.desc,
    );

    final expectedJson = {'field': 'name', 'dir': 'desc'};

    expect(ordering.toMap(), equals(expectedJson));
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
                'groups': [],
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

  test('ApiQueryResponse with data should produce correct JSON', () {
    final responseWithData = ApiQueryResponse<String>(
      data: ['item1', 'item2'],
      metadata: ApiQueryMetadata(count: 2, total: 10),
    );

    final expectedJson = {
      'data': ['item1', 'item2'],
      'metadata': {'count': 2, 'total': 10},
    };

    expect(responseWithData.toMap(), equals(expectedJson));
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
              'groups': [],
            },
          ],
        },
      };

      expect(nestedGroup.toMap(), equals(expectedJson));
      //  expect(SupyConverter(ApiQuery(filtering: nestedGroup)).toQueryParameters(), equals(expectedJson));
    },
  );

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
        'groups': [],
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
          'groups': [],
        },
        'paging': {'offset': 0, 'limit': -1},
        'ordering': [],
      };

      expect(queryWithEmptyValues.toMap(), equals(expectedJson));
    },
  );
}
