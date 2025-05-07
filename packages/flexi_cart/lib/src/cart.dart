import 'package:flexi_cart/src/cart_item.dart';
import 'package:flexi_cart/src/cart_items_group.dart';
import 'package:flexi_cart/src/mixins.dart';
import 'package:flutter/material.dart';

/// A callback that determines whether an item should be removed from the cart.
typedef RemoveCallBack<T> = bool Function(T item);

/// A generic, reactive cart management class that supports:
/// - Item grouping
/// - Quantity control
/// - Note-taking
/// - Delivery tracking
/// - Conditional removal
/// - Cloning
class FlexiCart<T extends ICartItem> extends ChangeNotifier
    with CartChangeNotifierDisposeMixin {
  /// Creates a new instance of [FlexiCart].
  ///
  /// [items] provides initial items in the cart.
  /// [groups] provides initial item groups.
  /// [removeItemCondition] is a custom rule to remove certain items.
  /// [onDisposed] is called when the cart is disposed.
  FlexiCart({
    Map<String, T>? items,
    Map<String, CartItemsGroup<T>>? groups,
    this.onDisposed,
    this.removeItemCondition,
  })  : _items = items ?? <String, T>{},
        groups = groups ?? <String, CartItemsGroup<T>>{};

  /// Callback executed when the cart is disposed.
  final VoidCallback? onDisposed;

  /// A condition to determine if an item should be removed.
  RemoveCallBack<T>? removeItemCondition;

  /// A map of item groups.
  Map<String, CartItemsGroup<T>> groups;

  /// Internal map of cart items keyed by their unique identifier.
  Map<String, T> _items;

  /// Exposes the internal map of items.
  Map<String, T> get items => _items;

  /// List of all items currently in the cart.
  List<T> get itemsList => items.values.toList();

  String? _note;
  DateTime? _deliveredAt;

  /// Optional note or comment attached to the cart.
  String? get note => _note;

  /// Sets a note for the cart and optionally notifies listeners.
  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _note = note;
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated: Use [setNote] instead.
  @Deprecated('Use [setNote] instead')
  set note(String? note) {
    _note = note;
    notifyListeners();
  }

  /// Optional delivery date/time associated with the cart.
  DateTime? get deliveredAt => _deliveredAt;

  /// Sets the delivery date/time and optionally notifies listeners.
  void setDeliveredAt(
    DateTime? deliveredAt, {
    bool shouldNotifyListeners = false,
  }) {
    _deliveredAt = deliveredAt;
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated: Use [setDeliveredAt] instead.
  @Deprecated('Use [setDeliveredAt] instead')
  set deliveredAt(DateTime? deliveredAt) {
    _deliveredAt = deliveredAt;
    notifyListeners();
  }

  /// If true, allows adding items with quantity of 0.
  bool addZeroQuantity = false;

  /// Calculates the total price of all items in the cart.
  double totalPrice() =>
      itemsList.map((e) => e.totalPrice()).fold(0, (a, b) => a + b);

  /// Calculates the total quantity of all items in the cart.
  double totalQuantity() =>
      itemsList.map((e) => e.notNullQty()).fold(0, (a, b) => a + b);

  /// Checks whether any item in the cart has a quantity of 100 or more.
  bool get checkForLargeValue => itemsList.any((e) => e.notNullQty() >= 100);

  /// Returns true if the cart has at least one item.
  bool isNotEmpty() => items.isNotEmpty;

  /// Returns true if the cart is empty.
  bool isEmpty() => items.isEmpty;

  /// Adds a single item to the cart.
  ///
  /// If [increment] is true, adds to the existing quantity.
  void add(T item, {bool increment = false}) {
    _add(item, increment);
    notifyListeners();
  }

  /// Adds multiple items to the cart.
  ///
  /// [increment] adds to existing quantities.
  /// [skipIfExist] skips items already in the cart.
  /// [shouldNotifyListeners] controls whether listeners are notified.
  void addItems(
    List<T> items, {
    bool increment = false,
    bool skipIfExist = false,
    bool shouldNotifyListeners = true,
  }) {
    for (final item in items) {
      if (skipIfExist && this.items.containsKey(item.key)) continue;
      _add(item, increment);
    }
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Removes items not found in the provided list.
  void removeItemsNotInList(List<T> items) {
    final keysToKeep = items.map((e) => e.key).toSet();
    for (final item in itemsList) {
      if (!keysToKeep.contains(item.key)) {
        _delete(item);
      }
    }
    notifyListeners();
  }

  /// Deletes an item from the cart.
  void delete(T item) {
    _delete(item);
    notifyListeners();
  }

  /// Clears all items and groups from the cart.
  void resetItems({bool shouldNotifyListeners = true}) {
    groups = {};
    _items = {};
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Fully resets the cart to its initial state.
  void reset({bool shouldNotifyListeners = true}) {
    groups = {};
    _items = {};
    _note = null;
    _deliveredAt = null;
    addZeroQuantity = false;
    removeItemCondition = null;
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Clears a specific group of items.
  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    groups.remove(groupId);
    items.removeWhere((_, value) => value.group == groupId);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Returns true if a specific group has no items.
  bool isItemsGroupEmpty(String groupId) => getItemsGroup(groupId).isEmpty;

  /// Returns true if a specific group has one or more items.
  bool isNotItemsGroupEmpty(String groupId) =>
      getItemsGroup(groupId).isNotEmpty;

  /// Returns a list of items in the specified group.
  List<T> getItemsGroup(String groupId) =>
      groups[groupId]?.items.values.toList() ?? [];

  /// Returns the number of items in a group.
  int getItemsGroupLength(String groupId) => getItemsGroup(groupId).length;

  /// Returns a deep copy of the cart.
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

  /// Casts this cart to a different item type.
  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
      items: items.cast<String, G>(),
      groups: groups.map((key, value) => MapEntry(key, value.cast<G>())),
    );
  }

  @override
  void dispose() {
    onDisposed?.call();
    super.dispose();
  }

  // --- Private Helpers ---

  void _add(T item, bool increment) {
    final shouldDeleteZeroQty = !addZeroQuantity && item.quantity == 0;
    final shouldRemoveItem = removeItemCondition?.call(item) ?? false;

    if (shouldRemoveItem || item.quantity == null || shouldDeleteZeroQty) {
      _delete(item);
      return;
    }

    _addToItems(item, increment: increment);
    _addToGroup(item);
  }

  void _addToItems(T item, {bool increment = false}) {
    final key = item.key;
    if (increment && items.containsKey(key)) {
      items[key] = item
        ..quantity = item.notNullQty() + items[key]!.notNullQty();
    } else {
      items[key] = item;
    }
  }

  void _addToGroup(T item) {
    groups.putIfAbsent(
      item.group,
      () => CartItemsGroup<T>(
        id: item.group,
        name: item.groupName,
      ),
    );
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
      if (group.items.isEmpty) groups.remove(item.group);
    }
  }
}
