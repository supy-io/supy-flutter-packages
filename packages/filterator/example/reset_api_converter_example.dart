import 'package:filterator/filterator.dart';

/// A custom API query converter that transforms a  query into a
/// map of query parameters suitable for REST API requests.
///
/// This converter processes filtering, searching,
/// ordering, selection, and paging
/// criteria defined in the [query] object and converts them into a structured
/// query parameters map.
///
/// - Search filters with field 'q' and `contains`
/// operation are handled specially.
/// - Other filters are converted with operator suffixes, e.g., `field__eq`.
/// - Ordering fields are concatenated as `sort=field:asc,otherField:desc`.
/// - Selected fields are concatenated as `fields=field1,field2`.
/// - Paging parameters `limit` and `offset` are included if specified.
///
/// Usage:
/// ```dart
/// final converter = ResetApiConverter(query);
/// final params = converter.toQueryParameters();
/// ```
///
/// Throws [ArgumentError] if an unsupported query operation is encountered.
class ResetApiConverter extends ApiStandardConverter {
  ResetApiConverter(super.query);

  /// Internal map to accumulate query parameters.
  final params = <String, dynamic>{};

  /// Converts the provided [query] into a map of query parameters.
  ///
  /// The map can be directly used to build REST API requests.
  ///
  /// Processes search filters, general filters, ordering, field selection,
  /// and paging parameters in sequence.
  @override
  Map<String, dynamic> toQueryParameters() {
    _processSearch();
    _processFilters();
    _processOrdering();
    _processSelection();
    _processPaging();

    return params;
  }

  /// Processes search filters where the
  /// field is 'q' and operation is `contains`.
  /// Adds the value as 'q' parameter.
  void _processSearch() {
    final searchFilters = query.filtering?.filters.where(
      (filter) =>
          filter.field == 'q' && filter.operation == QueryOperation.contains,
    );
    if (searchFilters != null && searchFilters.isNotEmpty) {
      params['q'] = searchFilters.first.value.toString();
    }
  }

  /// Processes other filters, excluding the search filters handled separately.
  /// Converts filter operations to their string representations and adds
  /// them with a suffix in the format `field__operator`.
  void _processFilters() {
    final filteringGroup = query.filtering;
    if (filteringGroup == null) return;

    for (final filter in filteringGroup.filters) {
      if (filter.field == 'q' && filter.operation == QueryOperation.contains) {
        continue; // Handled by _processSearch
      }
      final op = _operatorToString(filter.operation);
      final key = '${filter.field}__$op';
      params[key] = filter.value;
    }
  }

  /// Processes ordering instructions and adds them as a comma-separated
  /// 'sort' parameter with format 'field:direction'.
  void _processOrdering() {
    final ordering = query.ordering;
    if (ordering == null || ordering.isEmpty) return;

    params['sort'] = ordering
        .map((order) => '${order.field}:${_directionToString(order.dir)}')
        .join(',');
  }

  /// Processes field selection to include only specified fields.
  /// Adds them as a comma-separated 'fields' parameter.
  void _processSelection() {
    final selection = query.selection;
    if (selection == null || selection.includes.isEmpty) return;

    params['fields'] = selection.includes.join(',');
  }

  /// Processes paging information and adds
  /// 'limit' and 'offset' parameters if present.
  void _processPaging() {
    final paging = query.paging;
    if (paging == null) return;

    params['limit'] = paging.limit;
    if (paging.offset != null) {
      params['offset'] = paging.offset;
    }
  }

  /// Maps a [QueryOperation] enum value
  /// to its corresponding API operator string.
  ///
  /// Throws [ArgumentError] for unsupported operators.
  String _operatorToString(QueryOperation op) => switch (op) {
    QueryOperation.equals => 'eq',
    QueryOperation.notEquals => 'ne',
    QueryOperation.greaterThan => 'gt',
    QueryOperation.greaterOrEqual => 'gte',
    QueryOperation.lessThan => 'lt',
    QueryOperation.lessOrEqual => 'lte',
    QueryOperation.contains => 'contains',
    QueryOperation.startsWith => 'startswith',
    QueryOperation.endsWith => 'endswith',
    QueryOperation.inList => 'in',
    QueryOperation.notIn => 'nin',
    QueryOperation.isNull => 'isnull',
    QueryOperation.isNotNull => 'notnull',
    _ => throw ArgumentError('Unsupported operator $op'),
  };

  /// Converts the ordering direction enum to its string representation.
  /// Returns 'asc' for ascending and 'desc' for descending order.
  String _directionToString(QueryOrderDirection direction) {
    return direction == QueryOrderDirection.asc ? 'asc' : 'desc';
  }
}
