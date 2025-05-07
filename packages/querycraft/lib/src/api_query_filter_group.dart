import 'dart:convert';
import 'package:querycraft/querycraft.dart';
import 'interfaces/interfaces.dart';

/// Interface defining the structure of an API query filtering group.
///
/// This interface outlines the components of an API query filtering group,
/// including the nested filtering groups, the individual filtering operations,
/// and the condition type (AND, OR) for combining the groups.
/// It provides methods
/// to clone the filtering group and convert it to a map.
abstract interface class IApiQueryFilteringGroup<T>
    implements ICloneable<dynamic>, IMap<dynamic> {
  /// Gets the list of nested filtering groups within this group.
  List<IApiQueryFilteringGroup<T>>? get groups;

  /// Gets the list of individual filtering operations within this group.
  List<IApiQueryFiltering> get filtering;

  /// Gets the condition type (AND, OR) for combining the groups.
  FilterConditionType get condition;
}

/// Class representing a filtering group in an API query.
///
/// This class implements the [IApiQueryFilteringGroup] interface and represents
/// a filtering group in an API query. It includes the condition type (AND, OR),
/// the list of individual filtering operations,
/// and the list of nested filtering
/// groups. It also provides methods for cloning
/// the filtering group and converting
/// it to a map.
class ApiQueryFilteringGroup<T> implements IApiQueryFilteringGroup<T> {
  /// Creates a new instance of [ApiQueryFilteringGroup] with specified details.
  ///
  /// The constructor takes the [condition], [filtering], and [groups] details
  /// for the filtering group. It creates an immutable instance representing a
  /// filtering group in an API query.
  ApiQueryFilteringGroup({
    required this.condition,
    required this.filtering,
    this.groups,
  });

  /// The condition type (AND, OR) for combining the groups.
  @override
  final FilterConditionType condition;

  /// The list of individual filtering operations within this group.
  @override
  final List<IApiQueryFiltering> filtering;

  /// The list of nested filtering groups within this group.
  @override
  final List<IApiQueryFilteringGroup<T>>? groups;

  /// Creates a clone of the filtering group instance.
  ///
  /// This method returns a clone of the original
  /// [ApiQueryFilteringGroup] instance,
  /// producing an identical but separate instance.
  @override
  ApiQueryFilteringGroup<T> clone() {
    return ApiQueryFilteringGroup<T>(
      condition: condition,
      filtering: List.from(filtering.map((filter) => filter.clone())),
      groups:
          groups == null
              ? groups
              : List.from(groups!.map((group) => group.clone())),
    );
  }

  /// Recursive function that traverses a list of
  /// IApiQueryFilteringGroup instances
  /// and converts them into a structured list of
  /// maps representing the filter conditions
  /// and nested groups.
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
  Map<String, dynamic> toMap({bool encode = true}) {
    final filtering = {
      'condition': condition.name,
      'filtering': this.filtering.map((e) => e.toMap(encode: encode)).toList(),
      'groups': _visitGroups(groups) ?? [],
    };
    return {'filtering': encode ? jsonEncode(filtering) : filtering};
  }
}
