// // lib/src/standards/graphql/graphql_converter.dart
//
// import '../../../filterator.dart';
//
// class GraphQLConverter<T> extends ApiStandardConverter<T> {
//   const GraphQLConverter(super.query);
//
//   @override
//   String toRequestBody() {
//     final buffer = StringBuffer();
//
//     // Build query structure
//     buffer.writeln('query {');
//     buffer.write('  ${_typeName(T)}(');
//     _writeArguments(buffer);
//     buffer.writeln(') {');
//     _writeSelection(buffer);
//     buffer.writeln('  }');
//     buffer.writeln('}');
//
//     return buffer.toString();
//   }a
//
//   void _writeArguments(StringBuffer buffer) {
//     final args = <String>[];
//
//     if (query.filtering != null) {
//       args.add('filter: {${_buildFilter(query.filtering!)}}');
//     }
//
//     if (query.ordering != null) {
//       args.add('sort: [${_buildSort()}]');
//     }
//
//     if (query.paging != null) {
//       args.add('first: ${query.paging!.limit}');
//       if (query.paging!.cursor != null) {
//         args.add('after: "${query.paging!.cursor}"');
//       }
//     }
//
//     buffer.write(args.join(', '));
//   }
//
//   String _buildFilter(IApiQueryFilteringGroup<T> group) {
//     return group.filtering
//         .map((f) {
//           switch (f.operation) {
//             case QueryOperation.equals:
//               return '${f.field}: {eq: ${_graphqlValue(f.value)}}';
//             case QueryOperation.inList:
//               return '${f.field}: {in: [${f.values!.map(_graphqlValue).join(',')}]}';
//             // Handle other operations...
//           }
//         })
//         .join(', ');
//   }
//
//   String _graphqlValue(dynamic value) {
//     if (value is String) return '"$value"';
//     return value.toString();
//   }
// }
