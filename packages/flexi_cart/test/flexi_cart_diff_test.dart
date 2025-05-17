import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flexi_cart_test.dart';

void main() {
  group('CartDiff', () {
    test('returns empty diff when maps are equal', () {
      final item = MockItem(id: '1', name: 'Test', price: 10);
      final oldItems = {'1': item};
      final newItems = {'1': item};

      final diff = calculateCartDiff(oldItems, newItems);

      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
      expect(diff.updated, isEmpty);
      expect(diff.isEmpty, isTrue);
    });

    test('detects added items', () {
      final item1 = MockItem(id: '1', name: 'Test1', price: 10);
      final item2 = MockItem(id: '2', name: 'Test2', price: 20);
      final oldItems = {'1': item1};
      final newItems = {'1': item1, '2': item2};

      final diff = calculateCartDiff(oldItems, newItems);

      expect(diff.added, contains(item2));
      expect(diff.removed, isEmpty);
      expect(diff.updated, isEmpty);
      expect(diff.isEmpty, isFalse);
    });

    test('detects removed items', () {
      final item1 = MockItem(id: '1', name: 'Test1', price: 10);
      final item2 = MockItem(id: '2', name: 'Test2', price: 20);
      final oldItems = {'1': item1, '2': item2};
      final newItems = {'1': item1};

      final diff = calculateCartDiff(oldItems, newItems);

      expect(diff.added, isEmpty);
      expect(diff.removed, contains(item2));
      expect(diff.updated, isEmpty);
    });

    test('detects updated items', () {
      final item1Old = MockItem(id: '1', name: 'Test', price: 10);
      final item1New =
          MockItem(id: '1', name: 'Test', price: 10, quantityVal: 3);

      final oldItems = {'1': item1Old};
      final newItems = {'1': item1New};

      final diff = calculateCartDiff(oldItems, newItems);

      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
      expect(diff.updated, contains(item1New));
    });

    test('detects added, removed, and updated together', () {
      final itemOld = MockItem(id: '1', name: 'Old', price: 10);
      final itemUpdated =
          MockItem(id: '1', name: 'Old', price: 10, quantityVal: 2);
      final itemAdded = MockItem(id: '2', name: 'New', price: 20);

      final oldItems = {'1': itemOld};
      final newItems = {'1': itemUpdated, '2': itemAdded};

      final diff = calculateCartDiff(oldItems, newItems);

      expect(diff.added, contains(itemAdded));
      expect(diff.removed, isEmpty);
      expect(diff.updated, contains(itemUpdated));
    });
  });
}
