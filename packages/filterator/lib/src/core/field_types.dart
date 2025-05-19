// lib/src/core/field_types.dart

abstract class QueryFieldSet<T> {
  const QueryFieldSet();

  List<String> get allFields;

  void validateField(String field) {
    if (!allFields.contains(field)) {
      throw ArgumentError('Invalid field $field for type ${T.runtimeType}');
    }
  }
}
