import 'package:filterator/src/core/query.dart';

abstract class ApiStandardConverter {
  const ApiStandardConverter(this.query);

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
