import 'interfaces/interfaces.dart';
import 'query_filter.dart';
import 'query_operation.dart';

/// Interface defining the structure of an API query filtering group.
///
/// This interface outlines how complex query filters are grouped, including:
/// - nested filtering groups (`groups`)
/// - individual field filters (`filtering`)
/// - the condition (`AND`, `OR`, `NOT`) that determines how filters are combined.
///
/// The interface also enforces the ability to:
/// - clone the group
/// - convert the group into a map representation (typically for JSON serialization).
abstract interface class IApiQueryFilteringGroup<T>
    implements ICloneable<dynamic>, IMap<dynamic> {
  /// List of nested filtering groups.
  ///
  /// Each item in the list is another [IApiQueryFilteringGroup], allowing
  /// for recursive nesting of conditions (e.g. AND with nested ORs).
  List<IApiQueryFilteringGroup<T>>? get groups;

  /// List of individual filtering operations.
  ///
  /// Each item is a field-level filter like "status == active" or
  /// "price > 100".
  List<IApiQueryFilter> get filtering;

  /// Logical condition (AND, OR, NOT) that joins the filters/groups.
  FilterConditionType get condition;
}

/// A concrete implementation of [IApiQueryFilteringGroup] that represents
/// a filtering group in an API query.
///
/// This class provides full support for:
/// - nested groups
/// - cloning the group
/// - converting the group to a serializable map
///
/// Typically used to define structured, composable filter queries.
class ApiQueryFilteringGroup<T> implements IApiQueryFilteringGroup<T> {
  /// Creates a new instance of [ApiQueryFilteringGroup].
  ///
  /// The [condition] defines how filters and groups are combined.
  /// - [filtering] is a list of field-level filters.
  /// - [groups] is an optional list of nested filter groups.
  ApiQueryFilteringGroup({
    required this.condition,
    required this.filtering,
    this.groups,
  });

  /// Shortcut constructor for an `AND` filter group.
  ///
  /// Useful for writing: `ApiQueryFilteringGroup.and([...])`
  ApiQueryFilteringGroup.and(List<IApiQueryFilter> filters)
    : this(condition: FilterConditionType.and, filtering: filters);

  /// Shortcut constructor for an `OR` filter group.
  ApiQueryFilteringGroup.or(List<IApiQueryFilter> filters)
    : this(condition: FilterConditionType.or, filtering: filters);

  /// Shortcut constructor for a `NOT` filter group.
  ApiQueryFilteringGroup.not(List<IApiQueryFilter> filters)
    : this(condition: FilterConditionType.not, filtering: filters);

  /// The logical condition that joins all filters and subgroups.
  @override
  final FilterConditionType condition;

  /// List of field-level filters (e.g. `name == 'test'`).
  @override
  final List<IApiQueryFilter> filtering;

  /// List of nested filter groups.
  ///
  /// Allows recursively building complex filtering logic.
  @override
  final List<IApiQueryFilteringGroup<T>>? groups;

  /// Clones this filtering group and its contents.
  ///
  /// The clone will deeply copy all filters and subgroups, producing a
  /// new independent instance.
  @override
  ApiQueryFilteringGroup<T> clone() {
    return ApiQueryFilteringGroup<T>(
      condition: condition,
      filtering: List.from(filtering.map((filter) => filter.clone())),
      groups:
          groups == null
              ? null
              : List.from(groups!.map((group) => group.clone())),
    );
  }

  /// Converts the filtering group to a map structure.
  ///
  /// The returned map is suitable for JSON encoding or network transmission.
  /// Keys:
  /// - `'condition'`: the name of the enum (e.g. `"and"`, `"or"`)
  /// - `'filters'`: list of individual filter maps
  /// - `'groups'`: list of nested group maps (if any)
  List<Map<String, Object?>?>? _visitGroups(
    List<IApiQueryFilteringGroup<dynamic>>? groups,
  ) {
    return groups
        ?.map((group) {
          final filtering = group.filtering.map((e) => e.toMap()).toList();
          final nestedGroups = _visitGroups(group.groups);

          if (filtering.isNotEmpty || (nestedGroups != null)) {
            return {
              'condition': group.condition.name,
              'filtering': filtering,
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
      'filtering': this.filtering.map((e) => e.toMap()).toList(),
      'groups': _visitGroups(groups) ?? [],
    };
    return {'filtering': filtering};
  }

}
