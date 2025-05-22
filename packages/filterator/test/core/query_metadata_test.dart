import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

void main() {
  group('ApiQueryMetadata', () {
    test('creates instance with count and total', () {
      final metadata = ApiQueryMetadata(count: 5, total: 10);

      expect(metadata.count, 5);
      expect(metadata.total, 10);
    });

    test('empty() returns instance with count and total 0', () {
      final emptyMetadata = ApiQueryMetadata.empty();

      expect(emptyMetadata.count, 0);
      expect(emptyMetadata.total, 0);
      expect(emptyMetadata, isA<ApiQueryMetadata>());
    });

    test('toMap returns correct map representation', () {
      final metadata = ApiQueryMetadata(count: 3, total: 7);
      final map = metadata.toMap();

      expect(map, {'count': 3, 'total': 7});
    });
  });
}
