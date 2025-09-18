import 'dart:convert';

import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storageKey = 'test_cart_v1';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('1. save and restore cart with items', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(
        key: 'i1',
        id: 'id1',
        name: 'n1',
        price: 10,
        quantity: 2,
      ));

    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);
    cart.reset();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored!.items.length, equals(1));
    expect(restored.items['i1']!.notNullQty(), equals(2));
  });

  test('2. restore empty cart if nothing saved', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored, isNull);
  });

  test('3. deleteFromPrefs works', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'i', id: 'id1', name: 'n', price: 1));
    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);

    await cart.deleteFromCache(key: storageKey, provider: provider);
    expect(prefs.getString(storageKey), isNull);
  });

  test('4. save/restore cart with metadata', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>()..setMetadataEntry('user', 'Alice');
    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);
    cart.reset();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored!.metadata['user'], equals('Alice'));
  });

  test('5. add multiple items and restore', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>()
      ..addItems([
        MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 5),
        MyCartItem(key: 'i2', id: 'id2', name: 'n2', price: 3),
      ]);

    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);
    cart.reset();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored!.items.length, equals(2));
  });

  test('6. reset cart clears items', () async {
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1))
      ..reset();
    expect(cart.items, isEmpty);
  });

  test('7. set and restore note', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final cart = FlexiCart<MyCartItem>()..setNote('Hello');
    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);
    cart.reset();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored!.note, equals('Hello'));
  });

  test('8. set and restore deliveredAt', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);
    final date = DateTime.utc(2024);
    final cart = FlexiCart<MyCartItem>()..setDeliveredAt(date);
    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);
    cart.reset();

    final restored = await cart.restoreFromCache(
        key: storageKey, itemFromJson: MyCartItem.fromMap, provider: provider);
    expect(restored!.deliveredAt, equals(date));
  });

  test('9. cart totalPrice calculation', () {
    final cart = FlexiCart<MyCartItem>()
      ..addItems([
        MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 5, quantity: 2),
        MyCartItem(key: 'i2', id: 'id2', name: 'n2', price: 3, quantity: 4),
      ]);
    expect(cart.totalPrice(), equals(5 * 2 + 3 * 4));
  });

  test('10. cart totalQuantity calculation', () {
    final cart = FlexiCart<MyCartItem>()
      ..addItems([
        MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1, quantity: 2),
        MyCartItem(key: 'i2', id: 'id2', name: 'n2', price: 1, quantity: 4),
      ]);
    expect(cart.totalQuantity(), equals(6));
  });

  test('11. addZeroQuantity false removes zero qty items', () {
    final cart = FlexiCart<MyCartItem>()
      ..addZeroQuantity = false
      ..add(
          MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1, quantity: 0));
    expect(cart.items, isEmpty);
  });

  test('12. isNotEmpty / isEmpty check', () {
    final cart = FlexiCart<MyCartItem>();
    expect(cart.isEmpty(), isTrue);
    cart.add(MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1));
    expect(cart.isNotEmpty(), isTrue);
  });

  test('13. add and delete item', () {
    final cart = FlexiCart<MyCartItem>();
    final item = MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1);
    cart.add(item);
    expect(cart.items.containsKey('i1'), isTrue);
    cart.delete(item);
    expect(cart.items.containsKey('i1'), isFalse);
  });

  test('14. groups: add items and check group', () {
    final cart = FlexiCart<MyCartItem>();
    final item = MyCartItem(
        key: 'i1',
        group: 'g1',
        groupName: 'G1',
        id: 'id1',
        name: 'n1',
        price: 1);
    cart.add(item);
    expect(cart.groups.containsKey('g1'), isTrue);
    expect(cart.getItemsGroup('g1').length, equals(1));
  });

  test('15. clear group removes items', () {
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'i1', group: 'g1', id: 'id1', name: 'n1', price: 1))
      ..clearItemsGroup('g1');
    expect(cart.groups.containsKey('g1'), isFalse);
    expect(cart.items.containsKey('i1'), isFalse);
  });

  test('16. clone creates separate instance', () {
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1));
    final clone = cart.clone();
    expect(clone.items.length, equals(1));
    clone.reset();
    expect(cart.items.length, equals(1)); // original unaffected
  });

  test('17. cast works with generic type', () {
    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 1));
    final casted = cart.cast<MyCartItem>();
    expect(casted.items.length, equals(1));
  });

  test('18. apply and remove exchange rate', () {
    final cart = FlexiCart<MyCartItem>();
    final item = MyCartItem(key: 'i1', id: 'id1', name: 'n1', price: 10);
    cart.add(item);
    const currency = CartCurrency(code: 'USD', rate: 2);
    cart.applyExchangeRate(currency);
    expect(cart.items['i1']!.price, equals(20));
    cart.removeExchangeRate();
    expect(cart.items['i1']!.price, equals(10));
  });

  test('19. promoCode set and retrieve', () {
    final cart = FlexiCart<MyCartItem>()..setPromoCode('DISCOUNT');
    expect(cart.promoCode, equals('DISCOUNT'));
  });

  test('save and restore cart via SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);

    final cart = FlexiCart<MyCartItem>();

    final item1 = MyCartItem(
        key: 'i1',
        group: 'g1',
        groupName: 'G1',
        price: 5,
        quantity: 3,
        id: 'id1',
        name: 'name1');
    final item2 = MyCartItem(
      key: 'i2',
      group: 'g1',
      groupName: 'G1',
      price: 2,
      id: 'id2',
      name: 'name2',
    );

    cart
      ..add(item1)
      ..add(item2)
      ..setNote('Test note')
      ..setDeliveredAt(DateTime.utc(2024));

    // Save
    await cart.saveToCache(
      key: storageKey,
      itemToJson: (i) => i.toMap(),
      provider: provider,
    );

    cart.reset();

    // Inspect raw stored string (optional)
    final stored = prefs.getString(storageKey);
    expect(stored, isNotNull);

    expect(cart.items, isEmpty);
    // Restore
    final restored = await cart.restoreFromCache(
      key: storageKey,
      itemFromJson: MyCartItem.fromMap,
      provider: provider,
    );

    expect(restored, isNotNull);
    final r = restored!;
    expect(r.items.length, equals(2));
    expect(r.items.containsKey('i1'), isTrue);
    expect(r.items.containsKey('i2'), isTrue);

    final ri1 = r.items['i1']!;
    expect(ri1.price, equals(5.0));
    expect(ri1.notNullQty(), equals(3));

    expect(r.note, equals('Test note'));
    expect(r.deliveredAt, isNotNull);
    expect(r.deliveredAt!.year, equals(2024));
  });

  test('deleteFromPrefs removes entry', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);

    final cart = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'x', price: 1, id: 'id3', name: 'name3'));
    await cart.saveToCache(
        key: storageKey, itemToJson: (i) => i.toMap(), provider: provider);

    // ensure exists
    expect(prefs.getString(storageKey), isNotNull);

    // delete
    await cart.deleteFromCache(key: storageKey, provider: provider);
    expect(prefs.getString(storageKey), isNull);
  });
  test('deleteFromPrefs works on multiple keys', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);

    final cart1 = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'a', id: 'id1', name: 'n1', price: 1));
    final cart2 = FlexiCart<MyCartItem>()
      ..add(MyCartItem(key: 'b', id: 'id2', name: 'n2', price: 2));

    await cart1.saveToCache(
        key: 'cart1', itemToJson: (i) => i.toMap(), provider: provider);
    await cart2.saveToCache(
        key: 'cart2', itemToJson: (i) => i.toMap(), provider: provider);

    await cart1.deleteFromCache(key: 'cart1', provider: provider);

    expect(prefs.getString('cart1'), isNull);
    expect(prefs.getString('cart2'), isNotNull);
  });

  test('updating item after restore works correctly', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);

    final cart = FlexiCart<MyCartItem>();
    final item = MyCartItem(key: 'i1', id: 'id1', name: 'name1', price: 5);
    cart.add(item);

    await cart.saveToCache(
      key: storageKey,
      itemToJson: (i) => i.toMap(),
      provider: provider,
    );

    cart.reset();

    final restored = await cart.restoreFromCache(
      key: storageKey,
      itemFromJson: MyCartItem.fromMap,
      provider: provider,
    );

    restored!.add(MyCartItem(key: 'i2', id: 'id2', name: 'name2', price: 3));

    expect(restored.items.length, equals(2));
    expect(restored.items.containsKey('i2'), isTrue);
  });

  test('restoreFromCache with overrideThis updates current cart', () async {
    // Original cart with some items
    final cart = FlexiCart<MyCartItem>();
    final originalItem = MyCartItem(
      key: 'original',
      price: 10,
      id: 'id0',
      name: 'Original Item',
    );
    cart.add(originalItem);

    // Save a "cached" cart state
    final cachedCart = FlexiCart<MyCartItem>();
    final cachedItem = MyCartItem(
      key: 'cached',
      price: 99,
      id: 'id1',
      name: 'Cached Item',
    );
    cachedCart
      ..add(cachedItem)
      ..setNote('Restored note')
      ..setMetadataEntry('foo', 'bar');

    final cachedJson = jsonEncode({
      'items': cachedCart.items.map((k, v) => MapEntry(k, v.toMap())),
      'note': cachedCart.note,
      'metadata': cachedCart.metadata,
      'addZeroQuantity': cachedCart.addZeroQuantity,
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = SharedPrefsProvider(prefs);

    await prefs.setString(storageKey, cachedJson);

    // Confirm original cart has only original item
    expect(cart.items.containsKey('original'), isTrue);
    expect(cart.items.containsKey('cached'), isFalse);

    // Restore from cache with overrideThis=true
    final restored = await cart.restoreFromCache(
      key: storageKey,
      itemFromJson: MyCartItem.fromMap,
      provider: provider,
      overrideThis: true,
    );

    // After override, the original cart instance should now include cached item
    expect(cart.items.containsKey('original'), isFalse); // original cleared
    expect(cart.items.containsKey('cached'), isTrue);
    expect(cart.note, equals('Restored note'));
    expect(cart.metadata['foo'], equals('bar'));

    // The returned cart should also be correct
    expect(restored, isNotNull);
    expect(restored!.items.containsKey('cached'), isTrue);
    expect(restored.items.containsKey('original'), isFalse);
  });
}

class SharedPrefsProvider extends ICartCacheProvider {
  SharedPrefsProvider(this.prefs);

  final SharedPreferences prefs;

  @override
  Future<void> delete(String key) async {
    await prefs.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await prefs.setString(key, value);
  }
}

/// Minimal concrete item implementing ICartItem.
class MyCartItem extends ICartItem {
  MyCartItem({
    required super.id,
    required super.name,
    required this.key,
    required super.price,
    super.group = 'default',
    super.groupName = 'Default',
    super.quantity = 1,
  });

  factory MyCartItem.fromMap(Map<String, dynamic> m) => MyCartItem(
        key: m['key'] as String,
        group: m['group'] as String? ?? 'default',
        groupName: m['groupName'] as String? ?? 'Default',
        price: (m['price'] as num).toDouble(),
        quantity:
            m['quantity'] != null ? (m['quantity'] as num).toDouble() : null,
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
      );
  @override
  final String key;

  Map<String, dynamic> toMap() => {
        'key': key,
        'group': super.group,
        'groupName': groupName,
        'price': price,
        'quantity': quantity,
        'id': id,
        'name': name,
        'metadata': metadata,
      };

  @override
  String toString() =>
      'MyCartItem(key:$key, group:${super.group}, price:$price, qty:$quantity,'
      ' id:$id,'
      ' name:$name)';
}
