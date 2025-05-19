import 'package:filterator/src/core/interfaces/interfaces.dart';
import 'package:filterator/src/core/query_metadata.dart';

/// Interface defining a generic API query response.
///
/// This interface outlines the structure of
/// a generic API query response, including the data and metadata.
abstract class IApiQueryResponse<T> implements IMap<dynamic> {
  /// The list of data elements in the API query response.
  List<T> get data;

  /// Metadata associated with the API query response,
  /// providing additional information about the data.
  IApiQueryMetadata get metadata;
}

/// Class representing a complete API query response.
///
/// An instance of this class represents a complete API query response,
/// encapsulating both the data and metadata associated with the query result.
class ApiQueryResponse<T> implements IApiQueryResponse<T> {
  /// Creates an [ApiQueryResponse]
  /// instance with the specified data and metadata.
  ApiQueryResponse({required this.data, required this.metadata});

  @override
  final List<T> data;
  @override
  final IApiQueryMetadata metadata;

  /// Returns an empty API query response.
  ///
  /// This is a convenient factory method for creating an [ApiQueryResponse]
  /// instance with empty data and metadata.
  static IApiQueryResponse<dynamic> empty() {
    return ApiQueryResponse(data: [], metadata: ApiQueryMetadata.empty());
  }

  /// Converts the API query response to a JSON-like map.
  ///
  /// The resulting map includes entries for
  /// both the data and metadata components of the response.
  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'metadata': metadata.toMap()};
  }
}
