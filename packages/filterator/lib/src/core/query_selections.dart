import 'package:filterator/src/core/interfaces/interfaces.dart';

/// Interface defining the selection behavior in an API query.
///
/// This interface allows specifying which fields should be included or excluded
/// when querying data from an API. It is typically used to optimize data retrieval
/// by selecting only the necessary fields.
///
/// It extends [ICloneable] to allow cloning, and [IMap] to allow conversion
/// to a map (e.g., for serialization).
abstract interface class IApiQuerySelection
    implements ICloneable<ApiQuerySelection>, IMap<dynamic> {
  /// List of field names to exclude from the result.
  List<String> get excludes;

  /// List of field names to include in the result.
  List<String> get includes;

  /// Returns a copy of this selection instance with optional new values
  /// for [excludes] and [includes].
  IApiQuerySelection copyWith({List<String>? excludes, List<String>? includes});
}

/// Concrete implementation of [IApiQuerySelection].
///
/// Allows inclusion or exclusion of specific fields in an API query result.
/// Only one of `includes` or `excludes` should be used at a time to avoid ambiguity.
///
/// This class is immutable and supports cloning and conversion to a map.
class ApiQuerySelection implements IApiQuerySelection {
  /// Creates a new [ApiQuerySelection] instance with optional includes or excludes.
  ///
  /// Either [includes] or [excludes] can be specified. If both are provided,
  /// asserts will enforce that one must be empty.
  const ApiQuerySelection({this.excludes = kEmpty, this.includes = kEmpty});

  /// List of field names to be excluded from the result.
  @override
  final List<String> excludes;

  /// List of field names to be included in the result.
  @override
  final List<String> includes;

  /// An empty constant list used as a default value.
  static const List<String> kEmpty = [];

  /// Returns a new [IApiQuerySelection] instance with updated [excludes] and/or [includes].
  ///
  /// This method does not mutate the existing instance; it returns a new one
  /// with the provided overrides or existing values.
  @override
  IApiQuerySelection copyWith({
    List<String>? excludes,
    List<String>? includes,
  }) {
    return ApiQuerySelection(
      excludes: excludes ?? this.excludes,
      includes: includes ?? this.includes,
    );
  }

  /// Creates a deep copy of this selection instance.
  ///
  /// This method is useful when a separate but identical copy is required.
  @override
  ApiQuerySelection clone() =>
      ApiQuerySelection(excludes: excludes, includes: includes);

  /// Converts the selection to a [Map] format suitable for API serialization.
  ///
  /// The resulting map will contain either an `exclude` or `include` key, but not both.
  ///
  /// Assertions:
  /// - If `excludes` is not empty, `includes` must be empty, and vice versa.
  @override
  Map<String, dynamic> toMap() {
    assert(
      excludes.isEmpty || includes.isEmpty,
      'Only one of `excludes` or `includes` should be non-empty.',
    );
    assert(
      excludes.isNotEmpty || includes.isNotEmpty,
      'At least one of `excludes` or `includes` must be provided.',
    );
    return {
      if (excludes.isNotEmpty) 'exclude': excludes,
      if (includes.isNotEmpty) 'include': includes,
    };
  }
}
