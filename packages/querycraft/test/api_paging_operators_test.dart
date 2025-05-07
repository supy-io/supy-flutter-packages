import 'package:querycraft/querycraft.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryTools', () {
    test('offset function should modify offset in IApiQuery', () {
      // Arrange
      final originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup<dynamic>(
          condition: FilterConditionType.and,
          filtering: [],
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
      final originalQuery = ApiQuery<String>(
        filtering: ApiQueryFilteringGroup<String>(
          condition: FilterConditionType.and,
          filtering: [],
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
      IApiQuery<dynamic> originalQuery = ApiQuery(
        filtering: ApiQueryFilteringGroup(
          condition: FilterConditionType.and,
          filtering: [],
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
      IApiQuery<dynamic> originalQuery = ApiQuery<String>(
        filtering: ApiQueryFilteringGroup<String>(
          condition: FilterConditionType.and,
          filtering: [],
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
