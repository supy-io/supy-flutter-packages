/// Interface defining the paging details for an API query.
///
/// This interface outlines the structure of paging details in an API query,
/// specifying the offset and limit for fetching data.
abstract interface class IApiQueryPaging {
  /// The offset parameter for the API query,
  /// indicating the starting index of the results.
  int? get offset;

  /// The limit parameter for the API query,
  /// indicating the maximum number of results to retrieve.
  int get limit;

  /// The cursor parameter for the API query,
  String? get cursor;

  /// Creates a copy of the current paging
  /// configuration with optional modifications.
  ///
  /// The [offset], [limit], and [cursor] parameters allow modifying
  /// these values while keeping others intact.
  IApiQueryPaging copyWith({int? offset, int? limit, String? cursor});

  /// Converts the selection to a map format.
  Map<String, dynamic> toMap();
}

/// Concrete implementation of [IApiQueryPaging].
///
/// Defines the paging details with offset, limit, and optional cursor.
class ApiQueryPaging implements IApiQueryPaging {
  /// Creates an [ApiQueryPaging] instance with the specified offset and limit.
  const ApiQueryPaging({
    required this.offset,
    required this.limit,
    this.cursor,
  });

  /// Returns a paging configuration with no limit.
  ///
  /// This is a convenient constant for creating a paging
  /// configuration with no offset and no limit.
  factory ApiQueryPaging.noLimit() =>
      const ApiQueryPaging(offset: kNoOffset, limit: kNoLimit);

  /// Returns a paging configuration using cursor-based pagination.
  const ApiQueryPaging.cursorBased({required this.limit, required this.cursor})
      : offset = null;

  @override
  final int? offset;
  @override
  final int limit;
  @override
  final String? cursor;

  /// Constant indicating no offset in the API query.
  static const int kNoOffset = 0;

  /// Constant indicating no limit in the API query.
  static const int kNoLimit = -1;

  /// Creates a copy of the current [ApiQueryPaging]
  /// instance with optional modifications.
  ///
  /// The [offset], [limit], and [cursor] parameters allow modifying these
  /// values while keeping others intact.
  @override
  IApiQueryPaging copyWith({int? offset, int? limit, String? cursor}) {
    return ApiQueryPaging(
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      cursor: cursor ?? this.cursor,
    );
  }

  /// Converts the paging configuration to a JSON-like map.
  @override
  Map<String, dynamic> toMap() {
    return {
      if (cursor != null) 'cursor': cursor,
      if (offset != null) 'offset': offset,
      'limit': limit,
    };
  }
}

/// Clones the given [IApiQueryPaging] instance.
///
/// Returns a new [ApiQueryPaging] with identical values.
ApiQueryPaging cloneApiQueryPaging(IApiQueryPaging paging) {
  return ApiQueryPaging(
    offset: paging.offset,
    limit: paging.limit,
    cursor: paging.cursor,
  );
}
