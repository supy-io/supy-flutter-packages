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
class ODataConverter extends ApiStandardConverter {
  const ODataConverter(super.query, {this.version = ODataVersion.v4});

  final ODataVersion version;

  @override
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    if (query.filtering case final f?) {
      params[r'$filter'] = _buildFilter(f);
    }

    if (query.ordering case final o? when o.isNotEmpty) {
      params[r'$orderby'] =
          o.map((e) => '${e.field} ${e.dir.name.toLowerCase()}').join(',');
    }

    if (query.paging case final p?) {
      if (p.cursor != null) {
        throw UnsupportedError(
          'OData does not support cursor-based pagination',
        );
      }
      params[r'$top'] = p.limit.toString();
      params[r'$skip'] = (p.offset ?? 0).toString();
    }

    return params;
  }

  @override
  String toRequestBody() {
    final body = <String, dynamic>{};

    if (query.filtering case final f?) {
      body[r'$filter'] = _buildFilter(f);
    }

    if (query.ordering case final o? when o.isNotEmpty) {
      body[r'$orderby'] =
          o.map((e) => '${e.field} ${e.dir.name.toLowerCase()}').join(',');
    }

    if (query.paging case final p?) {
      if (p.cursor != null) {
        throw UnsupportedError(
          'OData does not support cursor-based pagination',
        );
      }
      body[r'$top'] = p.limit;
      body[r'$skip'] = p.offset ?? 0;
    }

    return const JsonEncoder.withIndent('  ').convert(body);
  }

  String _buildFilter(IApiQueryFilteringGroup group) {
    final buffer = StringBuffer();
    _writeGroup(buffer, group);
    return buffer.toString();
  }

  void _writeGroup(StringBuffer buffer, IApiQueryFilteringGroup group) {
    final parts = <String>[
      ...group.filters.map(_convertFilter),
      if (group.groups != null) ...group.groups!.map(_buildFilter),
    ];

    final condition = group.condition.name.toLowerCase();

    if (group.condition == FilterConditionType.not) {
      if (parts.length != 1) {
        throw const FormatException('NOT requires exactly one expression');
      }
      buffer.write('not ${parts.first}');
    } else {
      buffer
        ..write('(')
        ..write(parts.join(' $condition '))
        ..write(')');
    }
  }

  String _convertFilter(IApiQueryFilter filter) {
    final field = _formatField(filter.field);

    return switch (filter.operation) {
      QueryOperation.inList when version == ODataVersion.v4 =>
        "$field in (${filter.values!.map(_formatValue).join(',')})",
      QueryOperation.notIn when version == ODataVersion.v4 =>
        "not($field in (${filter.values!.map(_formatValue).join(',')}))",
      QueryOperation.length =>
        'length($field) eq ${_formatValue(filter.value)}',
      QueryOperation.indexOf => 'indexof($field, ${_formatValue(filter.value)})'
          ' ${_getOperator(filter)}',
      QueryOperation.substring =>
        'substring($field, ${filter.values![0]}, ${filter.values![1]})'
            ' eq ${_formatValue(filter.value)}',
      QueryOperation.datePart =>
        '${filter.values![0]}($field) eq ${_formatValue(filter.value)}',
      QueryOperation.mathOp =>
        '${filter.values![0]}($field) eq ${_formatValue(filter.value)}',
      QueryOperation.any =>
        '$field/any(${filter.values![0]}: ${_convertLambda(filter)})',
      QueryOperation.all =>
        '$field/all(${filter.values![0]}: ${_convertLambda(filter)})',
      _ => _convertBasicFilter(filter, field),
    };
  }

  String _getOperator(IApiQueryFilter filter) => switch (filter.operation) {
        QueryOperation.equals => 'eq',
        QueryOperation.notEquals => 'ne',
        QueryOperation.greaterThan => 'gt',
        QueryOperation.greaterOrEqual => 'ge',
        QueryOperation.lessThan => 'lt',
        QueryOperation.lessOrEqual => 'le',
        _ => 'eq',
      };

  String _convertBasicFilter(IApiQueryFilter filter, String field) {
    final value = _formatValue(filter.value);

    return switch (filter.operation) {
      QueryOperation.equals => '$field eq $value',
      QueryOperation.notEquals => '$field ne $value',
      QueryOperation.greaterThan => '$field gt $value',
      QueryOperation.greaterOrEqual => '$field ge $value',
      QueryOperation.lessThan => '$field lt $value',
      QueryOperation.lessOrEqual => '$field le $value',
      QueryOperation.contains => 'contains($field, $value)',
      QueryOperation.startsWith => 'startswith($field, $value)',
      QueryOperation.endsWith => 'endswith($field, $value)',
      QueryOperation.isNull => '$field eq null',
      QueryOperation.isNotNull => '$field ne null',
      QueryOperation.inList =>
        filter.values!.map((v) => '$field eq ${_formatValue(v)}').join(' or '),
      QueryOperation.notIn =>
        filter.values!.map((v) => '$field ne ${_formatValue(v)}').join(' and '),
      _ => throw UnsupportedError(
          'Unsupported filter operation: ${filter.operation}',
        ),
    };
  }

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

  String _formatField(String field) => field;
}

enum ODataVersion { v2, v4 }
