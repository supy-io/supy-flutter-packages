import 'dart:convert';

import 'package:filterator/filterator.dart' show ApiQuery;
import 'package:filterator/src/core/converter.dart';
import 'package:filterator/src/core/core.dart' show ApiQuery;
import 'package:filterator/src/core/query.dart' show ApiQuery;
import 'package:filterator/src/core/query_filter.dart';
import 'package:filterator/src/core/query_filter_group.dart';
import 'package:filterator/src/core/query_operation.dart';

/// A converter that transforms an [ApiQuery] into OData-compatible query
/// parameters and request body.
///
/// Supports filtering, ordering, and pagination (limit/offset only).
/// Cursor-based pagination is not supported, as per OData specification.
class ODataConverter<T> extends ApiStandardConverter<T> {
  /// Creates a new [ODataConverter] from the given query.
  const ODataConverter(super.query, {this.version = ODataVersion.v4});

  final ODataVersion version;

  /// Converts the API query into a map of OData query parameters for use
  /// in a URL-based request.
  ///
  /// Output includes:
  /// - `$filter`: logical expression for filters
  /// - `$orderby`: sorting instructions
  /// - `$top` and `$skip`: for pagination
  ///
  /// Throws [UnsupportedError] if cursor-based paging is requested.
  @override
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    if (query.filtering != null) {
      params[r'$filter'] = _buildFilter(query.filtering!);
    }

    if (query.ordering != null && query.ordering!.isNotEmpty) {
      params[r'$orderby'] = query.ordering!
          .map((o) => '${o.field} ${o.dir.name.toLowerCase()}')
          .join(',');
    }

    if (query.paging != null) {
      if (query.paging!.cursor != null) {
        throw UnsupportedError(
          'OData does not support cursor-based pagination',
        );
      }
      params[r'$top'] = query.paging!.limit.toString();
      params[r'$skip'] = (query.paging!.offset ?? 0).toString();
    }

