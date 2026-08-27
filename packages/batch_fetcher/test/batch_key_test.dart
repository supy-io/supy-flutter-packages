// The whole point of BatchKey is that it cannot repeat the bug it replaces:
// a key holding a collection compares by identity, so it mints a new scope on
// every rebuild.
import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:test/test.dart';

enum _Season { winter, spring }

void main() {
  group('value equality', () {
    test('two keys with equal scalar parts are the same key', () {
      expect(
        BatchKey(const ['loc_1', 'ret_1']),
        BatchKey(const ['loc_1', 'ret_1']),
      );
      expect(
        BatchKey(const ['loc_1']).hashCode,
        BatchKey(const ['loc_1']).hashCode,
      );
    });

    test('different parts, order or arity give different keys', () {
      expect(BatchKey(const ['a']), isNot(BatchKey(const ['b'])));
      expect(BatchKey(const ['a', 'b']), isNot(BatchKey(const ['b', 'a'])));
      expect(BatchKey(const ['a']), isNot(BatchKey(const ['a', 'b'])));
    });

    test('none is a key like any other', () {
      expect(BatchKey.none, BatchKey(const <Object?>[]));
      expect(BatchKey.none, isNot(BatchKey(const [null])));
    });

    test('is not equal to a non-key', () {
      const Object notAKey = 'a';
      expect(BatchKey(const ['a']) == notAKey, isFalse);
    });
  });

  group('normalisation', () {
    test('a UTC and a local DateTime for the same instant are one key', () {
      final instant = DateTime.utc(2026, 3, 14, 15, 9, 26);
      expect(
        BatchKey([instant]),
        BatchKey([instant.toLocal()]),
        reason: 'DateTime.== compares the isUtc flag, which is never what a '
            'batching key means',
      );
    });

    test('different instants stay different keys', () {
      expect(
        BatchKey([DateTime.utc(2026)]),
        isNot(BatchKey([DateTime.utc(2027)])),
      );
    });

    test('enums compare by value, not identity', () {
      expect(
          BatchKey(const [_Season.winter]), BatchKey(const [_Season.winter]));
      expect(
        BatchKey(const [_Season.winter]),
        isNot(BatchKey(const [_Season.spring])),
      );
    });

    test('keys nest', () {
      expect(
        BatchKey([
          BatchKey(const ['a']),
          'b'
        ]),
        BatchKey([
          BatchKey(const ['a']),
          'b'
        ]),
      );
    });

    test('accepts every scalar kind', () {
      expect(
        BatchKey(const [null, 1, 1.5, 'x', true]),
        BatchKey(const [null, 1, 1.5, 'x', true]),
      );
    });
  });

  group('collection parts', () {
    test('a List part is rejected, naming the identity trap', () {
      expect(
        () => BatchKey(const [
          ['a'],
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('compares by identity'),
          ),
        ),
      );
    });

    test('a Set or Map part is rejected too', () {
      expect(() => BatchKey(const [<String>{}]), throwsArgumentError);
      expect(() => BatchKey(const [<String, String>{}]), throwsArgumentError);
    });

    test('an arbitrary object is rejected', () {
      expect(() => BatchKey(const [Object()]), throwsArgumentError);
    });
  });

  test('toString names its parts', () {
    expect(BatchKey(const ['a', 1]).toString(), 'BatchKey([a, 1])');
  });
}
