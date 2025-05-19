import 'package:filterator/src/core/interfaces/interfaces.dart';
import 'package:filterator/src/core/query_operation.dart';

/// Interface defining the structure of an API query ordering operation.
///
/// This interface provides a blueprint
/// for creating ordering configurations in an API query.
abstract interface class IApiQueryOrdering
    implements ICloneable<ApiQueryOrdering>, IMap<dynamic> {
  /// The field by which the ordering is applied.
  String get field;

  /// The direction of the ordering (ascending or descending).
  QueryOrderDirection get dir;
}

/// Class representing an ordering operation in an API query.
///
/// An instance of this class defines an ordering operation in an API query,
/// specifying the field [by] and the order [dir] (ascending or descending).
class ApiQueryOrdering implements IApiQueryOrdering {
  /// Creates an [ApiQueryOrdering] instance with the specified field [by]
  /// and order direction [dir].
  const ApiQueryOrdering({required this.field, required this.dir});

  @override
  final String field;
  @override
  final QueryOrderDirection dir;

  /// Creates a clone of the current [ApiQueryOrdering] instance.
  @override
  ApiQueryOrdering clone() => ApiQueryOrdering(field: field, dir: dir);

  /// Converts the ordering configuration to a JSON-like map.
  @override
  Map<String, dynamic> toMap() {
    return {'field': field, 'dir': dir.name};
  }
}
