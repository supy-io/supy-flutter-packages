import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ODataConverter', () {
    test('converts simple equals filter', () {
      final filter = MockFilter(
        field: 'Name',
        operation: QueryOperation.equals,
        value: 'John',
      );
      final group = MockFilteringGroup(
        filtering: [filter],
        groups: null,
        condition: FilterConditionType.and,
      );
      final query = MockApiQuery(
        filtering: group,
        ordering: null,
        paging: null,
      );
      final converter = ODataConverter(query);

      final params = converter.toQueryParameters();

      expect(params[r'$filter'], "(Name eq 'John')");
    });

    test('converts ordering', () {
      final ordering = [
        MockOrdering(field: 'Age', dir: QueryOrderDirection.desc),
      ];
      final query = MockApiQuery(
        filtering: null,
        ordering: ordering,
        paging: null,
      );
      final converter = ODataConverter(query);

      final params = converter.toQueryParameters();

      expect(params[r'$orderby'], 'Age desc');
    });

    test('converts paging with limit and offset', () {
      final paging = MockPaging(limit: 10, offset: 5, cursor: null);
      final query = MockApiQuery(
        filtering: null,
        ordering: null,
        paging: paging,
      );
      final converter = ODataConverter(query);

      final params = converter.toQueryParameters();

      expect(params[r'$top'], '10');
      expect(params[r'$skip'], '5');
    });

    test('throws UnsupportedError on cursor-based paging', () {
      final paging = MockPaging(limit: 10, offset: null, cursor: 'cursor123');
      final query = MockApiQuery(
        filtering: null,
        ordering: null,
        paging: paging,
      );
      final converter = ODataConverter(query);

      expect(() => converter.toQueryParameters(), throwsUnsupportedError);
    });

    test('toRequestBody outputs JSON string', () {
      final filter = MockFilter(
        field: 'IsActive',
        operation: QueryOperation.equals,
        value: true,
      );
      final group = MockFilteringGroup(
        filtering: [filter],
        groups: null,
        condition: FilterConditionType.and,
      );
      final paging = MockPaging(limit: 5, offset: 0, cursor: null);
      final ordering = [
        MockOrdering(field: 'CreatedAt', dir: QueryOrderDirection.asc),
      ];
      final query = MockApiQuery(
        filtering: group,
        ordering: ordering,
        paging: paging,
      );
      final converter = ODataConverter(query);

      final body = converter.toRequestBody();

      expect(body, contains(r'"$filter"'));
      expect(body, contains(r'"$orderby"'));
      expect(body, contains(r'"$top"'));
      expect(body, contains(r'"$skip"'));
    });
  });

  test('handles and/or groups', () {
    final filter1 = MockFilter(
      field: 'A',
      operation: QueryOperation.equals,
      value: 1,
    );
    final filter2 = MockFilter(
      field: 'B',
      operation: QueryOperation.equals,
      value: 2,
    );
    final group = MockFilteringGroup(
      condition: FilterConditionType.and,
      filtering: [filter1],
      groups: [
        MockFilteringGroup(
          filtering: [filter2],
          groups: null,
          condition: FilterConditionType.or,
        ),
      ],
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final filterParam = converter.toQueryParameters()[r'$filter'];
    expect(filterParam, "(A eq 1 and (B eq 2))");
  });

  test('throws on NOT with multiple filters', () {
    final group = MockFilteringGroup(
      filtering: [
        MockFilter(field: 'A', operation: QueryOperation.equals, value: 1),
        MockFilter(field: 'B', operation: QueryOperation.equals, value: 2),
      ],
      groups: null,
      condition: FilterConditionType.not,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    expect(() => converter.toQueryParameters(), throwsFormatException);
  });

  test('inList and notIn are rendered correctly (OData v4)', () {
    final inFilter = MockFilter(
      field: 'status',
      operation: QueryOperation.inList,
      values: ['active', 'pending'],
    );
    final notInFilter = MockFilter(
      field: 'type',
      operation: QueryOperation.notIn,
      values: ['admin', 'guest'],
    );
    final group = MockFilteringGroup(
      filtering: [inFilter, notInFilter],
      groups: null,
      condition: FilterConditionType.and,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final filter = converter.toQueryParameters()[r'$filter'];
    expect(filter, contains("status in ('active','pending')"));
    expect(filter, contains("not(type in ('admin','guest'))"));
  });

  test('indexOf operation is handled with custom operator', () {
    final filter = MockFilter(
      field: 'name',
      operation: QueryOperation.indexOf,
      value: 0,
    );
    final group = MockFilteringGroup(
      filtering: [filter],
      groups: null,
      condition: FilterConditionType.and,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final result = converter.toQueryParameters()[r'$filter'];
    expect(result, contains("indexof(name, 0) eq"));
  });

  test('length, substring, datePart, mathOp', () {
    final filters = [
      MockFilter(field: 'name', operation: QueryOperation.length, value: 5),
      MockFilter(
        field: 'title',
        operation: QueryOperation.substring,
        value: 'abc',
        values: [0, 3],
      ),
      MockFilter(
        field: 'birthdate',
        operation: QueryOperation.datePart,
        value: 1990,
        values: ['year'],
      ),
      MockFilter(
        field: 'price',
        operation: QueryOperation.mathOp,
        value: 20,
        values: ['round'],
      ),
    ];
    final group = MockFilteringGroup(
      filtering: filters,
      groups: null,
      condition: FilterConditionType.and,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final filterStr = converter.toQueryParameters()[r'$filter'];
    expect(filterStr, contains("length(name) eq 5"));
    expect(filterStr, contains("substring(title, 0, 3) eq 'abc'"));
    expect(filterStr, contains("year(birthdate) eq 1990"));
    expect(filterStr, contains("round(price) eq 20"));
  });

  test('any and all lambda filters', () {
    final innerFilter = MockFilter(
      field: 'score',
      operation: QueryOperation.greaterThan,
      value: 50,
    );
    final anyFilter = MockFilter(
      field: 'results',
      operation: QueryOperation.any,
      values: ['r', innerFilter],
    );
    final allFilter = MockFilter(
      field: 'results',
      operation: QueryOperation.all,
      values: ['r', innerFilter],
    );
    final group = MockFilteringGroup(
      filtering: [anyFilter, allFilter],
      groups: null,
      condition: FilterConditionType.and,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final result = converter.toQueryParameters()[r'$filter'];
    expect(result, contains("results/any(r: r/score gt 50)"));
    expect(result, contains("results/all(r: r/score gt 50)"));
  });

  test('formatValue handles all supported types', () {
    final now = DateTime.utc(2020, 1, 1, 12, 30, 45);
    final duration = Duration(minutes: 5);

    final tests = <IApiQueryFilter>[
      MockFilter(
        field: 'StringField',
        operation: QueryOperation.equals,
        value: 'hello',
      ),
      MockFilter(
        field: 'StringWithQuote',
        operation: QueryOperation.equals,
        value: "O'Reilly",
      ),
      MockFilter(
        field: 'NumberField',
        operation: QueryOperation.equals,
        value: 123,
      ),
      MockFilter(
        field: 'DoubleField',
        operation: QueryOperation.equals,
        value: 123.45,
      ),
      MockFilter(
        field: 'BooleanTrue',
        operation: QueryOperation.equals,
        value: true,
      ),
      MockFilter(
        field: 'BooleanFalse',
        operation: QueryOperation.equals,
        value: false,
      ),
      MockFilter(
        field: 'DateField',
        operation: QueryOperation.equals,
        value: now,
      ),
      MockFilter(
        field: 'DurationField',
        operation: QueryOperation.equals,
        value: duration,
      ),
      MockFilter(
        field: 'NullField',
        operation: QueryOperation.equals,
        value: null,
      ),
    ];

    for (final filter in tests) {
      final query = MockApiQuery(
        filtering: MockFilteringGroup(
          filtering: [filter],
          groups: null,
          condition: FilterConditionType.and,
        ),
        ordering: null,
        paging: null,
      );
      final converter = ODataConverter(query);
      final params = converter.toQueryParameters();

      expect(
        params[r'$filter'],
        isNotEmpty,
        reason: 'Filter should not be empty for ${filter.field}',
      );
      expect(
        params[r'$filter'],
        contains(filter.field),
        reason: 'Should contain field ${filter.field}',
      );
    }
  });

  test('nested groups with mixed AND/OR/NOT conditions', () {
    final filter1 = MockFilter(
      field: 'X',
      operation: QueryOperation.equals,
      value: 1,
    );
    final filter2 = MockFilter(
      field: 'Y',
      operation: QueryOperation.equals,
      value: 2,
    );
    final filter3 = MockFilter(
      field: 'Z',
      operation: QueryOperation.equals,
      value: 3,
    );

    final innerOr = MockFilteringGroup(
      filtering: [filter2, filter3],
      groups: null,
      condition: FilterConditionType.or,
    );

    final outerGroup = MockFilteringGroup(
      filtering: [filter1],
      groups: [innerOr],
      condition: FilterConditionType.and,
    );

    final query = MockApiQuery(
      filtering: outerGroup,
      ordering: null,
      paging: null,
    );
    final converter = ODataConverter(query);
    final result = converter.toQueryParameters()[r'$filter'];

    expect(result, "(X eq 1 and (Y eq 2 or Z eq 3))");
  });

  test('handles special characters in string values', () {
    final filter = MockFilter(
      field: 'Note',
      operation: QueryOperation.equals,
      value: "O'Reilly & Sons",
    );
    final group = MockFilteringGroup(
      filtering: [filter],
      groups: null,
      condition: FilterConditionType.and,
    );
    final query = MockApiQuery(filtering: group, ordering: null, paging: null);
    final converter = ODataConverter(query);

    final filterStr = converter.toQueryParameters()[r'$filter'];

    expect(filterStr, contains("Note eq 'O''Reilly & Sons'"));
  });

  test('gracefully handles unsupported operation', () {
    final unsupportedOp = QueryOperation.values.last; // or any you want

    final filter = MockFilter(
      field: 'UnsupportedField',
      operation: unsupportedOp,
      value: 'foo',
    );

    final query = MockApiQuery(
      filtering: MockFilteringGroup(
        filtering: [filter],
        groups: null,
        condition: FilterConditionType.and,
      ),
      ordering: null,
      paging: null,
    );

    final converter = ODataConverter(query);
    final result = converter.toQueryParameters();

    expect(
      result[r'$filter'],
      contains('ne null'),
    ); // or whatever your fallback is
  });
}

// Mock classes to simulate dependencies

class MockFilter implements IApiQueryFilter {
  @override
  final String field;
  @override
  final QueryOperation operation;
  @override
  final dynamic value;
  @override
  final List<dynamic>? values;

  MockFilter({
    required this.field,
    required this.operation,
    this.value,
    this.values,
  });

  @override
  IApiQueryFilter clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class MockFilteringGroup<T> implements IApiQueryFilteringGroup<T> {
  @override
  final List<IApiQueryFilter> filtering;
  @override
  final List<IApiQueryFilteringGroup<T>>? groups;
  @override
  final FilterConditionType condition;

  MockFilteringGroup({
    required this.filtering,
    this.groups,
    required this.condition,
  });

  @override
  clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class MockOrdering implements IApiQueryOrdering {
  @override
  final String field;
  @override
  final QueryOrderDirection dir;

  MockOrdering({required this.field, required this.dir});

  @override
  ApiQueryOrdering clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class MockPaging implements IApiQueryPaging {
  @override
  final int limit;
  @override
  final int? offset;
  @override
  final String? cursor;

  MockPaging({required this.limit, this.offset, this.cursor});

  @override
  ApiQueryPaging clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  IApiQueryPaging copyWith({int? offset, int? limit}) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}

class MockApiQuery<T> implements ApiQuery<T> {
  @override
  final IApiQueryFilteringGroup<T>? filtering;
  @override
  final List<IApiQueryOrdering>? ordering;
  @override
  final IApiQueryPaging? paging;

  MockApiQuery({this.filtering, this.ordering, this.paging});

  @override
  ApiQuery<T> clone() {
    // TODO: implement clone
    throw UnimplementedError();
  }

  @override
  ApiQuery<T> copyWith({
    IApiQueryFilteringGroup<T>? filtering,
    List<IApiQueryOrdering>? ordering,
    IApiQueryPaging? paging,
    IApiQuerySelection? selection,
  }) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  // TODO: implement selection
  IApiQuerySelection? get selection => throw UnimplementedError();

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}
