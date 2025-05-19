// import 'dart:convert';
//
// import 'package:filterator/filterator.dart';
// import 'package:test/test.dart';
// import 'package:mockito/mockito.dart';
//
// // Mock classes
// class MockQuery<T> extends Mock implements IApiQuery<T> {}
//
// class MockConverter<T> extends Mock implements ApiStandardConverter<T> {
//
// }
//
// void main() {
//   group('CompositeConverter', () {
//     late MockQuery<dynamic> query;
//     late MockConverter<dynamic> mock1;
//     late MockConverter<dynamic> mock2;
//
//     setUp(() {
//       query = MockQuery<dynamic>();
//       mock1 = MockConverter<dynamic>(query);
//       mock2 = MockConverter<dynamic>(query);
//
//       when(mock1.toQueryParameters()).thenReturn(<String, String>{});
//       when(mock2.toQueryParameters()).thenReturn(<String, String>{});
//       when(mock1.toRequestBody()).thenReturn('');
//       when(mock2.toRequestBody()).thenReturn('');
//     });
//
//     test('merges query parameters from multiple converters', () {
//       when(mock1.toQueryParameters()).thenReturn({'a': '1', 'b': '2'});
//       when(mock2.toQueryParameters()).thenReturn({'b': '3', 'c': '4'});
//
//       final composite = CompositeConverter<dynamic>(
//         query: query,
//         converters: [mock1, mock2],
//       );
//
//       final result = composite.toQueryParameters();
//
//       expect(result, {
//         'a': '1',
//         'b': '3',
//         'c': '4',
//       });
//     });
//
//     test('merges request bodies from multiple converters', () {
//       when(mock1.toRequestBody()).thenReturn(jsonEncode({'x': 10, 'y': 20}));
//       when(mock2.toRequestBody()).thenReturn(jsonEncode({'y': 99, 'z': 42}));
//
//       final composite = CompositeConverter<dynamic>(
//         query: query,
//         converters: [mock1, mock2],
//       );
//
//       final result = jsonDecode(composite.toRequestBody());
//
//       expect(result, {
//         'x': 10,
//         'y': 99,
//         'z': 42,
//       });
//     });
//
//     test('handles invalid JSON gracefully', () {
//       when(mock1.toRequestBody()).thenReturn('invalid json');
//       when(mock2.toRequestBody()).thenReturn(jsonEncode({'valid': true}));
//
//       final composite = CompositeConverter<dynamic>(
//         query: query,
//         converters: [mock1, mock2],
//       );
//
//       final result = jsonDecode(composite.toRequestBody());
//
//       expect(result, {'valid': true});
//     });
//
//     test('returns empty outputs when no converters', () {
//       final composite = CompositeConverter<dynamic>(query: query, converters: []);
//
//       expect(composite.toQueryParameters(), {});
//       expect(composite.toRequestBody(), '{}');
//     });
//   });
// }
