import 'package:filterator/src/core/query_operation.dart';

/// Interface defining the structure of an API query ordering operation.
///
/// This interface provides a blueprint
/// for creating ordering configurations in an API query.
abstract interface class IApiQueryOrdering {
  /// The field by which the ordering is applied.
  String get field;

  /// The direction of the ordering (ascending or descending).
  QueryOrderDirection get dir;

  /// Converts the selection to a map format.
  Map<String, dynamic> toMap();
}

/// Creates a clone of an [IApiQueryOrdering] instance.
///
/// This is a top-level function replacing the `clone()` method.
ApiQueryOrdering cloneApiQueryOrdering(IApiQueryOrdering ordering) {
  return ApiQueryOrdering(field: ordering.field, dir: ordering.dir);
}

/// Class representing an ordering operation in an API query.
///
/// An instance of this class defines an ordering operation in an API query,
/// specifying the field [field] and the order [dir] (ascending or descending).
class ApiQueryOrdering implements IApiQueryOrdering {
  /// Creates an [ApiQueryOrdering]
  /// instance with the specified field [field]
  /// and order direction [dir].
  const ApiQueryOrdering({required this.field, required this.dir});

  @override
  final String field;
  @override
  final QueryOrderDirection dir;

  /// Converts the ordering configuration to a JSON-like map.
  @override
  Map<String, dynamic> toMap() {
    return {'field': field, 'dir': dir.name};
  }
}
