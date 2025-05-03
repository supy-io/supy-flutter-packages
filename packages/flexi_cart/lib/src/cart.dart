import 'package:flutter/material.dart';

import 'cart_item.dart';
import 'cart_items_group.dart';

typedef RemoveCallBack<T> = bool Function(T item);

class FlexiCart<T extends ICartItem> extends ChangeNotifier {
  FlexiCart({
    Map<String, T>? items,
    Map<String, CartItemsGroup<T>>? groups,
    this.onDisposed,
    this.removeItemCondition,
  })  : _items = items ?? <String, T>{},
        groups = groups ?? <String, CartItemsGroup<T>>{};

  final VoidCallback? onDisposed;
  RemoveCallBack<T>? removeItemCondition;

  Map<String, CartItemsGroup<T>> groups;

  Map<String, T> _items;

  Map<String, T> get items => _items;

  List<T> get itemsList => items.values.toList();

  String? _note;

  String? get note => _note;

  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _note = note;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void setDeliveredAt(DateTime? deliveredAt,
      {bool shouldNotifyListeners = false}) {
    _deliveredAt = deliveredAt;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  @Deprecated("You use [setNote] instead of it ")
  set note(String? note) {
    _note = note;
    notifyListeners();
  }

  DateTime? _deliveredAt;

  DateTime? get deliveredAt => _deliveredAt;

  bool addZeroQuantity = false;

  @Deprecated("You use [setDeliveredAt] instead of it ")
  set deliveredAt(DateTime? deliveredAt) {
    _deliveredAt = deliveredAt;
    notifyListeners();
  }

  double totalPrice() => itemsList.map((e) => e.totalPrice()).fold<double>(
        0,
        (value, element) => value + element,
      );

  double totalQuantity() => itemsList
      .map((e) => e.notNullQty())
      .fold<double>(0, (value, element) => value + element);

  bool get checkForLargeValue {
    return itemsList.any((p0) => p0.notNullQty() >= 100);
  }

  bool isNotEmpty() => items.isNotEmpty;

  bool isEmpty() => items.isEmpty;

  void add(T item, {bool increment = false}) {
    _add(item, increment);
    notifyListeners();
  }

  void _add(item, bool increment) {
    final shouldDeleteZeroQty = (!addZeroQuantity && item.quantity == 0);
    final shouldRemoveItem = removeItemCondition?.call(item) ?? false;

    if (shouldRemoveItem) {
      _delete(item);
      return;
    }

    if (item.quantity == null || shouldDeleteZeroQty) {
      _delete(item);
      return;
    }

    _addToItems(item, increment: increment);
    _addToGroup(item);
  }

  void addItems(
    List<T> items, {
    bool increment = false,
    bool skipIfExist = false,
    bool shouldNotifyListeners = true,
  }) {
    for (T item in items) {
      if (skipIfExist && this.items.containsKey(item.key)) {
        continue;
      }
      _add(item, increment);
    }
    if (shouldNotifyListeners) notifyListeners();
  }

  void removeItemsNotInList(List<T> items) {
    final map = items.map((e) => e.key);

    for (final item in itemsList) {
      if (map.contains(item.key)) {
        continue;
      }

      _delete(item);
    }

    notifyListeners();
  }

  void delete(T item) {
    _delete(item);

    notifyListeners();
  }

  void resetItems({bool shouldNotifyListeners = true}) {
    groups = {};
    _items = {};
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void reset({bool shouldNotifyListeners = true}) {
    groups = {};
    _items = {};
    _note = null;
    addZeroQuantity = false;
    _deliveredAt = null;
    removeItemCondition = null;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void _addToItems(T item, {bool increment = false}) {
    final key = item.key;
    if (increment && items.containsKey(item.key)) {
      items[key] = item
        ..quantity = item.notNullQty() + items[key]!.notNullQty();
    } else {
      items[key] = item;
    }
  }

  void _addToGroup(T item) {
    if (!groups.containsKey(item.group)) {
      final cartItemsGroup = CartItemsGroup<T>(
        id: item.group,
        name: item.groupName,
      );
      groups[item.group] = cartItemsGroup;
    }

    groups[item.group]!.add(item);
  }

  void _delete(T item) {
    items.remove(item.key);
    _deleteFromGroup(item);
  }

  void _deleteFromGroup(T item) {
    final group = groups[item.group];
    if (group != null) {
      group.remove(item);
      if (group.items.isEmpty) {
        groups.remove(item.group);
      }
    }
  }

  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    groups.remove(groupId);
    items.removeWhere(
      (key, value) => value.group == groupId,
    );
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  bool isItemsGroupEmpty(String groupId) {
    return getItemsGroup(groupId).isEmpty;
  }

  bool isNotItemsGroupEmpty(String groupId) {
    return getItemsGroup(groupId).isNotEmpty;
  }

  List<T> getItemsGroup(String groupId) =>
      groups[groupId]?.items.values.toList() ?? [];

  int getItemsGroupLength(String groupId) => getItemsGroup(groupId).length;

  FlexiCart<T> clone() {
    return FlexiCart<T>(
      items: Map.from(items),
      groups: Map.from(groups),
    )
      ..removeItemCondition = removeItemCondition
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      .._deliveredAt = _deliveredAt;
  }

  @override
  void dispose() {
    onDisposed?.call();
    super.dispose();
  }

  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
        items: items.cast<String, G>(),
        groups: groups.map((key, value) => MapEntry(key, value.cast<G>())));
  }
}
