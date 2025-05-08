import 'dart:async';

import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flexi_cart_test.dart';

/// A test notifier that uses the [CartChangeNotifierDisposeMixin].
class TestNotifier with ChangeNotifier, CartChangeNotifierDisposeMixin {
  void trigger() {
    notifyListeners();
  }
}

void main() {
  group('CartChangeNotifierDisposeMixin', () {
    test('notifyListeners works before dispose', () {
      final notifier = TestNotifier();
      var called = false;

      notifier
        ..addListener(() {
          called = true;
        })
        ..trigger();
      expect(called, isTrue);
    });

    test('notifyListeners does not trigger after dispose', () {
      final notifier = TestNotifier();
      var called = false;

      notifier
        ..addListener(() {
          called = true;
        })
        ..dispose()
        ..trigger();
      expect(called, isFalse);
    });

    test('disposed flag is set after dispose', () {
      final notifier = TestNotifier();
      expect(notifier.disposed, isFalse);

      notifier.dispose();
      expect(notifier.disposed, isTrue);
    });
  });
  test('emit is called when adding/removing items (via stream)', () async {
    final cart = FlexiCart<MockItem>();
    final item = MockItem(id: '1', name: 'item-name', price: 10);

    final completer = Completer<void>();

    cart.stream.listen((event) {
      completer.complete();
    });

    cart.add(item);
    await completer.future; // ensures the stream emitted
    expect(true, isTrue); // stream event received
  });
}
