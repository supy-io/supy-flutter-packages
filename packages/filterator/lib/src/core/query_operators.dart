import 'package:filterator/src/core/query_filter.dart';
import 'package:filterator/src/core/query_filter_group.dart';
import 'package:filterator/src/core/query_operation.dart';
import 'package:filterator/src/core/query_ordering.dart';
import 'package:filterator/src/core/query_paging.dart';
import 'package:filterator/src/core/query_selections.dart';

/// Returns a paging configuration that fetches a single item.
///
/// This is typically used when you want to retrieve only the first result
/// from an API list response.
IApiQueryPaging takeOne() => const ApiQueryPaging(limit: 1, offset: 0);

/// Creates a custom pagination configuration.
///
/// Use this when you need to define specific offset-based or cursor-based
/// pagination settings for API queries.
///
/// - [offset]: Number of items to skip (optional).
/// - [limit]: Maximum number of items to fetch.
/// - [cursor]: Optional cursor token for cursor-based pagination.
IApiQueryPaging paginate({required int limit, int? offset, String? cursor}) =>
    ApiQueryPaging(limit: limit, offset: offset, cursor: cursor);

/// Returns a paging configuration with no limit.
///
/// This configuration is useful when you want to retrieve all records
/// without enforcing a pagination limit.
IApiQueryPaging noLimit() => ApiQueryPaging.noLimit();

/// Constructs a filtering group with an `OR` logical condition.
///
/// This is useful when at least one condition from a list should be satisfied.
///
/// - [filters]: List of individual field filters (optional).
/// - [groups]: List of nested filter groups (optional).
IApiQueryFilteringGroup or({
  List<IApiQueryFilter>? filters,
  List<IApiQueryFilteringGroup>? groups,
}) {
  return ApiQueryFilteringGroup(
    condition: FilterConditionType.or,
    filtering: filters ?? [],
    groups: groups ?? [],
  );
}

/// Constructs a filtering group with an `AND` logical condition.
///
/// This is useful when all conditions in the list must be satisfied.
///
/// - [filters]: List of individual field filters (optional).
/// - [groups]: List of nested filter groups (optional).
IApiQueryFilteringGroup and({
  List<IApiQueryFilter>? filters,
  List<IApiQueryFilteringGroup>? groups,
}) {
  return ApiQueryFilteringGroup(
    condition: FilterConditionType.and,
    filtering: filters ?? [],
    groups: groups ?? [],
  );
}

/// Constructs a filtering group with a `NOT` logical condition.
///
/// This is useful to negate one or more filters or filter groups.
///
/// - [filters]: List of individual field filters (optional).
/// - [groups]: List of nested filter groups (optional).
IApiQueryFilteringGroup not({
  List<IApiQueryFilter>? filters,
  List<IApiQueryFilteringGroup>? groups,
}) {
  return ApiQueryFilteringGroup(
    condition: FilterConditionType.not,
    filtering: filters ?? [],
    groups: groups ?? [],
  );
}

/// Creates a field-based filter for a single value.
///
/// Example:
/// ```dart
/// where('status', 'eq', 'active')
/// ```
///
/// - [by]: The field to filter on.
/// - [op]: The string representation of the operation (e.g., 'eq', 'gt').
/// - [match]: The single value to compare against.
IApiQueryFilter where(String by, String op, Object match) {
  return ApiQueryFilter(
    field: by,
    operation: op.toQueryOperation(),
    value: match,
  );
}

/// Creates a field-based filter for multiple values (e.g., `in`, `not_in`).
///
/// Example:
/// ```dart
/// wheres('status', 'in', ['active', 'pending'])
/// ```
///
/// - [by]: The field to filter on.
/// - [op]: The string representation of the operation.
/// - [match]: A list of values to compare against.
IApiQueryFilter wheres(String by, String op, List<Object> match) {
  return ApiQueryFilter(
    field: by,
    operation: op.toQueryOperation(),
    values: match,
  );
}

/// Specifies ordering criteria for a query result.
///
/// Example:
/// ```dart
/// ordering('createdAt', 'desc')
/// ```
///
/// - [by]: The field to sort by.
/// - [dir]: The direction of sorting ('asc' or 'desc').
IApiQueryOrdering ordering(String by, String dir) {
  return ApiQueryOrdering(field: by, dir: dir.toQueryOrderDirection());
}

/// Specifies fields to exclude from the API response.
///
/// Use this to reduce payload size by excluding unnecessary fields.
///
/// - [excludes]: List of field names to exclude.
IApiQuerySelection exclude(List<String> excludes) {
  return ApiQuerySelection(excludes: excludes);
}

/// Specifies fields to include in the API response.
///
/// Use this to explicitly request only the necessary fields.
///
/// - [includes]: List of field names to include.
IApiQuerySelection include(List<String> includes) {
  return ApiQuerySelection(includes: includes);
}