    return params;
  }

  /// Converts the API query into a JSON-encoded request body string suitable
  /// for use in POST-based OData querying (if supported).
  ///
  /// Format mirrors the same structure as [toQueryParameters].
  @override
  String toRequestBody() {
    final body = <String, dynamic>{};

    if (query.filtering != null) {
      body[r'$filter'] = _buildFilter(query.filtering!);
    }

    if (query.ordering != null && query.ordering!.isNotEmpty) {
      body[r'$orderby'] = query.ordering!
          .map((o) => '${o.field} ${o.dir.name.toLowerCase()}')
          .join(',');
    }

    if (query.paging != null) {
      if (query.paging!.cursor != null) {
        throw UnsupportedError(
          'OData does not support cursor-based pagination',
        );
      }
      body[r'$top'] = query.paging!.limit;
      body[r'$skip'] = query.paging!.offset ?? 0;
    }

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(body);
  }

  /// Builds the `$filter` expression from a root filtering group.
  String _buildFilter(IApiQueryFilteringGroup group) {
    final buffer = StringBuffer();
    _writeGroup(buffer, group);
    return buffer.toString();
  }

  /// Recursively writes a filter group into the buffer.
  ///
  /// Groups are wrapped in parentheses and combined using the group’s
  /// logical condition (`and` / `or` / `not`).
  void _writeGroup(StringBuffer buffer, IApiQueryFilteringGroup group) {
    final parts = <String>[
      ...group.filtering.map(_convertFilter),
      if (group.groups != null) ...group.groups!.map(_buildFilter),
    ];

    final condition = group.condition.name.toLowerCase();

    if (group.condition == FilterConditionType.not) {
      if (parts.length != 1) {
        throw const FormatException('NOT requires exactly one expression');
      }
      buffer.write('not ${parts.first}');
    } else {
      buffer.write('(');
      buffer.write(parts.join(' $condition '));
      buffer.write(')');
    }
  }

  /// Converts a single filter into an OData-compatible expression string.
  ///
  /// Handles various comparison, list, and string operations.
  String _convertFilter(IApiQueryFilter filter) {
    final field = _formatField(filter.field);

    switch (filter.operation) {
      case QueryOperation.inList when version == ODataVersion.v4:
        return "$field in (${filter.values!.map(_formatValue).join(',')})";
      case QueryOperation.notIn when version == ODataVersion.v4:
        return "not($field in (${filter.values!.map(_formatValue).join(',')}))";
      case QueryOperation.length:
        return 'length($field) eq ${_formatValue(filter.value)}';
      case QueryOperation.indexOf:
        return 'indexof($field, ${_formatValue(filter.value)}) ${_getOperator(filter)}';
      case QueryOperation.substring:
        return 'substring($field, ${filter.values![0]}, ${filter.values![1]}) eq ${_formatValue(filter.value)}';
      case QueryOperation.datePart:
        return '${filter.values![0]}($field) eq ${_formatValue(filter.value)}';
      case QueryOperation.mathOp:
        return '${filter.values![0]}($field) eq ${_formatValue(filter.value)}';
      case QueryOperation.any:
        return '$field/any(${filter.values![0]}: ${_convertLambda(filter)})';
      case QueryOperation.all:
        return '$field/all(${filter.values![0]}: ${_convertLambda(filter)})';
      default:
        return _convertBasicFilter(filter, field);
    }
  }

  String _getOperator(IApiQueryFilter filter) {
    // This helper is necessary for indexOf case, map your own logic here
    switch (filter.operation) {
      case QueryOperation.equals:
        return 'eq';
      case QueryOperation.notEquals:
        return 'ne';
      case QueryOperation.greaterThan:
        return 'gt';
      case QueryOperation.greaterOrEqual:
        return 'ge';
      case QueryOperation.lessThan:
        return 'lt';
      case QueryOperation.lessOrEqual:
        return 'le';
      default:
        return 'eq'; // Default fallback
    }
  }

  String _convertBasicFilter(IApiQueryFilter filter, String field) {
    final value = _formatValue(filter.value);
    switch (filter.operation) {
      case QueryOperation.equals:
        return '$field eq $value';
      case QueryOperation.notEquals:
        return '$field ne $value';
      case QueryOperation.greaterThan:
        return '$field gt $value';
      case QueryOperation.greaterOrEqual:
        return '$field ge $value';
      case QueryOperation.lessThan:
        return '$field lt $value';
      case QueryOperation.lessOrEqual:
        return '$field le $value';
      case QueryOperation.contains:
        return 'contains($field, $value)';
      case QueryOperation.startsWith:
        return 'startswith($field, $value)';
      case QueryOperation.endsWith:
        return 'endswith($field, $value)';
      case QueryOperation.isNull:
        return '$field eq null';
      case QueryOperation.isNotNull:
        return '$field ne null';
      case QueryOperation.inList:
        return filter.values!
            .map((v) => '$field eq ${_formatValue(v)}')
            .join(' or ');
      case QueryOperation.notIn:
        return filter.values!
            .map((v) => '$field ne ${_formatValue(v)}')
            .join(' and ');
      default:
        throw UnsupportedError(
          'Unsupported filter operation: ${filter.operation}',
        );
    }
  }

  /// Formats a value for safe inclusion in an OData query string.
  ///
  /// - Strings are escaped and wrapped in single quotes.
  /// - Dates use ISO 8601.
  /// - Booleans are converted to `true`/`false`.
  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is Duration) return "duration'$value'";
    if (value is String) return "'${value.replaceAll("'", "''")}'";
    if (value is bool) return value.toString().toLowerCase();
    if (value is num) return value.toString();
    throw FormatException('Unsupported value type: ${value.runtimeType}');
  }

  String _convertLambda(IApiQueryFilter filter) {
    final lambdaVar = filter.values![0];
    final lambdaFilter = filter.values![1] as IApiQueryFilter;
    return '$lambdaVar/${_convertFilter(lambdaFilter)}';
  }

  String _formatField(String field) {
    return field;
  }
}

enum ODataVersion { v2, v4 }
