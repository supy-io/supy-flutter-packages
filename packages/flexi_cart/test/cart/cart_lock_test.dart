import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('Cart Locking', () {
    late FlexiCart<MockItem> cart;
    final item = MockItem(id: '1', name: 'item', price: 10);

    setUp(() {
      cart = FlexiCart<MockItem>();
    });

    test('cart lock prevents modification', () {
      final cart = FlexiCart<MockItem>();
      final item = MockItem(id: '1', name: 'item-name', price: 10);

      cart.lock();
      expect(cart.isLocked, isTrue);

      expect(() => cart.add(item), throwsException);
      expect(() => cart.delete(item), throwsException);

      cart.unlock();
      expect(cart.isLocked, isFalse);

      cart.add(item);
      expect(cart.items.length, 1);
    });

    test('Allows modification after unlock', () {
      cart
        ..lock()
        ..unlock();
      expect(() => cart.add(item), returnsNormally);
    });
    test('lock() is idempotent', () {
      cart
        ..lock()
        ..lock()
        ..lock();
      expect(cart.isLocked, isTrue);
    });
    test('unlock() is idempotent', () {
      cart
        ..lock()
        ..unlock()
        ..unlock()
        ..unlock();
      expect(cart.isLocked, isFalse);
    });

    test('Maintains lock state after reset', () {
      cart
        ..lock()
        ..reset();
      expect(cart.isLocked, isFalse);
    });
    test('toggleLock() locks and unlocks correctly', () {
      cart.toggleLock();
      expect(cart.isLocked, isTrue);
      expect(cart.history.last, contains('Cart locked'));

      cart.toggleLock();
      expect(cart.isLocked, isFalse);
      expect(cart.history.last, contains('Cart unlocked'));
    });

    test('toggleLock() with shouldNotifyListeners = true', () {
      cart.toggleLock(shouldNotifyListeners: true);
      expect(cart.history.last, contains('notified: true'));
    });

    test('resetLock() forces unlock regardless of state', () {
      cart
        ..lock()
        ..resetLock();
      expect(cart.isLocked, isFalse);
      expect(cart.history.last, contains('Cart lock reset'));
    });

    test('resetLock() with shouldNotifyListeners = true', () {
      cart
        ..lock()
        ..resetLock(shouldNotifyListeners: true);
      expect(cart.history.last, contains('notified: true'));
    });
  });
}
