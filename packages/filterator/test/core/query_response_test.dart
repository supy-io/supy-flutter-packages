import 'package:filterator/src/core/query_metadata.dart';
import 'package:filterator/src/core/query_response.dart';
import 'package:test/test.dart';

class DummyMetadata implements IApiQueryMetadata {
  @override
  Map<String, dynamic> toMap() => {'dummy': true};

  @override
  int get count => throw UnimplementedError();

  @override
  int get total => throw UnimplementedError();
}

void main() {
  group('ApiQueryResponse', () {
    test('ApiQueryResponse empty should produce correct JSON', () {
      final emptyResponse = ApiQueryResponse.empty();

      final expectedJson = {
        'data': <dynamic>[],
        'metadata': {'count': 0, 'total': 0},
      };

      expect(emptyResponse.toMap(), equals(expectedJson));
    });
    test('constructor initializes data and metadata', () {
      final metadata = DummyMetadata();
      final response = ApiQueryResponse<String>(
        data: ['item1', 'item2'],
        metadata: metadata,
      );

      expect(response.data, ['item1', 'item2']);
      expect(response.metadata, metadata);
    });

    test('empty factory returns empty data and metadata', () {
      final emptyResponse = ApiQueryResponse.empty();

      expect(emptyResponse.data, isEmpty);
      expect(emptyResponse.metadata, isA<ApiQueryMetadata>());
    });

    test('toMap returns correct map representation', () {
      final metadata = DummyMetadata();
      final response = ApiQueryResponse<String>(
        data: ['item1'],
        metadata: metadata,
      );

      final map = response.toMap();

      expect(map, {
        'data': ['item1'],
        'metadata': {'dummy': true},
      });
    });
    test('ApiQueryResponse with data should produce correct JSON', () {
      final responseWithData = ApiQueryResponse<String>(
        data: ['item1', 'item2'],
        metadata: ApiQueryMetadata(count: 2, total: 10),
      );

      final expectedJson = {
        'data': ['item1', 'item2'],
        'metadata': {'count': 2, 'total': 10},
      };

      expect(responseWithData.toMap(), equals(expectedJson));
    });
  });
}
