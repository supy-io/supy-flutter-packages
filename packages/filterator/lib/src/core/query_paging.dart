import 'package:filterator/src/core/interfaces/interfaces.dart';

/// Interface defining the paging details for an API query.
///
/// This interface outlines the structure of paging details in an API query,
/// specifying the offset and limit for fetching data.
abstract interface class IApiQueryPaging
    implements ICloneable<ApiQueryPaging>, IMap<dynamic> {
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
  /// The [offset] and [limit] parameters allow modifying
  /// the offset and limit values while keeping other values intact.
  IApiQueryPaging copyWith({int? offset, int? limit});
}

/// Class representing paging details in an API query.
///
/// An instance of this class defines the paging details in an API query,
/// specifying the offset and limit parameters for result pagination.
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
  /// The [offset] and [limit] parameters allow modifying the offset and limit
  /// values while keeping other values intact.
  @override
  IApiQueryPaging copyWith({int? offset, int? limit, String? cursor}) {
    return ApiQueryPaging(
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      cursor: cursor ?? this.cursor,
    );
  }

  /// Creates a clone of the current [ApiQueryPaging] instance.
  @override
  ApiQueryPaging clone() =>
      ApiQueryPaging(offset: offset, limit: limit, cursor: cursor);

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
