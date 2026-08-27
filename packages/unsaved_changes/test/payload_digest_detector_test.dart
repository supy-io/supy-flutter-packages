import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum Fallback { other }

class Payload {
  Payload(this.build);

  Map<String, dynamic> Function() build;
}

void main() {
  PayloadDigestDetector<Payload, Fallback> build({
    Set<String> volatileKeys = const {},
    Object? Function(Object?)? normalize,
  }) =>
      PayloadDigestDetector<Payload, Fallback>(
        id: 'payload-digest',
        kind: Fallback.other,
        payloadOf: (p) => p.build(),
        volatileKeys: volatileKeys,
        normalize: normalize,
      );

  test('defaults to the fallback role', () {
    expect(build().role, DetectorRole.fallback);
  });

  test('reports nothing while the payload matches', () {
    final payload = Payload(() => {'a': 1, 'b': 'x'});
    final session = build().start(payload);

    expect(session.diff(payload), isEmpty);
  });

  test('reports a change when any value moves', () {
    var value = 1;
    final payload = Payload(() => {'a': value});
    final session = build().start(payload);

    value = 2;

    expect(session.diff(payload).single.kind, Fallback.other);
  });

  test('is independent of key order', () {
    var flip = false;
    final payload = Payload(
      () => flip ? {'b': 2, 'a': 1} : {'a': 1, 'b': 2},
    );
    final session = build().start(payload);

    flip = true;

    expect(session.diff(payload), isEmpty);
  });

  test('ignores volatile keys the surface changes on its own', () {
    var status = 'draft';
    final payload = Payload(() => {'status': status, 'total': 10});
    final session = build(volatileKeys: {'status'}).start(payload);

    status = 'saved';

    expect(session.diff(payload), isEmpty);
  });

  test('disables itself when the payload is not stable between two reads', () {
    var counter = 0;
    final payload = Payload(() => {'nonce': counter++});
    final session = build().start(payload);

    expect(
      session.diff(payload),
      isEmpty,
      reason: 'an unstable payload must not report a permanent phantom change',
    );
  });

  test('disables itself when the payload cannot be built', () {
    final payload = Payload(() => throw StateError('not ready'));
    final session = build().start(payload);

    expect(session.diff(payload), isEmpty);
  });

  test('reports nothing when the payload stops being buildable', () {
    var broken = false;
    final payload = Payload(() {
      if (broken) throw StateError('gone');

      return {'a': 1};
    });
    final session = build().start(payload);

    broken = true;

    expect(session.diff(payload), isEmpty);
  });

  test('descends into nested maps and lists', () {
    var nested = 1;
    final payload = Payload(
      () => {
        'items': [
          {'qty': nested},
        ],
      },
    );
    final session = build().start(payload);

    nested = 2;

    expect(session.diff(payload), hasLength(1));
  });

  test('normalize can make 1 and 1.0 the same value', () {
    Object? value = 1;
    final payload = Payload(() => {'qty': value});
    final session = build(
      normalize: (v) => v is num ? v.toDouble() : v,
    ).start(payload);

    value = 1.0;

    expect(session.diff(payload), isEmpty);
  });

  test('without normalize, 1 and 1.0 differ', () {
    Object? value = 1;
    final payload = Payload(() => {'qty': value});
    final session = build().start(payload);

    value = 1.0;

    expect(session.diff(payload), hasLength(1));
  });

  test('stringifies leaves it cannot encode', () {
    var value = const Duration(seconds: 1);
    final payload = Payload(() => {'span': value});
    final session = build().start(payload);

    expect(session.diff(payload), isEmpty);

    value = const Duration(seconds: 2);
    expect(session.diff(payload), hasLength(1));
  });
}
