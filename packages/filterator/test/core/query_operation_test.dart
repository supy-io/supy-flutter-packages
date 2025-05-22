import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('QueryOperationStringExtension', () {
    test('valid strings convert to correct QueryOperation', () {
      expect('eq'.toQueryOperation(), QueryOperation.equals);
      expect('equals'.toQueryOperation(), QueryOperation.equals);
      expect('neq'.toQueryOperation(), QueryOperation.notEquals);
      expect('notequals'.toQueryOperation(), QueryOperation.notEquals);
      expect('in'.toQueryOperation(), QueryOperation.inList);
      expect('inlist'.toQueryOperation(), QueryOperation.inList);
      expect('not-in'.toQueryOperation(), QueryOperation.notIn);
      expect('notin'.toQueryOperation(), QueryOperation.notIn);
      expect('contains'.toQueryOperation(), QueryOperation.contains);
      expect('contains-any'.toQueryOperation(), QueryOperation.containsAny);
      expect('contains-all'.toQueryOperation(), QueryOperation.containsAll);
      expect('not-contains'.toQueryOperation(), QueryOperation.notContains);
      expect('starts-with'.toQueryOperation(), QueryOperation.startsWith);
      expect('startswith'.toQueryOperation(), QueryOperation.startsWith);
      expect('ends-with'.toQueryOperation(), QueryOperation.endsWith);
      expect('endswith'.toQueryOperation(), QueryOperation.endsWith);
      expect('gt'.toQueryOperation(), QueryOperation.greaterThan);
      expect('greaterthan'.toQueryOperation(), QueryOperation.greaterThan);
      expect('lt'.toQueryOperation(), QueryOperation.lessThan);
      expect('lessthan'.toQueryOperation(), QueryOperation.lessThan);
      expect('gte'.toQueryOperation(), QueryOperation.greaterOrEqual);
      expect(
        'greaterorequal'.toQueryOperation(),
        QueryOperation.greaterOrEqual,
      );
      expect('lte'.toQueryOperation(), QueryOperation.lessOrEqual);
      expect('lessorequal'.toQueryOperation(), QueryOperation.lessOrEqual);
      expect('isnull'.toQueryOperation(), QueryOperation.isNull);
      expect('isnotnull'.toQueryOperation(), QueryOperation.isNotNull);
      expect('like'.toQueryOperation(), QueryOperation.like);
      expect('search'.toQueryOperation(), QueryOperation.search);
    });

    test('invalid string throws ArgumentError', () {
      expect(() => 'invalid'.toQueryOperation(), throwsArgumentError);
      expect(() => ''.toQueryOperation(), throwsArgumentError);
      expect(() => 'eqx'.toQueryOperation(), throwsArgumentError);
    });
  });

  group('QueryOperationExtension', () {
    test('toShortQueryOperation returns correct shorthand', () {
      expect(QueryOperation.equals.toShortQueryOperation(), 'eq');
      expect(QueryOperation.notEquals.toShortQueryOperation(), 'neq');
      expect(QueryOperation.inList.toShortQueryOperation(), 'in');
      expect(QueryOperation.notIn.toShortQueryOperation(), 'not-in');
      expect(QueryOperation.contains.toShortQueryOperation(), 'contains');
      expect(
        QueryOperation.containsAny.toShortQueryOperation(),
        'contains-any',
      );
      expect(
        QueryOperation.containsAll.toShortQueryOperation(),
        'contains-all',
      );
      expect(
        QueryOperation.notContains.toShortQueryOperation(),
        'not-contains',
      );
      expect(QueryOperation.startsWith.toShortQueryOperation(), 'starts-with');
      expect(QueryOperation.endsWith.toShortQueryOperation(), 'ends-with');
      expect(QueryOperation.greaterThan.toShortQueryOperation(), 'gt');
      expect(QueryOperation.lessThan.toShortQueryOperation(), 'lt');
      expect(QueryOperation.greaterOrEqual.toShortQueryOperation(), 'gte');
      expect(QueryOperation.lessOrEqual.toShortQueryOperation(), 'lte');
      expect(QueryOperation.isNull.toShortQueryOperation(), 'is-null');
      expect(QueryOperation.isNotNull.toShortQueryOperation(), 'is-not-null');
      expect(QueryOperation.like.toShortQueryOperation(), 'like');
      expect(QueryOperation.search.toShortQueryOperation(), 'search');
    });
  });

  group('QueryOrderDirectionExtension', () {
    test('valid strings convert to QueryOrderDirection.asc', () {
      expect('asc'.toQueryOrderDirection(), QueryOrderDirection.asc);
      expect('ascending'.toQueryOrderDirection(), QueryOrderDirection.asc);
      expect('ascend'.toQueryOrderDirection(), QueryOrderDirection.asc);
    });

    test('valid strings convert to QueryOrderDirection.desc', () {
      expect('desc'.toQueryOrderDirection(), QueryOrderDirection.desc);
      expect('descending'.toQueryOrderDirection(), QueryOrderDirection.desc);
      expect('descend'.toQueryOrderDirection(), QueryOrderDirection.desc);
    });

    test('invalid string throws ArgumentError', () {
      expect(() => 'invalid'.toQueryOrderDirection(), throwsArgumentError);
      expect(() => ''.toQueryOrderDirection(), throwsArgumentError);
      expect(() => 'up'.toQueryOrderDirection(), throwsArgumentError);
    });
  });
}
