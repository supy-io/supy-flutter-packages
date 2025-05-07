
import 'package:querycraft/querycraft.dart';

/// Creates a paging configuration for fetching a single item.
///
/// This function returns an [IApiQueryPaging] instance
/// with a limit of 1 and offset of 0,
/// suitable for fetching a single item from an API result.
IApiQueryPaging takeOne() => const ApiQueryPaging(limit: 1, offset: 0);

/// Creates a custom paging configuration with specified offset and limit.
///
/// This function returns an [IApiQueryPaging]
/// instance with the provided [offset] and [limit],
/// allowing for custom pagination settings in API queries.
IApiQueryPaging paginate({required int offset, required int limit}) =>
    ApiQueryPaging(limit: limit, offset: offset);

/// Creates a paging configuration indicating no limit.
///
/// This function returns an [IApiQueryPaging] instance
/// with an offset of 0 and limit of -1,
/// indicating that there is no limit on the number of items to be retrieved.
IApiQueryPaging noLimit() => ApiQueryPaging.noLimit();

/// Creates a filtering group with the OR condition.
///
/// This function returns an [IApiQueryFilteringGroup]
/// instance with the condition set to OR,
/// and includes the specified list of
/// [filters] and [groups] in the filtering configuration.
IApiQueryFilteringGroup<dynamic> or({
  List<IApiQueryFiltering>? filters,
  List<IApiQueryFilteringGroup<dynamic>>? groups,
}) {
  return ApiQueryFilteringGroup(
    condition: FilterConditionType.or,
    filtering: filters ?? [],
    groups: groups ?? [],
  );
}

/// Creates a filtering group with the AND condition.
///
/// This function returns an [IApiQueryFilteringGroup]
/// instance with the condition set to AND,
/// and includes the specified list of [filters] and [groups]
/// åin the filtering configuration.
IApiQueryFilteringGroup<dynamic> and({
  List<IApiQueryFiltering>? filters,
  List<IApiQueryFilteringGroup<dynamic>>? groups,
}) {
  return ApiQueryFilteringGroup(
    condition: FilterConditionType.and,
    filtering: filters ?? [],
    groups: groups ?? [],
  );
}

/// Creates a filtering operation for a specific field.
///
/// This function returns an [IApiQueryFiltering]
/// instance representing a filtering operation
/// on a specific field, defined by [by],
/// using the specified operation [op], and matching the
/// given [match] value.
IApiQueryFiltering where(String by, String op, Object match) {
  return ApiQueryFiltering(by: by, op: op, match: match);
}

/// Creates an ordering configuration for a specific field.
///
/// This function returns an [IApiQueryOrdering]
/// instance representing the ordering
/// configuration for a specific field [by], with the specified [dir]
/// indicating the order direction.
IApiQueryOrdering<dynamic> ordering(String by, QueryOrderDirection dir) {
  return ApiQueryOrdering(by: by, dir: dir);
}

///
IApiQuerySelection exclude(List<String> excludes) {
  return ApiQuerySelection(excludes: excludes);
}

///
IApiQuerySelection include(List<String> includes) {
  return ApiQuerySelection(includes: includes);
}
