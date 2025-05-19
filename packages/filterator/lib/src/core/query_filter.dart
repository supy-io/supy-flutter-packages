import 'package:filterator/src/core/interfaces/interfaces.dart';
import 'package:filterator/src/core/query_operation.dart';

abstract class IApiQueryFilter
    implements ICloneable<IApiQueryFilter>, IMap<dynamic> {
  /// Gets the field to filter by in the API query.
  String get field;

  /// Gets the filter operation to be applied in the API query.
  QueryOperation get operation;

  /// Gets the value used for matching in the API query.
  dynamic get value;

  /// Gets the value used for matching in the API query.
  List<dynamic>? get values;
}

class ApiQueryFilter implements IApiQueryFilter {
  /// Creates a new instance of [ApiQueryFiltering] with specified details.
  ///
  /// The constructor takes the [by], [op], and [match] details for the
  /// filtering operation. It creates an immutable instance representing a
  /// filtering operation in an API query.
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

  /// Creates a clone of the filtering operation instance.
  ///
  /// This method returns a clone of the original [ApiQueryFiltering] instance,
  /// producing an identical but separate instance.
  @override
  ApiQueryFilter clone() {
    return ApiQueryFilter(
      field: field,
      operation: operation,
      value: value,
      values: values,
    );
  }

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
