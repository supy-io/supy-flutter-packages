import 'package:querycraft/querycraft.dart';

import 'interfaces/interfaces.dart';

/// Interface defining metadata for a query result.
///
/// This interface outlines the structure of metadata associated
/// with a query result,
/// including the count and total number of items.
/// It provides a method to convert
/// the metadata to a map for easy serialization.
abstract interface class IApiQueryMetadata implements IMap<dynamic> {
  /// The count of items in the query result.
  int get count;

  /// The total number of items available.
  int get total;
}

/// Class representing metadata for a query result.
///
/// This class implements the [IApiQueryMetadata]
/// interface and represents metadata
/// associated with a query result.
/// It includes the count and total number of items,
/// and provides a method to convert the metadata
/// to a map for easy serialization.
class ApiQueryMetadata implements IApiQueryMetadata {
  /// Creates an instance of [ApiQueryMetadata]
  /// with the specified [count] and [total].
  ApiQueryMetadata({required this.count, required this.total});

  /// The count of items in the query result.
  @override
  final int count;

  /// The total number of items available.
  @override
  final int total;

  /// Returns an empty API query metadata instance.
  ///
  /// This static method creates and returns an instance of
  /// [ApiQueryMetadata] with
  /// count and total set to 0, representing an empty query result.
  static IApiQueryMetadata empty() => ApiQueryMetadata(count: 0, total: 0);

  /// Converts the metadata to a map representation.
  ///
  /// This method converts the metadata details into
  /// a map that can be easily serialized
  /// to JSON or used in API responses.
  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    return {'count': count, 'total': total};
  }
}
