import 'package:querycraft/querycraft.dart';

import 'interfaces/interfaces.dart';

/// Interface defining the structure of an API query filtering operation.
///
/// This interface outlines the components of an API query filtering operation,
/// including the field to filter by, the filter operation, and the matching
/// value. It provides methods to clone the filtering operation and convert
/// it to a map.
abstract class IApiQueryFiltering
    implements ICloneable<IApiQueryFiltering>, IMap<dynamic> {
  /// Gets the field to filter by in the API query.
  String get by;

  /// Gets the filter operation to be applied in the API query.
  String get op;

  /// Gets the value used for matching in the API query.
  Object? get match;
}

/// Class representing a filtering operation in an API query.
///
/// This class implements the [IApiQueryFiltering] interface and represents
/// a filtering operation in an API query. It includes the field to filter by,
/// the filter operation, and the matching value. It also provides methods
/// for cloning the filtering operation and converting it to a map.
class ApiQueryFiltering implements IApiQueryFiltering {
  /// Creates a new instance of [ApiQueryFiltering] with specified details.
  ///
  /// The constructor takes the [by], [op], and [match] details for the
  /// filtering operation. It creates an immutable instance representing a
  /// filtering operation in an API query.
  ApiQueryFiltering({
    required this.by,
    required this.op,
    required this.match,
  }) : assert(
          QueryOperation.values.contains(op),
          'QueryOperation Values is not containing your operator',
        );

  /// The field to filter by in the API query.
  @override
  final String by;

  /// The filter operation to be applied in the API query.
  @override
  final String op;

  /// The value used for matching in the API query.
  @override
  final Object? match;

  /// Creates a clone of the filtering operation instance.
  ///
  /// This method returns a clone of the original [ApiQueryFiltering] instance,
  /// producing an identical but separate instance.
  @override
  ApiQueryFiltering clone() {
    return ApiQueryFiltering(
      by: by,
      op: op,
      match: match,
    );
  }

  /// Converts the filtering operation instance to a map representation.
  ///
  /// This method converts the filtering operation details into a map that can
  /// be easily serialized to JSON or used in API requests.
  @override
  Map<String, dynamic> toMap({bool encode = true}) {
    return {'by': by, 'op': op, 'match': match};
  }
}
