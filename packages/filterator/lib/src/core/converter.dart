import 'package:filterator/src/core/query.dart';

/// A base class for converting API queries to standard-specific formats.
abstract class ApiStandardConverter {
  /// Creates an instance of [ApiStandardConverter] with the given [query].
  const ApiStandardConverter(this.query);

  ///
  final IApiQuery query;

  /// Convert to standard-specific parameters
  Map<String, dynamic> toQueryParameters() {
    throw UnsupportedError('Not implemented');
  }

  /// Convert to standard-specific request body (for GraphQL/POST)
  String toRequestBody() {
    throw UnsupportedError('Not implemented');
  }
}
