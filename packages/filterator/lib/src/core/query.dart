import 'package:filterator/src/core/query_filter_group.dart';
import 'package:filterator/src/core/query_operation.dart';
import 'package:filterator/src/core/query_ordering.dart';
import 'package:filterator/src/core/query_paging.dart';
import 'package:filterator/src/core/query_selections.dart';

/// Interface defining the structure of an API query.
///
/// This interface outlines the components of an API query, including
/// filtering, ordering, and paging details. It provides methods to create a
/// modified copy, and convert the query to a map.
abstract interface class IApiQuery {
  /// Gets the filtering details of the API query.
  IApiQueryFilteringGroup? get filtering;

  /// Gets the list of ordering details in the API query.
  List<IApiQueryOrdering>? get ordering;

  /// Gets the paging details of the API query.
  IApiQueryPaging? get paging;

  ///
  IApiQuerySelection? get selection;

  /// Creates a new instance of [IApiQuery] with specified modifications.
  ///
  /// This method returns a modified copy of the original [IApiQuery] instance
  /// with the provided changes. It allows for creating a new query based on
  /// the original query while modifying specific components.
  IApiQuery copyWith({
    IApiQueryFilteringGroup? filtering,
    List<IApiQueryOrdering>? ordering,
    IApiQueryPaging? paging,
    IApiQuerySelection? selection,
  });
}

/// Creates a clone of an [IApiQuery] instance.
///
/// This is a top-level function replacing the `clone()` method.
/// Implement cloning logic here if needed.
ApiQuery cloneApiQuery(IApiQuery query) {
  return ApiQuery._(query: query);
}

/// Class representing a complete API query.
///
/// This class implements the [IApiQuery] interface and represents a complete
/// API query with filtering, ordering, and paging details. It allows for
/// creating, modifying, and converting API queries to a map.
class ApiQuery implements IApiQuery {
  /// Creates a new instance of [ApiQuery] with specified details.
  ///
  /// The constructor takes the [filtering], [ordering], and [paging] details
  /// for the API query. It creates an immutable instance representing a
  /// complete API query.
  const ApiQuery({this.filtering, this.ordering, this.paging, this.selection});

  /// Creates an API query instance from another query instance.
  ///
  /// This static method is used to create an [ApiQuery] instance from an
  /// existing [IApiQuery] instance.
  factory ApiQuery.from(IApiQuery query) {
    return ApiQuery._(query: query);
  }

  /// Creates an API query instance with default values.
  ///
  /// This private constructor is used to create an instance of [ApiQuery]
  /// with default values when no query is provided.
  ApiQuery._({IApiQuery? query})
    : filtering =
          query?.filtering ??
          ApiQueryFilteringGroup(
            condition: FilterConditionType.and,
            filters: [],
            groups: [],
          ),
      ordering = query?.ordering ?? [],
      paging = query?.paging ?? ApiQueryPaging.noLimit(),
      selection = null;

  @override
  final IApiQueryFilteringGroup? filtering;

  @override
  final List<IApiQueryOrdering>? ordering;

  @override
  final IApiQueryPaging? paging;
  @override
  final IApiQuerySelection? selection;

  /// Casts an API query instance to a specific type.
  ///
  /// This static method is used to cast an [IApiQuery] instance to [ApiQuery]
  /// with a specific data type [T].
  static ApiQuery cast<T>(IApiQuery query) {
    return ApiQuery._(query: query);
  }

  /// Creates a modified copy of the API query with specified changes.
  ///
  /// This method returns a new instance of [ApiQuery] with the specified
  /// modifications, allowing for easy creation of updated queries.
  @override
  ApiQuery copyWith({
    IApiQueryFilteringGroup? filtering,
    List<IApiQueryOrdering>? ordering,
    IApiQueryPaging? paging,
    IApiQuerySelection? selection,
  }) {
    return ApiQuery(
      filtering: filtering ?? this.filtering,
      ordering: ordering ?? this.ordering,
      paging: paging ?? this.paging,
      selection: selection ?? this.selection,
    );
  }

  /// Converts the API query instance to a map representation.
  ///
  /// This method converts the API query details into a map that can be easily
  /// serialized to JSON or used in HTTP requests.
  Map<String, dynamic> toMap() {
    final filteringMap = filtering?.toMap();
    final pagingMap = paging?.toMap();
    final orderingList = ordering?.map((e) => e.toMap()).toList();
    final selectionMap = selection?.toMap();
    return {
      if (filteringMap != null) ...filteringMap,
      if (pagingMap != null) 'paging': pagingMap,
      if (ordering != null) 'ordering': orderingList,
      if (selection != null) 'selection': selectionMap,
    };
  }
}
