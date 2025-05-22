/// This file defines the field types used in the query builder.
abstract class QueryFieldSet<T> {
  /// Creates a new instance of [QueryFieldSet].
  const QueryFieldSet();

  /// Returns a list of all fields available in this field set.
  List<String> get allFields;

  /// Returns a list of all fields available in this field set.
  void validateField(String field) {
    if (!allFields.contains(field)) {
      throw ArgumentError('Invalid field $field for type ${T.runtimeType}');
    }
  }
}
