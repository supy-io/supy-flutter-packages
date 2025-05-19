import 'query.dart';

/// Adds or modifies the offset value in an [IApiQuery] instance.
///
/// This function takes an existing [IApiQuery]
/// instance and an integer [offset],
/// and returns a new [IApiQuery] instance with the specified offset value.
/// If the original query does not have paging details, the function returns
/// the original query without modification.
IApiQuery<dynamic> offset(IApiQuery<dynamic> query, {required int offset}) {
  return query.copyWith(paging: query.paging?.copyWith(offset: offset));
}

/// Adds or modifies the limit value in an [IApiQuery] instance.
///
/// This function takes an existing [IApiQuery] instance and an integer [limit],
/// and returns a new [IApiQuery] instance with the specified limit value.
/// If the original query does not have paging details, the function returns
/// the original query without modification.
IApiQuery<dynamic> limit(IApiQuery<dynamic> query, {required int limit}) {
  return query.copyWith(paging: query.paging?.copyWith(limit: limit));
}

/// Extension methods for convenient modification of [IApiQuery] instances.
extension ExApiQuery on IApiQuery<dynamic> {
  /// Sets the limit value in the current [IApiQuery] instance.
  ///
  /// This extension method allows you to set the limit value directly on an
  /// [IApiQuery] instance without the need to use the [limit] function.
  IApiQuery<dynamic> setLimit(int value) => limit(this, limit: value);

  /// Sets the offset value in the current [IApiQuery] instance.
  ///
  /// This extension method allows you to set the offset value directly on an
  /// [IApiQuery] instance without the need to use the [offset] function.
  IApiQuery<dynamic> setOffset(int value) => offset(this, offset: value);
}
