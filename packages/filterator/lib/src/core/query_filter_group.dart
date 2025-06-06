import 'package:filterator/src/core/query_filter.dart';
import 'package:filterator/src/core/query_operation.dart';

/// Interface defining the structure of an API query filtering group.
///
/// This interface outlines how complex query filters are grouped, including:
/// - nested filtering groups (`groups`)
/// - individual field filters (`filters`)
/// - the condition (`AND`, `OR`, `NOT`) that determines how filters
/// are combined.
///
/// The interface also enforces the ability to convert the group into a map
/// representation (typically for JSON serialization).
abstract interface class IApiQueryFilteringGroup {
  /// List of nested filtering groups.
  ///
  /// Each item in the list is another [IApiQueryFilteringGroup], allowing
  /// for recursive nesting of conditions (e.g. AND with nested ORs).
  List<IApiQueryFilteringGroup>? get groups;

  /// List of individual filtering operations.
  ///
  /// Each item is a field-level filter
  /// like "status == active" or "price > 100".
  List<IApiQueryFilter> get filters;

  /// Logical condition (AND, OR, NOT) that joins the filters/groups.
  FilterConditionType get condition;

  /// Converts the selection to a map format.
  Map<String, dynamic> toMap();
}

/// Creates a deep clone of an [IApiQueryFilteringGroup] instance.
///
/// This is a top-level function replacing the `clone()` method.
ApiQueryFilteringGroup cloneApiQueryFilteringGroup(
  IApiQueryFilteringGroup group,
) {
  return ApiQueryFilteringGroup(
    condition: group.condition,
    filters: group.filters.map(cloneApiQueryFilter).toList(),
    groups: group.groups?.map(cloneApiQueryFilteringGroup).toList(),
  );
}

/// Concrete implementation of [IApiQueryFilteringGroup] representing
/// a filtering group in an API query.
///
/// This class provides full support for:
/// - nested groups
/// - converting the group to a serializable map
///
/// Typically used to define structured, composable filter queries.
class ApiQueryFilteringGroup implements IApiQueryFilteringGroup {
  /// Creates a new instance of [ApiQueryFilteringGroup].
  ///
  /// The [condition] defines how filters and groups are combined.
  /// - [filters] is a list of field-level filters.
  /// - [groups] is an optional list of nested filter groups.
  ApiQueryFilteringGroup({
    required this.condition,
    required this.filters,
    this.groups,
  });

  /// Shortcut constructor for an `AND` filter group.
  ///
  /// Useful for writing: `ApiQueryFilteringGroup.and([...])`
  ApiQueryFilteringGroup.and(List<IApiQueryFilter> filters)
      : this(condition: FilterConditionType.and, filters: filters);

  /// Shortcut constructor for an `OR` filter group.
  ApiQueryFilteringGroup.or(List<IApiQueryFilter> filters)
      : this(condition: FilterConditionType.or, filters: filters);

  /// Shortcut constructor for a `NOT` filter group.
  ApiQueryFilteringGroup.not(List<IApiQueryFilter> filters)
      : this(condition: FilterConditionType.not, filters: filters);

  /// The logical condition that joins all filters and subgroups.
  @override
  final FilterConditionType condition;

  /// List of field-level filters (e.g. `name == 'test'`).
  @override
  final List<IApiQueryFilter> filters;

  /// List of nested filter groups.
  ///
  /// Allows recursively building complex filtering logic.
  @override
  final List<IApiQueryFilteringGroup>? groups;

  /// Converts the filtering group to a map structure.
  ///
  /// The returned map is suitable for JSON encoding or network transmission.
  /// Keys:
  /// - `'condition'`: the name of the enum (e.g. `"and"`, `"or"`)
  /// - `'filters'`: list of individual filter maps
  /// - `'groups'`: list of nested group maps (if any)
  List<Map<String, Object?>?>? _visitGroups(
    List<IApiQueryFilteringGroup>? groups,
  ) {
    return groups
        ?.map((group) {
          final filters = group.filters.map((e) => e.toMap()).toList();
          final nestedGroups = _visitGroups(group.groups);

          if (filters.isNotEmpty ||
              (nestedGroups != null && nestedGroups.isNotEmpty)) {
            return {
              'condition': group.condition.name,
              'filters': filters,
              'groups': nestedGroups ?? [],
            };
          }

          return null;
        })
        .where((e) => e != null)
        .toList();
  }

  /// Converts the filtering group instance to a map representation.
  ///
  /// This method converts the filtering group details into a map that can
  /// be easily serialized to JSON or used in API requests.
  @override
  Map<String, dynamic> toMap() {
    final filtering = {
      'condition': condition.name,
      'filters': filters.map((e) => e.toMap()).toList(),
      'groups': _visitGroups(groups) ?? [],
    };
    return {'filtering': filtering};
  }
}
