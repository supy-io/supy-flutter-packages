## 0.1.2-beta.2
- Deleted unused files:
  - `packages/filterator/lib/src/core/field_types.dart`
  - `packages/filterator/lib/src/core/selection.dart`
  - `packages/filterator/test/query_tests/query_operators_test.dart` (functionality moved)
  - `packages/filterator/test/query_tests/query_tests.dart`
  - `packages/filterator/test/query_tests/query_tools_test.dart` (functionality moved)
- Updated `packages/filterator/lib/src/core/query.dart` to remove the static `cast` method from `ApiQuery`.
- Updated `packages/filterator/test/fiterator_test.dart` to import tests from the new `core` directory.
- Created new test files in `packages/filterator/test/core/`:
  - `converter_tests.dart`: Basic tests for `ApiStandardConverter`.
  - `query_test.dart`: Tests for `ApiQuery` construction and `toMap` serialization.
  - `paging_operators_test.dart`: (Renamed from `query_tests/paging_operators_test.dart`) Tests for paging helper functions and `ApiQuery` `toMap` with complex filtering.
  - `query_filter_test.dart`: Tests for `ApiQueryFilter` construction and `toMap` serialization, including `cloneApiQueryFilter`.
  - `query_metadata_test.dart`: Tests for `ApiQueryMetadata` construction, `empty` factory, and `toMap`.
  - `query_filter_group_test.dart`: Tests for `ApiQueryFilteringGroup` construction, shortcut constructors, `toMap` serialization with nested groups, and `cloneApiQueryFilteringGroup`.
  - `query_operators_test.dart`: Tests for helper functions for paging, filter groups, filters, ordering, and selections.
  - `query_operation_test.dart`: Tests for `QueryOperationStringExtension`, `QueryOperationExtension`, and `QueryOrderDirectionExtension`.
  - `query_ordering_test.dart`: Tests for `ApiQueryOrdering` construction, `toMap`, and `cloneApiQueryOrdering`.
  - `query_response_test.dart`: Tests for `ApiQueryResponse` construction, `empty` factory, and `toMap`.
  - `query_paging_test.dart`: Tests for `ApiQueryPaging` construction, factories, `copyWith`, `toMap`, and `cloneApiQueryPaging`.
  - `query_selections_test.dart`: Tests for `ApiQuerySelection` construction, cloning, `copyWith`, and `toMap` serialization.
- Updated `packages/filterator/lib/src/core/core.dart` to remove the export of `field_types.dart`.


## 0.1.1-beta.1
- Updating the dependency version in `README.md` to `^0.1.0-beta.1`.
- Removing extra newlines and whitespace from code examples in `README.md`.
- Updating the package description in `pubspec.yaml` for better clarity.

## 0.1.0-beta.1

### 🚀 Features - Initial Release

* **Dynamic Query Interface (`ApiQuery`)**
  Introduced a flexible, type-safe API query builder interface supporting:

    * Simple filters with `where()` and `wheres()` helpers
    * Nested filtering using logical groups: `and()` / `or()`
    * Full control over filtering conditions, ordering, paging, and selection

* **Standardized Query Filters (`ApiQueryFilter`)**

    * Supports operations like: `eq`, `neq`, `lt`, `gt`, `contains`, `inList`, etc.
    * Provides both short-form and verbose syntax for maximum flexibility

* **Pagination Support (`paginate()`)**

    * Easily define `limit` and `offset` for paginated requests

* **Field Selection (`include()` / `exclude()`)**

    * Explicitly include or exclude response fields for lightweight API calls

* **Sorting (`ordering()`)**

    * Order results by any field with direction control (ascending or descending)

* **SupyConverter**

    * Converts `ApiQuery` objects to:

        * Query parameters (`toQueryParameters()`)
        * JSON body payloads (`toRequestBody()`)
        * Nested map structures (`body()`)
    * Ready to integrate with Supy-style or similar RESTful backends
    * Encoder toggle to support different formats (e.g., REST, GraphQL, OData)

* **Extensibility**

    * Designed to be extensible for future formats and standards (GraphQL, OData, etc.)
    * Easily plug in other converters following the same interface
