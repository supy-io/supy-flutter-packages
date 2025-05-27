# Filterator
[![Pub Version](https://img.shields.io/pub/v/filterator)](https://pub.dev/packages/filterator)
![License](https://img.shields.io/badge/license-MIT-blue.svg) [![codecov](https://codecov.io/gh/supy-io/supy-flutter-packages/branch/main/graph/badge.svg?flag=filterator&token=V5WF4C83K7)](https://app.codecov.io/gh/supy-io/supy-flutter-packages/flags/filterator) ![Null safety](https://img.shields.io/badge/null%20safety-true-brightgreen)




API Query Builder for Dart, A powerful and flexible library for constructing structured API queries with support for filtering, ordering, paging, and seamless conversion to API-specific formats.

## Features ✨

- **Type-safe Query Building:** Create complex queries with fluent interface.
- **Standard Converters:** Convert queries to REST/GraphQL formats.
- **Custom Converters:** Implement domain-specific serialization.
- **Immutable API:** All operations return new query instances.
- **Nested Filter Groups:** Support for AND/OR/NOT logic with unlimited nesting.
- **Easily pluggable:** into any backend API format (Supy, GraphQL, OData, etc.)

## Installation 📦

Add to your `pubspec.yaml`:

```yaml
dependencies:
   filterator: ^0.1.3
```
## 🚀 Getting Started
#### Quick Start
Instead of manually constructing queries as raw **String** or **JSON** objects, this library introduces a typed query interface that allows you to express complex query logic using fluent, composable functions.
This approach offers a safer and more readable API for building queries, while remaining flexible enough to support multiple backends like REST, GraphQL, OData, or any other API format.
By defining your queries using this interface (e.g. ApiQuery, where, and, or, ordering, paginate, etc.), you can then pass them through your standardized converter, such as ODataConverter Example, to serialize them into the appropriate format (query parameters, request body, etc.) — fully decoupling query logic from transport format.


### 🔍 Simple Filters (Short Style)
```dart
final query = ApiQuery(
  filtering: and(
    filters: [
      where('email', 'contains', '@example.com'),
      wheres('status', 'in', ['active', 'pending']),
    ],
  ),
);
```

- ✅ Use **where()** for single value.
- ✅ Use **wheres()** for multiple values (like in, notIn)

###  🧱 Filters (Verbose Object Style)
```dart
final query = ApiQuery(
  filtering: and(
    filters: [
      ApiQueryFilter(
        field: 'email',
        operation: QueryOperation.contains,
        value: '@example.com',
      ),
      ApiQueryFilter(
        field: 'status',
        operation: QueryOperation.inList,
        values: ['active', 'pending'],
      ),
    ],
  ),
);
```
- 🧩 Useful when you need more control or dynamic values.


### 🔁  Nested Group Filters (AND + OR)
```dart
final query = ApiQuery(
  filtering: and(
    filters: [
      where('email', 'contains', '@example.com'),
    ],
    groups: [
      or(
        filters: [
          where('name', 'eq', 'John'),
          where('name', 'eq', 'Jane'),
        ],
      ),
    ],
  ),
);
```
-  ⚖️ Combine conditions: email contains AND (name = John OR name = Jane)

### 🔃 Ordering Results
```dart
final query = ApiQuery(
  ordering: [
    ordering('name', 'asc'),
    ordering('createdAt', 'desc'),
  ],
);
```
- 🔼 Sort results ascending or descending by any field

## 📄  Pagination
```dart
final query = ApiQuery(
  paging: paginate(limit: 20, offset: 0),
);
```
- 🔢 Control how many results to fetch and from where to start

### 🎯 Field Selection
```dart
final query = ApiQuery(
  selection: include(['id', 'name', 'status']),
  // or
  // selection: exclude(['internalNotes']),
);
```
- 📌 Choose what fields to include/exclude in the API response

## 🧩 Full Example: All Combined
```dart
final query = ApiQuery(
  filtering: and(
    filters: [
      where('email', 'contains', '@example.com'),
    ],
    groups: [
      or(
        filters: [
          where('name', 'eq', 'John'),
          where('name', 'eq', 'Jane'),
        ],
      ),
    ],
  ),
  ordering: [ordering('name', 'asc')],
  paging: paginate(limit: 20, offset: 0),
  selection: include(['items']),
);
```

🔄 Combines filtering, nested groups, ordering, paging, and selection


- ## Convert to your format
```dart
final converter = 
  SupyConverter(query) ,
  ODataConverter(query),
/// or any other customConverter
```
- ## Customize your query format
```dart
class CustomConverter extends ApiStandardConverter {
  CustomConverter(super.query);

  @override
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    /// your custom transformer here. for example
    if (query.filtering != null) {
      params['fields'] = query.filtering!.filters.map((e) => {e.value});
    }
    return params;
  }

  @override
  String toRequestBody() {
    /// your custom transformer here
    return '';
  }
}
```
-  #### As query parameters (for GET requests)
```dart
final params = converter.toQueryParameters();
```
- #### As JSON request body (for POST requests)
```dart
final body = converter.toRequestBody();
```

## 📚 API Reference

- ### ApiQuery Field Reference Table
| **Property** | **Type**                  | **Description**                                                                                                                               | **Example**                            |
| ------------ | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `filtering`  | `IApiQueryFilteringGroup` | Defines the **main filtering conditions** for the query. Can include `filters` (single conditions) and nested `groups` (AND/OR logic blocks). | `and([...])`, `or([...])`              |
| `ordering`   | `List<IApiQueryOrdering>` | Specifies how the results should be **sorted**. You define the field and direction (`asc` or `desc`).                                         | `ordering('name', 'asc')`              |
| `paging`     | `IApiQueryPaging`         | Used to define **pagination**: how many items to return (`limit`) and from which offset (`offset`).                                           | `paginate(limit: 10, offset: 0)`       |
| `selection`  | `IApiQuerySelection`      | Allows inclusion or exclusion of specific **fields** from the response.                                                                       | `include(['name'])`, `exclude(['id'])` |


- ### IApiQueryFilteringGroup Properties
| **Property** | **Type**                              | **Description**                                   | **Example**                                  |
| ------------ | ------------------------------------- | ------------------------------------------------- | -------------------------------------------- |
| `condition`  | `QueryGroupCondition` (`and` or `or`) | Logical operator to combine filters (`AND`/`OR`). | `and(...)`, `or(...)`                        |
| `filters`    | `List<IApiQueryFilter>`               | The individual field-level conditions to apply.   | `where('email', 'contains', '@example.com')` |
| `groups`     | `List<IApiQueryFilteringGroup>`       | Nested filtering groups for more complex logic.   | `groups: [or([...]), and([...])]`            |



- ### IApiQueryFilter Properties

| **Property** | **Type**         | **Description**                                                  | **Example**               |
| ------------ | ---------------- | ---------------------------------------------------------------- | ------------------------- |
| `field`      | `String`         | The name of the field to filter on.                              | `'email'`                 |
| `operation`  | `QueryOperation` | The type of comparison: `eq`, `neq`, `contains`, `inList`, etc.  | `QueryOperation.contains` |
| `value`      | `dynamic?`       | A single match value (used in most filters).                     | `'@example.com'`          |
| `values`     | `List<dynamic>?` | Used when filtering with multiple values (e.g., `in`, `not in`). | `['active', 'pending']`   |

- ### IApiQueryOrdering Properties


| **Property** | **Type**                            | **Description**                   | **Example** |
| ------------ | ----------------------------------- | --------------------------------- | ----------- |
| `field`      | `String`                            | The name of the field to sort by. | `'name'`    |
| `dir`        | `OrderingDirection` (`asc`, `desc`) | The sort direction.               | `'asc'`     |

- ### IApiQueryPaging Properties

| **Property** | **Type** | **Description**                        | **Example** |
| ------------ | -------- | -------------------------------------- | ----------- |
| `limit`      | `int`    | Maximum number of items to return.     | `limit: 20` |
| `offset`     | `int`    | The index of the first item to return. | `offset: 0` |
| `currsor`     | `String?`    | The index of the first item to return. | `currsor: 'A` |


- ### IApiQuerySelection Properties

| **Property** | **Type**       | **Description**                                    | **Example**                    |
| ------------ | -------------- | -------------------------------------------------- | ------------------------------ |
| `include`    | `List<String>` | Specifies the fields to include in the response.   | `include(['name', 'email'])`   |
| `exclude`    | `List<String>` | Specifies the fields to exclude from the response. | `exclude(['id', 'createdAt'])` |



### 🙌 Contributions
Feel free to fork, contribute, or suggest features. PRs are welcome!
