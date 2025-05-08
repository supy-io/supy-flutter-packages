import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';

/// A callback function that determines whether an
/// item should be removed from the cart.
typedef RemoveCallBack<T> = bool Function(T item);

/// A reactive and extensible shopping cart that supports item grouping,
/// custom metadata, locking, expiration, and plugin extensions.
///
/// This class is designed for flexibility and use in state management
/// systems such as Provider, Riverpod, or GetX.
class FlexiCart<T extends ICartItem> extends ChangeNotifier
    with CartChangeNotifierDisposeMixin, CartStreamMixin<FlexiCart<T>> {
  /// Constructs a [FlexiCart] instance.
  ///
  /// - [items] is an optional initial map of items.
  /// - [groups] is an optional map of item groups.
  /// - [onDisposed] is a callback called on disposal.
  /// - [onAddItem] and [onDeleteItem] are callbacks for item operations.
  /// - [removeItemCondition] defines a custom condition to remove items.
  FlexiCart({
    Map<String, T>? items,
    Map<String, CartItemsGroup<T>>? groups,
    this.onDisposed,
    this.onAddItem,
    this.onDeleteItem,
    this.removeItemCondition,
  })  : _items = items ?? {},
        groups = groups ?? {};

  /// Callback triggered when the cart is disposed.
  final VoidCallback? onDisposed;

  /// Callback triggered when an item is added.
  final VoidCallback? onAddItem;

  /// Callback triggered when an item is deleted.
  final VoidCallback? onDeleteItem;

  /// Condition to determine whether an item should be removed.
  RemoveCallBack<T>? removeItemCondition;

  /// Internal storage for cart items.
  Map<String, T> _items;

  /// Storage for item groups.
  Map<String, CartItemsGroup<T>> groups;

  /// Optional note for the cart (e.g., special instructions).
  String? _note;

  /// Delivery timestamp.
  DateTime? _deliveredAt;

  /// Expiration timestamp of the cart.
  DateTime? _expiresAt;

  /// Whether to allow items with quantity zero in the cart.
  bool addZeroQuantity = false;

  /// Indicates if the cart is locked for editing.
  bool _isLocked = false;

  /// Internal logs of cart events.
  final List<String> _logs = [];

  /// Registered plugins for cart event hooks.
  final List<ICartPlugin<T>> _plugins = [];

  /// Returns all cart items as a map.
  Map<String, T> get items => _items;

  /// Returns all cart items as a list.
  List<T> get itemsList => _items.values.toList();

  /// Returns the note for the cart.
  String? get note => _note;

  /// Returns the delivery timestamp.
  DateTime? get deliveredAt => _deliveredAt;

  /// Indicates whether the cart is currently locked.
  bool get isLocked => _isLocked;

  /// Returns true if the cart has expired.
  bool get isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Returns the internal log entries.
  List<String> get logs => List.unmodifiable(_logs);

  /// Sets the cart to expire after the given duration from now.
  void setExpiration(Duration duration) {
    _expiresAt = DateTime.now().add(duration);
  }

  /// Locks the cart from being edited.
  void lock() => _isLocked = true;

  /// Unlocks the cart, allowing edits.
  void unlock() => _isLocked = false;

  /// Throws an exception if the cart is locked.
  void _checkLock() {
    if (_isLocked) throw StateError('Cart is locked.');
  }

  /// Logs a message with a timestamp.
  void _log(String message) {
    _logs.add('${DateTime.now().toIso8601String()} - $message');
  }

  /// Registers a plugin to be notified on cart changes.
  void registerPlugin(ICartPlugin<T> plugin) => _plugins.add(plugin);

  /// Notifies all registered plugins about a cart change.
  void _notifyPlugins() {
    for (final plugin in _plugins) {
      plugin.onCartChanged(this);
    }
  }

  /// Sets a note for the cart.
  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _note = note;
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated. Use [setNote] instead.
  @Deprecated('Use setNote() instead')
  set note(String? note) {
    _note = note;
    notifyListeners();
  }

  /// Sets the delivery timestamp.
  void setDeliveredAt(DateTime? deliveredAt,
      {bool shouldNotifyListeners = false}) {
    _deliveredAt = deliveredAt;
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated. Use [setDeliveredAt] instead.
  @Deprecated('Use setDeliveredAt() instead')
  set deliveredAt(DateTime? deliveredAt) {
    _deliveredAt = deliveredAt;
    notifyListeners();
  }

  /// Calculates the total price of items in the cart.
  double totalPrice() =>
      itemsList.fold(0, (sum, item) => sum + item.totalPrice());

  /// Calculates the total quantity of all items.
  double totalQuantity() =>
      itemsList.fold(0, (sum, item) => sum + item.notNullQty());

  /// Checks if any item in the cart has a very high quantity.
  bool get checkForLargeValue => itemsList.any((e) => e.notNullQty() >= 100);

  /// Returns true if the cart has any items.
  bool isNotEmpty() => _items.isNotEmpty;

  /// Returns true if the cart is empty.
  bool isEmpty() => _items.isEmpty;

  /// Adds a single item to the cart.
  ///
  /// If [increment] is true and the item already exists, quantity is added.
  void add(T item, {bool increment = false}) {
    _checkLock();
    _add(item, increment);
    emit(this);
    notifyListeners();
  }

  /// Adds multiple items to the cart.
  ///
  /// - [increment] adds quantities if item already exists.
  /// - [skipIfExist] skips items already in the cart.
  /// - [shouldNotifyListeners] determines if [notifyListeners] is called.
  void addItems(List<T> items,
      {bool increment = false,
      bool skipIfExist = false,
      bool shouldNotifyListeners = true}) {
    _checkLock();
    for (final item in items) {
      if (skipIfExist && _items.containsKey(item.key)) continue;
      _add(item, increment);
    }
    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Removes all items not included in the provided list.
  void removeItemsNotInList(List<T> items) {
    _checkLock();
    final keepKeys = items.map((e) => e.key).toSet();
    for (final item in itemsList) {
      if (!keepKeys.contains(item.key)) _delete(item);
    }
    emit(this);
    notifyListeners();
  }

  /// Deletes a single item from the cart.
  void delete(T item) {
    _checkLock();
    _delete(item);
    emit(this);
    notifyListeners();
  }

  /// Clears all items from the cart without affecting metadata.
  void resetItems({bool shouldNotifyListeners = true}) {
    _checkLock();
    groups.clear();
    _items.clear();
    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Fully resets the cart and its metadata.
  void reset({bool shouldNotifyListeners = true}) {
    _checkLock();
    groups.clear();
    _items.clear();
    _note = null;
    _deliveredAt = null;
    _expiresAt = null;
    addZeroQuantity = false;
    removeItemCondition = null;
    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Clears a specific item group by ID.
  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    groups.remove(groupId);
    _items.removeWhere((_, item) => item.group == groupId);
    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Returns true if the given group is empty.
  bool isItemsGroupEmpty(String groupId) => getItemsGroup(groupId).isEmpty;

  /// Returns true if the given group is not empty.
  bool isNotItemsGroupEmpty(String groupId) =>
      getItemsGroup(groupId).isNotEmpty;

  /// Gets the list of items for a specific group.
  List<T> getItemsGroup(String groupId) =>
      groups[groupId]?.items.values.toList() ?? [];

  /// Returns the count of items in a specific group.
  int getItemsGroupLength(String groupId) => getItemsGroup(groupId).length;

  /// Returns a clone of the cart with copied items and metadata.
  FlexiCart<T> clone() {
    return FlexiCart<T>(
      items: Map<String, T>.from(_items),
      groups: Map<String, CartItemsGroup<T>>.from(groups),
    )
      ..removeItemCondition = removeItemCondition
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      .._deliveredAt = _deliveredAt;
  }

  /// Casts the cart to a different item type [G].
  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
      items: _items.cast<String, G>(),
      groups: groups.map((k, v) => MapEntry(k, v.cast<G>())),
    );
  }

  /// Disposes of the cart and triggers [onDisposed].
  @override
  void dispose() {
    onDisposed?.call();
    disposeStream(); // call this if using the mixin's stream
    super.dispose();
  }

  /// Internal method to add an item and notify plugins.
  void _add(T item, bool increment) {
    final shouldDeleteZeroQty = !addZeroQuantity && item.quantity == 0;
    final shouldRemoveItem = removeItemCondition?.call(item) ?? false;

    if (shouldRemoveItem || item.quantity == null || shouldDeleteZeroQty) {
      _delete(item);
      return;
    }

    onAddItem?.call();
    _addToItems(item, increment: increment);
    _addToGroup(item);
    _log('Item added: ${item.key}');
    _notifyPlugins();
  }

  /// Adds an item to the item map.
  void _addToItems(T item, {bool increment = false}) {
    final key = item.key;
    if (increment && _items.containsKey(key)) {
      _items[key] = item
        ..quantity = item.notNullQty() + _items[key]!.notNullQty();
    } else {
      _items[key] = item;
    }
  }

  /// Adds an item to the appropriate group.
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

  /// Deletes an item from the item map and group.
  void _delete(T item) {
    _items.remove(item.key);
    _deleteFromGroup(item);
    onDeleteItem?.call();
    _log('Item removed: ${item.key}');
    _notifyPlugins();
  }

  /// Removes an item from its group.
  void _deleteFromGroup(T item) {
    final group = groups[item.group];
    if (group != null) {
      group.remove(item);
      if (group.items.isEmpty) groups.remove(item.group);
    }
  }
}

/// Interface for plugins that want to be notified when the cart changes.
abstract class ICartPlugin<T extends ICartItem> {
  /// Called when the cart is updated.
  void onCartChanged(FlexiCart<T> cart);
}
