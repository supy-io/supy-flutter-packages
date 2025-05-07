/// Enum representing the type of filter condition (AND or OR).
enum FilterConditionType {
  ///
  and,

  ///
  or
}

/// Enum representing the direction of ordering
/// in a query (ascending or descending).
enum QueryOrderDirection {
  ///
  asc,

  ///
  desc
}

/// Interface defining common query operations.
abstract class IQueryOperation {
  ///
  static late String inclusion;

  ///

  static late String notInclusion;

  ///

  static late String eq;

  ///

  static late String neq;

  ///

  static late String lt;

  ///

  static late String gt;

  ///

  static late String lte;

  ///

  static late String gte;

  ///

  static late String contains;

  ///

  static late String notContains;

  ///

  static late String containsAny;

  ///

  static late String containsAll;

  ///

  static late String like;

  ///

  static late String startsWith;

  ///

  static late String endsWith;

  ///

  static late String search;
}

/// Mixin providing inclusion-related query operations.
mixin InclusionOperation on IQueryOperation {
  ///

  static const String inclusion = 'in';

  ///

  static const String notInclusion = 'not-in';
}

/// Mixin providing strict equality-related query operations.
mixin StrictEqualityOperation on IQueryOperation {
  ///
  static const String eq = 'eq';

  ///
  static const String neq = 'neq';
}

/// Mixin providing range equality-related query operations.
mixin RangeEqualityOperation on IQueryOperation {
  ///

  static const String lt = 'lt';

  ///

  static const String gt = 'gt';

  ///

  static const String lte = 'lte';

  ///

  static const String gte = 'gte';
}

/// Mixin providing single containment-related query operations.
mixin SingleContainmentOperation on IQueryOperation {
  ///

  static const String contains = 'contains';

  ///

  static const String notContains = 'not-contains';
}

/// Mixin providing multi-containment-related query operations.
mixin MultiContainmentOperation on IQueryOperation {
  ///

  static const String containsAny = 'contains-any';

  ///

  static const String containsAll = 'contains-all';
}

/// Mixin providing text search-related query operations.
mixin TextSearchOperation on IQueryOperation {
  ///
  static const String like = 'like';

  ///

  static const String startsWith = 'starts-with';

  ///

  static const String endsWith = 'ends-with';

  ///

  static const String search = 'search';
}

/// Class implementing common query operations.
class QueryOperation extends IQueryOperation
    implements
        InclusionOperation,
        StrictEqualityOperation,
        RangeEqualityOperation,
        SingleContainmentOperation,
        MultiContainmentOperation,
        TextSearchOperation {
  ///

  static String get inclusion => InclusionOperation.inclusion;

  ///

  static String get notInclusion => InclusionOperation.notInclusion;

  ///

  static String get like => TextSearchOperation.like;

  ///

  static String get eq => StrictEqualityOperation.eq;

  ///

  static String get neq => StrictEqualityOperation.neq;

  ///

  static String get lt => RangeEqualityOperation.lt;

  ///

  static String get gt => RangeEqualityOperation.gt;

  ///

  static String get lte => RangeEqualityOperation.lte;

  ///

  static String get gte => RangeEqualityOperation.gte;

  ///

  static String get contains => SingleContainmentOperation.contains;

  ///

  static String get notContains => SingleContainmentOperation.notContains;

  ///

  static String get containsAny => MultiContainmentOperation.containsAny;

  ///

  static String get containsAll => MultiContainmentOperation.containsAll;

  ///

  static String get startsWith => TextSearchOperation.startsWith;

  ///

  static String get endsWith => TextSearchOperation.endsWith;

  ///

  static String get search => TextSearchOperation.search;

  ///

  static List<String> get values => [
        inclusion,
        notInclusion,
        like,
        eq,
        neq,
        lt,
        gt,
        lte,
        gte,
        contains,
        notContains,
        containsAny,
        containsAll,
        startsWith,
        endsWith,
        search,
      ];
}
