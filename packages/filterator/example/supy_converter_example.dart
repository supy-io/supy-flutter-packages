import 'dart:convert';

import 'package:filterator/filterator.dart';

/// A custom API converter for the Supy platform.
///
/// This class extends [ApiStandardConverter] and is responsible for
/// converting a typed query object [T] into API-compatible formats:
/// query parameters and request body maps or JSON strings.
///
/// The converter serializes query elements such as filtering,
/// grouping, paging, ordering, and selection into JSON-compatible
/// structures based on Supy's expected API contract.
///
/// Example usage:
/// ```dart
/// final converter = SupyConverter<MyQuery>(myQuery);
/// final params = converter.toQueryParameters();
/// final body = converter.toRequestBody();
/// ```
class SupyConverter extends ApiStandardConverter {
  /// Creates a new instance of [SupyConverter] with the given [query].
  ///
  /// The [query] is the domain-specific query object that will be
  /// converted into a Supy-compatible format.
  SupyConverter(super.query);

  /// Converts the query into a map of URL query parameters.
  ///
  /// Internally, this delegates to the [body] method, returning the
  /// same serialized map representation.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'filtering': '{...}',
  ///   'paging': '{...}'
  /// }
  /// ```
  @override
  Map<String, dynamic> toQueryParameters({bool encode = true}) {
    return body(encode: encode);
  }

  /// Builds the full query structure as a [Map<String, dynamic>].
  ///
  /// This method optionally encodes parts of the structure (like
  /// filtering, groups, paging, ordering) to JSON strings, based on the
  /// [encode] flag. By default, encoding is enabled for compatibility
  /// with most API query parameter formats.
  ///
  /// - [encode = true] returns strings.
  /// - [encode = false] returns nested maps (used for `toRequestBody()`).
  Map<String, dynamic> body({bool encode = true}) {
    final filtering = query.filtering;

    return {
      if (filtering != null) ...{
        'filtering':
            encode
                ? jsonEncode(
                  _transformFiltering(filtering, includeGroups: false),
                )
                : _transformFiltering(filtering, includeGroups: false),

        if (filtering.groups != null)
          'groups':
              encode
                  ? jsonEncode(
                    filtering.groups!.map(_transformFiltering).toList(),
                  )
                  : filtering.groups!.map(_transformFiltering).toList(),
      },
      if (query.paging != null)
        'paging':
            encode
                ? jsonEncode(_transformPaging(query.paging!))
                : _transformPaging(query.paging!),
      if (query.ordering != null)
        'ordering':
            encode
                ? jsonEncode(query.ordering!.map(_transformOrdering).toList())
                : query.ordering!.map(_transformOrdering).toList(),
      if (query.selection != null)
        'selection':
            encode
                ? jsonEncode(query.selection!.toMap())
                : query.selection!.toMap(),
    };
  }

  /// Transforms a filtering group into a map format.
  ///
  /// The [includeGroups] flag determines whether nested groups are
  /// recursively serialized. This method is used for both top-level
  /// and nested filtering logic.
  Map<String, dynamic> _transformFiltering(
    IApiQueryFilteringGroup filtering, {
    bool includeGroups = true,
  }) {
    return {
      'condition': filtering.condition.name,
      'filtering': filtering.filters.map(_transformFilter).toList(),
      if (filtering.groups != null && includeGroups)
        'groups': filtering.groups?.map(_transformGroups).toList(),
    };
  }

  /// Converts the query into a formatted JSON request body.
  ///
  /// This method disables encoding in [body] to return the structure
  /// as a nested map before formatting it into a pretty JSON string.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "filtering": {
  ///     "condition": "and",
  ///     "filtering": [...]
  ///   }
  /// }
  /// ```
  @override
  String toRequestBody({bool encode = false}) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(body(encode: encode));
  }

  /// Converts a single query filter into a map.
  ///
  /// Handles both `value` and `values` properties, including only the
  /// non-null `match` target appropriate for the filter type.
  Map<String, dynamic> _transformFilter(IApiQueryFilter filter) {
    return {
      'by': filter.field,
      'op': filter.operation.toShortQueryOperation(),
      if (filter.value != null)
        'match': filter.value
      else
        'match': filter.values,
    };
  }

  /// Converts a paging object into a map.
  ///
  /// Includes `offset` and `limit` values directly.
  Map<String, dynamic> _transformPaging(IApiQueryPaging paging) {
    return {'offset': paging.offset, 'limit': paging.limit};
  }

  /// Converts an ordering object into a map.
  ///
  /// The `dir` field is converted to lowercase (e.g., "asc", "desc").
  Map<String, dynamic> _transformOrdering(IApiQueryOrdering ordering) {
    return {'by': ordering.field, 'dir': ordering.dir.name.toLowerCase()};
  }

  /// Transforms a nested filtering group into a map.
  ///
  /// Returns a structured filtering map that includes condition,
  /// filtering rules, and any subgroups. When [encode] is true, the
  /// result is first encoded and then decoded to ensure serialization.
  Map<String, dynamic> _transformGroups(
    IApiQueryFilteringGroup groups, {
    bool encode = true,
  }) {
    final groupMap = {
      'condition': groups.condition.name,
      'filtering': groups.filters.map(_transformFilter).toList(),
      'groups': _visitGroups(groups.groups) ?? [],
    };

    return encode
        ? jsonDecode(jsonEncode(groupMap)) as Map<String, dynamic>
        : groupMap;
  }

  /// Recursively visits and transforms nested filtering groups.
  ///
  /// Returns a list of maps representing each group. Skips null or
  /// empty groups to keep the result clean.
  List<Map<String, Object?>?>? _visitGroups(
    List<IApiQueryFilteringGroup>? groups,
  ) {
    return groups
        ?.map((group) {
          final filtering = group.filters.map(_transformFilter).toList();
          final nestedGroups = _visitGroups(group.groups);

          if (filtering.isNotEmpty || (nestedGroups != null)) {
            return {
              'condition': group.condition.name,
              'filtering': filtering,
              'groups': nestedGroups ?? [],
            };
          }

          return null;
        })
        .where((e) => e != null)
        .toList();
  }
}

/// Extension methods for the [ApiQuery] class.
extension SupyExtension on ApiQuery {
  /// Converts the query into a map of URL query parameters.
  Map<String, dynamic> toSupyQueryParameters({bool encode = true}) {
    return SupyConverter(this).toQueryParameters(encode: encode);
  }

  /// Converts the query into a formatted JSON request body.
  String toSupyRequestBody({bool encode = false}) {
    return SupyConverter(this).toRequestBody(encode: encode);
  }
}
