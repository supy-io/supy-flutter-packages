import 'package:querycraft/querycraft.dart';
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
      filtering: [],
      groups: [],
    );

    final expectedJson = {
      'filtering': '{"condition":"and","filtering":[],"groups":[]}',
    };

    expect(emptyGroup.toMap(), equals(expectedJson));
  });
  test('ApiQueryFiltering toMap should produce correct JSON', () {
    final filtering = ApiQueryFiltering(
      by: 'name.en',
      op: QueryOperation.like,
      match: 'apple',
    );

    final expectedJson = {'by': 'name.en', 'op': 'like', 'match': 'apple'};

    expect(filtering.toMap(), equals(expectedJson));
  });

  test('ApiQueryPaging toMap should produce correct JSON', () {
    const paging = ApiQueryPaging(offset: 10, limit: 5);

    final expectedJson = {'offset': 10, 'limit': 5};

    expect(paging.toMap(), equals(expectedJson));
  });

  test('ApiQueryOrdering toMap should produce correct JSON', () {
    const ordering = ApiQueryOrdering(
      by: 'name',
      dir: QueryOrderDirection.desc,
    );

    final expectedJson = {'by': 'name', 'dir': 'desc'};

    expect(ordering.toMap(), equals(expectedJson));
  });

  test('ApiQuery toMap should produce correct JSON', () {
    final query = ApiQuery(
      filtering: ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filtering: [
          ApiQueryFiltering(
            by: 'name.en',
            op: QueryOperation.like,
            match: 'apple',
          ),
          ApiQueryFiltering(
            by: 'name.ar',
            op: QueryOperation.like,
            match: 'apple',
          ),
        ],
        groups: [
          ApiQueryFilteringGroup(
            condition: FilterConditionType.or,
            filtering: [
              ApiQueryFiltering(by: 'G1', op: QueryOperation.like, match: 'G1'),
              ApiQueryFiltering(by: 'G1', op: QueryOperation.like, match: 'G1'),
            ],
            groups: [
              ApiQueryFilteringGroup(
                condition: FilterConditionType.and,
                filtering: [
                  ApiQueryFiltering(
                    by: 'G2',
                    op: QueryOperation.like,
                    match: 'G2',
                  ),
                  ApiQueryFiltering(
                    by: 'G2',
                    op: QueryOperation.like,
                    match: 'G2',
                  ),
                ],
                groups: [],
              ),
            ],
          ),
        ],
      ),
      ordering: [
        const ApiQueryOrdering(by: 'name', dir: QueryOrderDirection.asc),
      ],
      paging: const ApiQueryPaging(limit: 0, offset: 20),
    );

    final expectedJson = {
      'filtering':
          '{"condition":"and","filtering":[{"by":"name.en","op":"like","match":"apple"},{"by":"name.ar","op":"like","match":"apple"}],"groups":[{"condition":"or","filtering":[{"by":"G1","op":"like","match":"G1"},{"by":"G1","op":"like","match":"G1"}],"groups":[{"condition":"and","filtering":[{"by":"G2","op":"like","match":"G2"},{"by":"G2","op":"like","match":"G2"}],"groups":[]}]}]}',
      'paging': '{"offset":20,"limit":0}',
      'ordering': '[{"by":"name","dir":"asc"}]',
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
        filtering: [
          ApiQueryFiltering(
            by: 'field1',
            op: QueryOperation.eq,
            match: 'value1',
          ),
          ApiQueryFiltering(
            by: 'field2',
            op: QueryOperation.neq,
            match: 'value2',
          ),
        ],
        groups: [
          ApiQueryFilteringGroup(
            condition: FilterConditionType.or,
            filtering: [
              ApiQueryFiltering(
                by: 'nestedField1',
                op: QueryOperation.contains,
                match: 'nestedValue1',
              ),
              ApiQueryFiltering(
                by: 'nestedField2',
                op: QueryOperation.notContains,
                match: 'nestedValue2',
              ),
            ],
            groups: [],
          ),
        ],
      );

      final expectedJson = {
        'filtering': '{"condition":"and","filtering":[{"by":"field1","op":"eq","match":"value1"},{"by":"field2","op":"neq","match":"value2"}],"groups":[{"condition":"or","filtering":[{"by":"nestedField1","op":"contains","match":"nestedValue1"},{"by":"nestedField2","op":"not-contains","match":"nestedValue2"}],"groups":[]}]}'
      };

      expect(nestedGroup.toMap(), equals(expectedJson));
    },
  );

  test('ApiQuery with null values should produce correct JSON', () {
    final queryWithNulls = ApiQuery<String>(
      filtering: ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filtering: [
          ApiQueryFiltering(
            by: 'field1',
            op: QueryOperation.eq,
            match: 'value1',
          ),
        ],
      ),
    );

    final expectedJson = {
      'filtering': '{"condition":"and","filtering":[{"by":"field1","op":"eq","match":"value1"}],"groups":[]}'
    };

    expect(queryWithNulls.toMap(), equals(expectedJson));
  });
  test('ApiQuery with empty ordering and paging should produce correct JSON', () {
    final queryWithEmptyValues = ApiQuery<String>(
      filtering: ApiQueryFilteringGroup(
        condition: FilterConditionType.and,
        filtering: [
          ApiQueryFiltering(
            by: 'field1',
            op: QueryOperation.eq,
            match: 'value1',
          ),
        ],
        groups: [],
      ),
      ordering: [],
      paging: ApiQueryPaging.noLimit(),
    );

    final expectedJson ={
      'filtering': '{"condition":"and","filtering":[{"by":"field1","op":"eq","match":"value1"}],"groups":[]}',
      'paging': '{"offset":0,"limit":-1}',
      'ordering': '[]'
    };

    expect(queryWithEmptyValues.toMap(), equals(expectedJson));
  });

  test(
    'ApiQueryFiltering with invalid operation should throw an exception',
    () {
      expect(
        () => ApiQueryFiltering(by: 'field', op: 'invalidOp', match: 'value'),
        throwsA(isA<AssertionError>()),
      );
    },
  );
}
