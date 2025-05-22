import 'package:filterator/filterator.dart';
import 'package:test/test.dart';

class DummyConverter extends ApiStandardConverter {
  DummyConverter(super.query);
}

void main() {
  group('ApiStandardConverter', () {
    test('toQueryParameters throws UnsupportedError', () {
      final converter = DummyConverter(const ApiQuery());
      expect(converter.toQueryParameters, throwsUnsupportedError);
    });

    test('toRequestBody throws UnsupportedError', () {
      final converter = DummyConverter(const ApiQuery());
      expect(converter.toRequestBody, throwsUnsupportedError);
    });
  });
}
