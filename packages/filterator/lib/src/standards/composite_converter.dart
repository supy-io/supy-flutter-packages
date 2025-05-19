import 'dart:convert';

import 'package:filterator/filterator.dart';

typedef ConverterFactory<T> =
    ApiStandardConverter<T> Function(IApiQuery<T> query);
typedef QueryParamMerger =
    Map<String, dynamic> Function(
      Map<String, dynamic> accumulated,
      Map<String, dynamic> current,
    );
typedef BodyMerger =
    Map<String, dynamic> Function(
      Map<String, dynamic> accumulated,
      Map<String, dynamic> current,
    );

class CompositeConverter<T> implements ApiStandardConverter<T> {
  const CompositeConverter({
    required this.query,
    required this.converterFactories,
    this.paramMerger = _defaultParamMerger,
    this.bodyMerger = _defaultBodyMerger,
    this.onConverterError,
  });
  @override
  final IApiQuery<T> query;
  final List<ConverterFactory<T>> converterFactories;
  final QueryParamMerger paramMerger;
  final BodyMerger bodyMerger;
  final void Function(Object error, StackTrace stack)? onConverterError;

  /// Default parameter merging strategy: later converters override earlier ones
  static Map<String, dynamic> _defaultParamMerger(
    Map<String, dynamic> accumulated,
    Map<String, dynamic> current,
  ) => {...accumulated, ...current};

  /// Default body merging strategy: deep merge with override
  static Map<String, dynamic> _defaultBodyMerger(
    Map<String, dynamic> accumulated,
    Map<String, dynamic> current,
  ) => _deepMerge(accumulated, current);

  List<ApiStandardConverter<T>> get _converters {
    return converterFactories.map((factory) => factory(query)).toList();
  }

  @override
  Map<String, dynamic> toQueryParameters() {
    return _converters.fold<Map<String, dynamic>>({}, _mergeParamsSafe);
  }

  @override
  String toRequestBody() {
    final merged = _converters.fold<Map<String, dynamic>>({}, _mergeBodySafe);
    return jsonEncode(merged);
  }

  Map<String, dynamic> _mergeParamsSafe(
    Map<String, dynamic> accumulated,
    ApiStandardConverter<T> converter,
  ) {
    try {
      final params = converter.toQueryParameters();
      return paramMerger(accumulated, params);
    } catch (e, s) {
      onConverterError?.call(e, s);
      return accumulated;
    }
  }

  Map<String, dynamic> _mergeBodySafe(
    Map<String, dynamic> accumulated,
    ApiStandardConverter<T> converter,
  ) {
    try {
      final bodyStr = converter.toRequestBody();
      final bodyMap = jsonDecode(bodyStr) as Map<String, dynamic>;
      return bodyMerger(accumulated, bodyMap);
    } catch (e, s) {
      onConverterError?.call(e, s);
      return accumulated;
    }
  }

  /// Deep merge implementation for nested maps
  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final result = Map<String, dynamic>.from(a);

    for (final entry in b.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic> &&
          result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Creates a new converter with additional query transformations
  CompositeConverter<T> transformQuery(
    IApiQuery<T> Function(IApiQuery<T> query) transformer,
  ) {
    return CompositeConverter<T>(
      query: transformer(query),
      converterFactories: converterFactories,
      paramMerger: paramMerger,
      bodyMerger: bodyMerger,
      onConverterError: onConverterError,
    );
  }

  /// Creates a filtered converter that only includes specific parameters
  CompositeConverter<T> filterParameters(bool Function(String key) predicate) {
    return CompositeConverter<T>(
      query: query,
      converterFactories: converterFactories,
      paramMerger: (accumulated, current) {
        final filtered = current..removeWhere((k, _) => !predicate(k));
        return paramMerger(accumulated, filtered);
      },
      bodyMerger: bodyMerger,
      onConverterError: onConverterError,
    );
  }
}
