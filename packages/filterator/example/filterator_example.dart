import 'package:filterator/filterator.dart';

void main() {
  final query = ApiQuery(
    /// 🔍 Filtering section: where you define conditions on fields
    filtering: and(
      filters: [
        // ✅ SHORT STYLE: Using the helper function `where(field, op, value)`
        where('email', 'contains', '@example.com'),

        // ✅ SHORT STYLE: Multiple values (e.g., for "in" or "not in" operations)
        wheres('status', 'in', ['active', 'pending']),

        // ✅ VERBOSE STYLE: Directly constructing the filter object
        ApiQueryFilter(
          field: 'email',
          // Field to filter on
          operation: QueryOperation.contains,
          // Operation to use (e.g., contains)
          value: '@example.com', // Single value
        ),
        ApiQueryFilter(
          field: 'status',
          operation: QueryOperation.inList, // Use `inList` for multiple values
          values: ['active', 'pending'], // Multiple values
        ),
      ],

      /// 🔁 GROUPING section: Nested filter groups with their own logic
      groups: [
        or(
          filters: [
            where('name', 'eq', 'John'), // Name equals "John"
            where('name', 'eq', 'Jane'), // OR Name equals "Jane"
          ],
        ),
      ],
    ),

    /// 🔃 ORDERING: Sort the results
    ordering: [
      ordering('name', 'asc'), // Sort by name in ascending order
    ],

    /// 📄 PAGINATION: Limit number of results per request
    paging: paginate(
      limit: 20,
      offset: 0,
    ), // Return 20 items starting from index 0
  );
  final supyConverter = SupyConverter(query);

  print(supyConverter.toRequestBody());
  print(supyConverter.toQueryParameters());
}
