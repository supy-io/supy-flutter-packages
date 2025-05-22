import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('Paging helpers', () {
    test('takeOne returns paging with limit 1 and offset 0', () {
      final paging = takeOne();
      expect(paging.limit, 1);
      expect(paging.offset, 0);
      expect(paging.cursor, isNull);
    });

    test('paginate returns paging with provided parameters', () {
      final paging = paginate(limit: 5, offset: 10, cursor: 'cursor123');
      expect(paging.limit, 5);
      expect(paging.offset, 10);
      expect(paging.cursor, 'cursor123');
    });

    test('noLimit returns paging with no limit set', () {
      final paging = noLimit();
      expect(paging.limit, isNull);
      expect(paging.offset, isNull);
      expect(paging.cursor, isNull);
    });
  });

  group('Filter group helpers', () {
    test('or creates group with OR condition', () {
      final group = or();
      expect(group.condition, FilterConditionType.or);
      expect(group.filters, isEmpty);
      expect(group.groups, isEmpty);

      final filters = [where('field', 'eq', 1)];
      final groups = [and()];
      final groupWithParams = or(filters: filters, groups: groups);
      expect(groupWithParams.condition, FilterConditionType.or);
      expect(groupWithParams.filters, filters);
      expect(groupWithParams.groups, groups);
    });

    test('and creates group with AND condition', () {
      final group = and();
      expect(group.condition, FilterConditionType.and);
      expect(group.filters, isEmpty);
      expect(group.groups, isEmpty);
    });

    test('not creates group with NOT condition', () {
      final group = not();
      expect(group.condition, FilterConditionType.not);
      expect(group.filters, isEmpty);
      expect(group.groups, isEmpty);
    });
  });

  group('Filter helpers', () {
    test('where creates filter with single value', () {
      final filter = where('status', 'eq', 'active');
      expect(filter.field, 'status');
      expect(filter.operation, QueryOperation.equals);
      expect(filter.value, 'active');
      expect(filter.values, isNull);
    });

    test('wheres creates filter with multiple values', () {
      final filter = wheres('status', 'in', ['active', 'pending']);
      expect(filter.field, 'status');
      expect(filter.operation, QueryOperation.inList);
      expect(filter.values, ['active', 'pending']);
      expect(filter.value, isNull);
    });
  });

  group('Ordering helper', () {
    test('ordering creates ordering with correct field and direction', () {
      final orderAsc = ordering('createdAt', 'asc');
      expect(orderAsc.field, 'createdAt');
      expect(orderAsc.dir, QueryOrderDirection.asc);

      final orderDesc = ordering('updatedAt', 'descend');
      expect(orderDesc.field, 'updatedAt');
      expect(orderDesc.dir, QueryOrderDirection.desc);
    });
  });

  group('Selection helpers', () {
    test('exclude creates selection with excludes set', () {
      final selection = exclude(['password', 'secret']);
      expect(selection.excludes, ['password', 'secret']);
      expect(selection.includes, isNull);
    });

    test('include creates selection with includes set', () {
      final selection = include(['id', 'name']);
      expect(selection.includes, ['id', 'name']);
      expect(selection.excludes, isNull);
    });
  });
}
