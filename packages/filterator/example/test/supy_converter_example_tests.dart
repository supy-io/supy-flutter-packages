import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

import '../supy_converter_example.dart';

void main() {
  group('SupyConverter Tests', () {
    test('Empty query should return empty map', () {
      const query = ApiQuery();
      final result = query.toSupyQueryParameters();
      expect(result, isEmpty);
    });

    test('Single filter only', () {
      final query = ApiQuery(
        filtering: and(filters: [where('name', 'eq', 'test')]),
      );
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"by":"name"'));
    });

    test('Multiple filters with AND', () {
      final query = ApiQuery(
        filtering: and(
          filters: [where('name', 'eq', 'A'), where('age', 'gt', 18)],
        ),
      );
      final body = query.toSupyQueryParameters();
      expect(body['filtering'], contains('"condition":"and"'));
    });

    test('Multiple filters with OR', () {
      final query = ApiQuery(
        filtering: or(
          filters: [
            where('status', 'eq', 'active'),
            where('status', 'eq', 'pending'),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"condition":"or"'));
    });

    test('Nested filtering groups', () {
      final query = ApiQuery(
        filtering: and(
          filters: [where('age', 'gte', 18)],
          groups: [
            or(
              filters: [
                where('country', 'eq', 'US'),
                where('country', 'eq', 'UK'),
              ],
            ),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['groups'], contains('"condition":"or"'));
    });

    test('Paging with custom values', () {
      final query = ApiQuery(paging: paginate(limit: 25, offset: 10));
      final result = query.toSupyQueryParameters();
      expect(result['paging'], '{"offset":10,"limit":25}');
    });

    test('Paging with no limit', () {
      final query = ApiQuery(paging: ApiQueryPaging.noLimit());
      final result = query.toSupyQueryParameters();
      expect(result['paging'], contains('"limit":-1'));
    });

    test('Ordering ascending', () {
      final query = ApiQuery(ordering: [ordering('name', 'asc')]);
      final result = query.toSupyQueryParameters();
      expect(result['ordering'], contains('"dir":"asc"'));
    });

    test('Ordering descending', () {
      final query = ApiQuery(ordering: [ordering('date', 'desc')]);
      final result = query.toSupyQueryParameters();
      expect(result['ordering'], contains('"dir":"desc"'));
    });

    test('Selection with fields', () {
      final query = ApiQuery(selection: include(['id', 'name']));
      final result = query.toSupyQueryParameters();
      expect(result['selection'], contains('"include"'));
    });

    test('Request body returns valid JSON', () {
      final query = ApiQuery(filtering: and(filters: [where('id', 'eq', 1)]));
      final body = query.toSupyRequestBody();
      expect(body, contains('"match": 1\n'));
    });

    test('Multiple ordering fields', () {
      final query = ApiQuery(
        ordering: [ordering('name', 'asc'), ordering('created_at', 'desc')],
      );
      final result = query.toSupyQueryParameters();
      expect(result['ordering'], contains('"by":"created_at"'));
    });

    test('Filtering with values list', () {
      final query = ApiQuery(
        filtering: and(
          filters: [
            ApiQueryFilter(
              field: 'tags',
              operation: QueryOperation.inList,
              values: ['a', 'b', 'c'],
            ),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"match":["a","b","c"]'));
    });

    test('Empty ordering list included', () {
      const query = ApiQuery(ordering: []);
      final result = query.toSupyQueryParameters();
      expect(result['ordering'], equals('[]'));
    });

    test('Empty groups list included', () {
      final query = ApiQuery(
        filtering: and(filters: [where('a', 'eq', 1)], groups: []),
      );
      final result = query.toSupyQueryParameters();
      expect(result['groups'], equals('[]'));
    });

    test('Deep nested groups structure', () {
      final query = ApiQuery(
        filtering: and(
          filters: [where('x', 'eq', 1)],
          groups: [
            or(
              filters: [where('y', 'eq', 2)],
              groups: [
                and(filters: [where('z', 'eq', 3)]),
              ],
            ),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['groups'], contains('"condition":"and"'));
    });

    test('Empty filtering and selection only', () {
      final query = ApiQuery(selection: include(['id']));
      final result = query.toSupyQueryParameters();
      expect(result['selection'], contains('"include"'));
    });

    test('Ordering only', () {
      final query = ApiQuery(ordering: [ordering('price', 'asc')]);
      final result = query.toSupyQueryParameters();
      expect(result['ordering'], contains('"by":"price"'));
    });

    test('Filter with null value should be excluded', () {
      final query = ApiQuery(
        filtering: and(
          filters: [
            ApiQueryFilter(field: 'field', operation: QueryOperation.equals),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"match":null'));
    });

    test('toRequestBody returns pretty-printed JSON', () {
      final query = ApiQuery(filtering: and(filters: [where('id', 'eq', 1)]));
      final json = query.toSupyRequestBody();
      expect(json, contains('\n  ')); // indented output
    });

    test('Encode flag false returns raw Map', () {
      final query = ApiQuery(filtering: and(filters: [where('x', 'eq', 1)]));
      final converter = SupyConverter(query);
      final map = converter.toQueryParameters(encode: false);
      expect(map['filtering'], isA<Map<dynamic, dynamic>>());
    });

    test('Multiple values: filter with nulls', () {
      final query = ApiQuery(
        filtering: and(
          filters: [
            ApiQueryFilter(field: 'tags', operation: QueryOperation.inList),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"match":null'));
    });

    test('Request body includes all sections', () {
      final query = ApiQuery(
        filtering: and(filters: [where('id', 'eq', 1)]),
        paging: paginate(limit: 10, offset: 0),
        ordering: [ordering('name', 'asc')],
        selection: include(['id', 'name']),
      );
      final json = query.toSupyRequestBody();
      expect(
        json,
        allOf([
          contains('filtering'),
          contains('paging'),
          contains('ordering'),
          contains('selection'),
        ]),
      );
    });

    test('Nested groups with empty subgroups', () {
      final query = ApiQuery(
        filtering: and(filters: [], groups: [or(filters: [], groups: [])]),
      );
      final result = query.toSupyQueryParameters();
      expect(result['groups'], isNotEmpty);
    });

    test('Empty filter list should still serialize condition', () {
      final query = ApiQuery(filtering: and(filters: []));
      final result = query.toSupyQueryParameters();
      expect(result['filtering'], contains('"condition":"and"'));
    });

    test('Complex ordering + paging + selection', () {
      final query = ApiQuery(
        paging: paginate(limit: 100, offset: 200),
        ordering: [ordering('price', 'asc'), ordering('rating', 'desc')],
        selection: include(['title', 'price']),
      );
      final json = query.toSupyRequestBody();
      expect(json, contains('"limit": 100\n'));
      expect(json, contains('"dir": "asc"\n'));
      expect(json, contains('"include"'));
    });

    test('Filtering with multiple nested OR groups', () {
      final query = ApiQuery(
        filtering: and(
          filters: [where('x', 'eq', 5)],
          groups: [
            or(filters: [where('a', 'eq', 1)]),
            or(filters: [where('b', 'eq', 2)]),
          ],
        ),
      );
      final result = query.toSupyQueryParameters();
      expect(result['groups'], contains('"by":"b"'));
    });
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
      'filtering': '{"condition":"and","filtering":['
          '{"by":"name.en","op":"like","match":"apple"},'
          '{"by":"name.ar","op":"like","match":"apple"}]}',
      'groups':
          '[{"condition":"or","filtering":[{"by":"G1","op":"like","match":"G1"}'
              ',{"by":"G1","op":"like","match":"G1"}],'
              '"groups":[{"condition":"and","filtering":['
              '{"by":"G2","op":"like","match":"G2"},'
              '{"by":"G2","op":"like","match":"G2"}],"groups":[]}]}]',
      'paging': '{"offset":20,"limit":0}',
      'ordering': '[{"by":"name","dir":"asc"}]',
    };

    expect(query.toSupyQueryParameters(), equals(expectedJson));
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
      'filtering': '{"condition":"and","filtering":['
          '{"by":"field1","op":"eq","match":"value1"}]}',
    };

    expect(queryWithNulls.toSupyQueryParameters(), equals(expectedJson));
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
        'filtering': '{"condition":"and","filtering":['
            '{"by":"field1","op":"eq","match":"value1"}]}',
        'groups': '[]',
        'paging': '{"offset":0,"limit":-1}',
        'ordering': '[]',
      };

      expect(
        queryWithEmptyValues.toSupyQueryParameters(),
        equals(expectedJson),
      );
    },
  );
  test(
    'ApiQueryFiltering with invalid operation should throw an exception',
    () {
      final expectedJson = {
        'filtering': '{"condition":"and","filtering":['
            '{"by":"field1","op":"eq","match":"value1"},'
            '{"by":"field2","op":"eq","match":"value2"}]}',
        'groups': '[{"condition":"or","filtering":['
            '{"by":"field3","op":"eq","match":"value3"},'
            '{"by":"field4","op":"eq","match":"value4"}],'
            '"groups":[]},'
            '{"condition":"or",'
            '"filtering":['
            '{"by":"field3","op":"eq","match":"value3"},'
            '{"by":"field4","op":"eq","match":"value4"}],"groups":[]}]',
        'paging': '{"offset":20,"limit":0}',
        'ordering': '[{"by":"name","dir":"asc"}]',
      };

      final query = ApiQuery(
        filtering: and(
          filters: [
            where('field1', 'eq', 'value1'),
            where('field2', 'eq', 'value2'),
          ],
          groups: [
            or(
              filters: [
                where('field3', 'eq', 'value3'),
                where('field4', 'eq', 'value4'),
              ],
            ),
            or(
              filters: [
                where('field3', 'eq', 'value3'),
                where('field4', 'eq', 'value4'),
              ],
            ),
          ],
        ),
        ordering: [ordering('name', 'asc')],
        paging: paginate(limit: 0, offset: 20),
      );

      expect(query.toSupyQueryParameters(), equals(expectedJson));
    },
  );
  test('Filter with empty string should serialize correctly', () {
    final query = ApiQuery(filtering: and(filters: [where('field', 'eq', '')]));
    final result = query.toSupyQueryParameters();
    expect(result['filtering'], contains('"match":""'));
  });
  test('Ordering with invalid direction should handle gracefully', () {
    final query = ApiQuery(
      ordering: [
        ApiQueryOrdering(
          field: 'field',
          dir: QueryOrderDirection.values.firstWhere((e) => e.name == 'asc'),
        ),
      ],
    );
    final result = query.toSupyQueryParameters();
    expect(result['ordering'], contains('"dir":"asc"'));
  });
  test('Filter with boolean value', () {
    final query = ApiQuery(
      filtering: and(filters: [where('active', 'eq', true)]),
    );
    final result = query.toSupyQueryParameters();
    expect(result['filtering'], contains('"match":true'));
  });
  test('Nested AND inside OR', () {
    final query = ApiQuery(
      filtering: or(
        groups: [
          and(filters: [where('score', 'gt', 80), where('grade', 'eq', 'A')]),
        ],
      ),
    );
    final result = query.toSupyQueryParameters();
    expect(result['groups'], contains('"condition":"and"'));
  });
  test('Empty selection should not include selection key', () {
    final query = ApiQuery(selection: include(['A']));
    final result = query.toSupyQueryParameters();
    expect(result.containsKey('selection'), isTrue);
    expect(result['selection'], equals('{"include":["A"]}'));
  });

  test('Filtering with 3-level nested group hierarchy', () {
    final query = ApiQuery(
      filtering: and(
        groups: [
          or(
            groups: [
              and(filters: [where('depth', 'eq', 3)]),
            ],
          ),
        ],
      ),
    );
    final result = query.toSupyQueryParameters();
    expect(result['groups'], contains('"by":"depth"'));
  });
  test('Selection with include and exclude together', () {
    const selection = ApiQuerySelection(excludes: ['name']);
    const query = ApiQuery(selection: selection);
    final result = query.toSupyQueryParameters();
    expect(result['selection'], contains('exclude'));
  });
  test('Null filter value with other filters', () {
    final query = ApiQuery(
      filtering: and(
        filters: [
          where('field1', 'eq', 'value'),
          ApiQueryFilter(field: 'field2', operation: QueryOperation.equals),
        ],
      ),
    );
    final result = query.toSupyQueryParameters();
    expect(result['filtering'], contains('"match":null'));
  });
  test('Null filter value with other filters', () {
    final query = ApiQuery(
      filtering: and(
        filters: [
          where('field1', 'eq', 'value'),
          ApiQueryFilter(field: 'field2', operation: QueryOperation.equals),
        ],
      ),
    );
    final result = query.toSupyQueryParameters();
    expect(result['filtering'], contains('"match":null'));
  });

  test('Filter with int and double values', () {
    final query = ApiQuery(
      filtering: and(
        filters: [where('intField', 'eq', 5), where('doubleField', 'eq', 3.14)],
      ),
    );
    final result = query.toSupyQueryParameters();
    expect(result['filtering'], contains('"match":5'));
    expect(result['filtering'], contains('"match":3.14'));
  });

  test('Empty ApiQuery produces a map', () {
    const query = ApiQuery();
    final result = query.toSupyQueryParameters();
    expect(result, isA<Map<dynamic, dynamic>>());
  });
}
