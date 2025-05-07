import 'interfaces/interfaces.dart';

///
abstract interface class IApiQuerySelection
    implements ICloneable<ApiQuerySelection>, IMap<dynamic> {
  ///
  List<String> get excludes;

  ///
  List<String> get includes;

  ///
  IApiQuerySelection copyWith({
    List<String>? excludes,
    List<String>? includes,
  });
}

///
class ApiQuerySelection implements IApiQuerySelection {
  ///
  const ApiQuerySelection({this.excludes = kEmpty, this.includes = kEmpty});

  @override
  final List<String> excludes;
  @override
  final List<String> includes;

  ///
  static const List<String> kEmpty = [];

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

  @override
  ApiQuerySelection clone() =>
      ApiQuerySelection(excludes: excludes, includes: includes);

  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    assert(
      excludes.isEmpty || includes.isEmpty,
      'excludes and includes are empty',
    );
    assert(
      excludes.isNotEmpty || includes.isNotEmpty,
      'excludes and includes are NotEmpty',
    );
    return {
      if (excludes.isNotEmpty) 'exclude': excludes,
      if (includes.isNotEmpty) 'include': includes,
    };
  }
}
