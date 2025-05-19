## \[1.0.0] -Beta Initial Release

### 🚀 Features

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
