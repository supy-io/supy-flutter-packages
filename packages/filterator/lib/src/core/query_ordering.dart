import 'interfaces/interfaces.dart';
import 'query_operation.dart';

/// Interface defining the structure of an API query ordering operation.
///
/// This interface provides a blueprint
/// for creating ordering configurations in an API query.
abstract interface class IApiQueryOrdering<T>
    implements ICloneable<ApiQueryOrdering<T>>, IMap<dynamic> {
  /// The field by which the ordering is applied.
  String get field;

  /// The direction of the ordering (ascending or descending).
  QueryOrderDirection get dir;
}

/// Class representing an ordering operation in an API query.
///
/// An instance of this class defines an ordering operation in an API query,
/// specifying the field [by] and the order [dir] (ascending or descending).
class ApiQueryOrdering<T> implements IApiQueryOrdering<T> {
  /// Creates an [ApiQueryOrdering] instance with the specified field [by]
  /// and order direction [dir].
  const ApiQueryOrdering({required this.field, required this.dir});

  @override
  final String field;
  @override
  final QueryOrderDirection dir;

  /// Creates a clone of the current [ApiQueryOrdering] instance.
  @override
  ApiQueryOrdering<T> clone() => ApiQueryOrdering<T>(field: field, dir: dir);

  /// Converts the ordering configuration to a JSON-like map.
  @override
  Map<String, dynamic> toMap() {
    return {'field': field, 'dir': dir.name};
  }
}
