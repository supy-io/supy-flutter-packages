import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryTools', () {
    test(
      'ApiQueryFiltering with invalid operation should throw an exception',
      () {
        final expectedJson = {
          'filtering': {
            'condition': 'and',
            'filters': [
              {'field': 'field1', 'operation': 'equals', 'value': 'value1'},
              {'field': 'field2', 'operation': 'equals', 'value': 'value2'},
            ],
            'groups': [
              {
                'condition': 'or',
                'filters': [
                  {'field': 'field3', 'operation': 'equals', 'value': 'value3'},
                  {'field': 'field4', 'operation': 'equals', 'value': 'value4'},
                ],
                'groups': <dynamic>[],
              },
              {
                'condition': 'or',
                'filters': [
                  {'field': 'field3', 'operation': 'equals', 'value': 'value3'},
                  {'field': 'field4', 'operation': 'equals', 'value': 'value4'},
                ],
                'groups': <dynamic>[],
              },
            ],
          },
          'paging': {'offset': 20, 'limit': 0},
          'ordering': [
            {'field': 'name', 'dir': 'asc'},
          ],
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

        expect(query.toMap(), equals(expectedJson));
      },
    );
    test('offset function should modify offset in IApiQuery', () {
      // Arrange
      final originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [],
        ),
        paging: const ApiQueryPaging(offset: 0, limit: 10),
      );

      // Act
      final modifiedQuery = offset(originalQuery, offset: 5);

      // Assert
      expect(modifiedQuery.paging?.offset, equals(5));
      expect(modifiedQuery.paging?.limit, equals(10));
    });

    test('limit function should modify limit in IApiQuery', () {
      // Arrange
      final originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [],
        ),
        paging: const ApiQueryPaging(offset: 0, limit: 10),
      );

      // Act
      final modifiedQuery = limit(originalQuery, limit: 20);

      // Assert
      expect(modifiedQuery.paging?.offset, equals(0));
      expect(modifiedQuery.paging?.limit, equals(20));
    });

    test('ExApiQuery setLimit method should modify limit in IApiQuery', () {
      // Arrange
      IApiQuery originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [],
        ),
        paging: const ApiQueryPaging(offset: 0, limit: 10),
      );

      // Act
      originalQuery = originalQuery.setLimit(15);

      // Assert
      expect(originalQuery.paging?.offset, equals(0));
      expect(originalQuery.paging?.limit, equals(15));
    });

    test('ExApiQuery setOffset method should modify offset in IApiQuery', () {
      // Arrange
      IApiQuery originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filters: [],
        ),
        paging: const ApiQueryPaging(offset: 0, limit: 10),
      );

      // Act
      originalQuery = originalQuery.setOffset(5);

      // Assert
      expect(originalQuery.paging?.offset, equals(5));
      expect(originalQuery.paging?.limit, equals(10));
    });
  });
}
