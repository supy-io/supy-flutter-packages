import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryPaging', () {
    test('ApiQueryPaging toMap should produce correct JSON', () {
      const paging = ApiQueryPaging(offset: 10, limit: 5);

      final expectedJson = {'offset': 10, 'limit': 5};

      expect(paging.toMap(), equals(expectedJson));
    });
    test('constructor sets offset, limit, and cursor correctly', () {
      const paging = ApiQueryPaging(offset: 10, limit: 25, cursor: 'abc123');

      expect(paging.offset, 10);
      expect(paging.limit, 25);
      expect(paging.cursor, 'abc123');
    });

    test('noLimit factory creates correct instance', () {
      final paging = ApiQueryPaging.noLimit();

      expect(paging.offset, ApiQueryPaging.kNoOffset);
      expect(paging.limit, ApiQueryPaging.kNoLimit);
      expect(paging.cursor, isNull);
    });

    test('cursorBased constructor sets cursor and limit correctly', () {
      const paging = ApiQueryPaging.cursorBased(limit: 50, cursor: 'cursorX');

      expect(paging.offset, isNull);
      expect(paging.limit, 50);
      expect(paging.cursor, 'cursorX');
    });

    test('copyWith updates values correctly', () {
      const original = ApiQueryPaging(offset: 5, limit: 20, cursor: 'cursor1');

      final copy = original.copyWith(offset: 10);
      expect(copy.offset, 10);
      expect(copy.limit, 20);
      expect(copy.cursor, 'cursor1');

      final copy2 = original.copyWith(limit: 30, cursor: 'cursor2');
      expect(copy2.offset, 5);
      expect(copy2.limit, 30);
      expect(copy2.cursor, 'cursor2');
    });

    test('toMap returns correct map representation', () {
      const paging = ApiQueryPaging(offset: 7, limit: 15, cursor: 'abc');
      final map = paging.toMap();

      expect(map, {'cursor': 'abc', 'offset': 7, 'limit': 15});

      const pagingNoCursor = ApiQueryPaging(offset: 1, limit: 10);
      final mapNoCursor = pagingNoCursor.toMap();

      expect(mapNoCursor, {'offset': 1, 'limit': 10});
    });
  });

  group('cloneApiQueryPaging', () {
    test('clone creates a new identical instance', () {
      const original = ApiQueryPaging(offset: 3, limit: 50, cursor: 'cursorX');
      final cloned = cloneApiQueryPaging(original);

      expect(
        cloned,
        isNot(same(original)),
        reason: 'Clone should be a different instance',
      );
      expect(cloned.offset, original.offset);
      expect(cloned.limit, original.limit);
      expect(cloned.cursor, original.cursor);
    });
  });
}
