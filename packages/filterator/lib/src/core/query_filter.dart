import 'package:filterator/src/core/query_operation.dart';

/// Interface defining the structure of an API query filter operation.
abstract class IApiQueryFilter {
  /// Gets the field to filter by in the API query.
  String get field;

  /// Gets the filter operation to be applied in the API query.
  QueryOperation get operation;

  /// Gets the value used for matching in the API query.
  dynamic get value;

  /// Gets the list of values used for matching in the API query.
  List<dynamic>? get values;

  /// Converts the selection to a map format.
  Map<String, dynamic> toMap();
}

/// Creates a clone of an [IApiQueryFilter] instance.
///
/// This is a top-level function replacing the `clone()` method.
/// Implement cloning logic here if needed.
ApiQueryFilter cloneApiQueryFilter(IApiQueryFilter filter) {
  return ApiQueryFilter(
    field: filter.field,
    operation: filter.operation,
    value: filter.value,
    values: filter.values,
  );
}

/// Class representing a filter operation in an API query.
class ApiQueryFilter implements IApiQueryFilter {
  /// Creates a new instance of [ApiQueryFilter] with specified details.
  ///
  /// The constructor takes the [field], [operation], and [values || value]
  /// details for the filtering operation. It creates an immutable instance
  /// representing a filtering operation in an API query.
  ApiQueryFilter({
    required this.field,
    required this.operation,
    this.value,
    this.values,
  }) : assert(
          QueryOperation.values.contains(operation),
          'QueryOperation Values is not containing your operator',
        );

  /// The field to filter by in the API query.
  @override
  final String field;

  /// The filter operation to be applied in the API query.
  @override
  final QueryOperation operation;

  /// The value used for matching in the API query.
  @override
  final dynamic value;

  /// The values used for matching in the API query.
  @override
  final List<dynamic>? values;

  /// Converts the filtering operation instance to a map representation.
  ///
  /// This method converts the filtering operation details into a map that can
  /// be easily serialized to JSON or used in API requests.
  @override
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operation': operation.name,
      if (value != null) 'value': value,
      if (values != null) 'values': values,
    };
  }
}
