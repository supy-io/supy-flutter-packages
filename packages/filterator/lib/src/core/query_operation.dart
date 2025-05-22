/// Enum representing the logical condition used to combine filter expressions.
///
/// Typically used in compound query filters to define whether all
/// conditions must be true (`and`), any condition can be true (`or`),
/// or the condition should be negated (`not`).
enum FilterConditionType {
  /// Logical AND condition: all contained filters or groups must match.
  and,

  /// Logical OR condition: at least one contained filter or group must match.
  or,

  /// Logical NOT condition: inverts the result
  /// of the contained filters or groups.
  not,
}

/// Enum representing the direction of sorting in an API query.
enum QueryOrderDirection {
  /// Ascending order: values are sorted from smallest to largest.
  asc,

  /// Descending order: values are sorted from largest to smallest.
  desc,
}

/// Enum representing supported operations for filtering query data.
///
/// Includes comparison operations, string-based filters, collection filters,
/// math and date functions, and null checks.
enum QueryOperation {
  // Basic comparisons

  /// Equals (`==`) comparison.
  equals,

  /// Not equals (`!=`) comparison.
  notEquals,

  /// Greater than (`>`) comparison.
  greaterThan,

  /// Less than (`<`) comparison.
  lessThan,

  /// Greater than or equal (`>=`) comparison.
  greaterOrEqual,

  /// Less than or equal (`<=`) comparison.
  lessOrEqual,

  // Collections

  /// Checks if a value is in a list.
  inList,

  /// Checks if a value is not in a list.
  notIn,

  /// Checks if any value in the list matches the condition.
  any,

  /// Checks if all values in the list match the condition.
  all,

  // String operations

  /// Checks if the string contains a specific value.
  contains,

  /// Checks if the string contains any of the given values.
  containsAny,

  /// Checks if the string contains all of the given values.
  containsAll,

  /// Checks if the string does not contain the specified value.
  notContains,

  /// Checks if the string starts with the specified prefix.
  startsWith,

  /// Checks if the string ends with the specified suffix.
  endsWith,

  /// Retrieves the length of a string or collection.
  length,

  /// Gets the index of a substring.
  indexOf,

  /// Extracts a substring.
  substring,

  /// Converts the value to lowercase.
  toLower,

  /// Converts the value to uppercase.
  toUpper,

  /// Performs a pattern match using SQL-like syntax.
  like,

  /// Performs a fuzzy or full-text search.
  search,

  // Date operations

  /// Extracts a part of a date (e.g., year, month).
  datePart,

  // Math operations

  /// Applies a math operation (e.g., add, subtract).
  mathOp,

  // Null checks

  /// Checks if the value is null.
  isNull,

  /// Checks if the value is not null.
  isNotNull,
}

/// Extension on [String] to convert a string to a [QueryOperation].
extension QueryOperationStringExtension on String {
  /// Converts the string representation of an operation into
  /// a [QueryOperation] enum.
  ///
  /// Supports aliases like `'eq'` for `equals`, `'gt'` for `greaterThan`, etc.
  ///
  /// Throws an [ArgumentError] if the string does not match a known operation.
  QueryOperation toQueryOperation() {
    return switch (toLowerCase()) {
      'equals' || 'eq' => QueryOperation.equals,
      'notequals' || 'neq' => QueryOperation.notEquals,
      'inlist' || 'in' => QueryOperation.inList,
      'notin' || 'not-in' => QueryOperation.notIn,
      'contains' => QueryOperation.contains,
      'contains-any' => QueryOperation.containsAny,
      'contains-all' => QueryOperation.containsAll,
      'not-contains' => QueryOperation.notContains,
      'startswith' || 'starts-with' => QueryOperation.startsWith,
      'endswith' || 'ends-with' => QueryOperation.endsWith,
      'greaterthan' || 'gt' => QueryOperation.greaterThan,
      'lessthan' || 'lt' => QueryOperation.lessThan,
      'greaterorequal' || 'gte' => QueryOperation.greaterOrEqual,
      'lessorequal' || 'lte' => QueryOperation.lessOrEqual,
      'isnull' => QueryOperation.isNull,
      'isnotnull' => QueryOperation.isNotNull,
      'like' => QueryOperation.like,
      'search' => QueryOperation.search,
      _ => throw ArgumentError('Invalid QueryOperation: $this'),
    };
  }
}

/// Extension on [QueryOperation] that provides a shorthand
/// string representation
/// of each operation, typically used in query serialization.
///
/// This is useful for converting enum values to compact query parameter strings
/// when building API requests.
extension QueryOperationExtension on QueryOperation {
  /// Converts the [QueryOperation] enum to its shorthand string form.
  ///
  /// This method is particularly useful when serializing query filters
  /// for APIs that expect compact operation keywords (e.g., `eq`, `gt`, `in`).
  ///
  /// Throws an [ArgumentError] if the operation is unsupported or not mapped.
  ///
  /// Example:
  /// ```dart
  /// QueryOperation.equals.toShort(); // returns 'eq'
  /// ```
  String toShortQueryOperation() {
    return switch (this) {
      QueryOperation.equals => 'eq',
      QueryOperation.notEquals => 'neq',
      QueryOperation.inList => 'in',
      QueryOperation.notIn => 'not-in',
      QueryOperation.contains => 'contains',
      QueryOperation.containsAny => 'contains-any',
      QueryOperation.containsAll => 'contains-all',
      QueryOperation.notContains => 'not-contains',
      QueryOperation.startsWith => 'starts-with',
      QueryOperation.endsWith => 'ends-with',
      QueryOperation.greaterThan => 'gt',
      QueryOperation.lessThan => 'lt',
      QueryOperation.greaterOrEqual => 'gte',
      QueryOperation.lessOrEqual => 'lte',
      QueryOperation.isNull => 'is-null',
      QueryOperation.isNotNull => 'is-not-null',
      QueryOperation.like => 'like',
      QueryOperation.search => 'search',
      _ => throw ArgumentError('Invalid QueryOperation: $this'),
    };
  }
}

/// Extension on [String] to convert a string to a [QueryOrderDirection].
extension QueryOrderDirectionExtension on String {
  /// Converts a string to a [QueryOrderDirection].
  ///
  /// Accepts multiple aliases:
  /// - `'asc'`, `'ascending'`, `'ascend'` → [QueryOrderDirection.asc]
  /// - `'desc'`, `'descending'`, `'descend'` → [QueryOrderDirection.desc]
  ///
  /// Throws an [ArgumentError] if the string doesn't match a valid direction.
  QueryOrderDirection toQueryOrderDirection() {
    return switch (toLowerCase()) {
      'asc' || 'ascending' || 'ascend' => QueryOrderDirection.asc,
      'desc' || 'descending' || 'descend' => QueryOrderDirection.desc,
      _ => throw ArgumentError('Invalid QueryOrderDirection: $this'),
    };
  }
}
