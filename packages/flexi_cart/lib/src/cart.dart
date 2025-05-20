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

  /// Custom metadata storage.
  final Map<String, dynamic> _metadata = {};

  /// Returns a read-only view of the metadata.
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

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

  /// Currency if needed for the cart.
  CartCurrency? _cartCurrency;

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
  void setExpiration(Duration duration, {bool shouldNotifyListeners = false}) {
    _expiresAt = DateTime.now().add(duration);
    _log(
      'Cart has been set to expire at: $_expiresAt',
      notified: shouldNotifyListeners,
    );
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Sets a metadata key-value pair.
  void setMetadata(
    String key,
    dynamic value, {
    bool shouldNotifyListeners = true,
  }) {
    _metadata[key] = value;
    _log('Metadata set: $key = $value', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// get metadata value by key
  D? getMetadata<D>(String key) => _metadata[key] as D?;

  /// Removes a metadata entry.
  void removeMetadata(String key, {bool shouldNotifyListeners = true}) {
    if (_metadata.containsKey(key)) {
      _metadata.remove(key);
      _log('Metadata removed: $key', notified: shouldNotifyListeners);
      if (shouldNotifyListeners) notifyListeners();
    }
  }

  /// Locks the cart from being edited.
  void lock({bool shouldNotifyListeners = false}) {
    _isLocked = true;
    _log('Cart has been locked', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Unlocks the cart, allowing edits.
  void unlock({bool shouldNotifyListeners = false}) {
    _isLocked = false;
    _log('Cart has been locked', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Throws an exception if the cart is locked.
  void _checkLock() {
    if (_isLocked) {
      final error = StateError('Cart is locked.');
      _notifyOnErrorPlugins(error, StackTrace.current);
      throw error;
    }
  }

  /// Logs a message with a timestamp.
  void _log(String message, {bool notified = false}) {
    _logs.add('$message - {notified: $notified}');
  }

  /// Registers a plugin to be notified on cart changes.
  void registerPlugin(ICartPlugin<T> plugin) => _plugins.add(plugin);

  /// Notifies all registered plugins about a cart change.
  void _notifyOnChangedPlugins() {
    for (final plugin in _plugins) {
      plugin.onChange(this);
    }
  }

  /// Notifies all registered plugins about a cart error.
  void _notifyOnErrorPlugins(Object error, StackTrace stackTrace) {
    for (final plugin in _plugins) {
      plugin.onError(this, error, stackTrace);
    }
  }

  /// Notifies all registered plugins about a cart close.
  void _notifyOnClosePlugins() {
    for (final plugin in _plugins) {
      plugin.onClose(this);
    }
  }

  /// Sets a note for the cart.
  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _note = note;
    _log('Set Note with: $note', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated. Use [setNote] instead.
  @Deprecated('Use setNote() instead')
  set note(String? note) {
    _note = note;
    _log('Set Note with: $note', notified: true);
    notifyListeners();
  }

  /// Sets the delivery timestamp.
  void setDeliveredAt(
    DateTime? deliveredAt, {
    bool shouldNotifyListeners = false,
  }) {
    _deliveredAt = deliveredAt;
    _log('Set Delivered at: $deliveredAt', notified: shouldNotifyListeners);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deprecated. Use [setDeliveredAt] instead.
  @Deprecated('Use setDeliveredAt() instead')
  set deliveredAt(DateTime? deliveredAt) {
    _deliveredAt = deliveredAt;

    _log('Set Delivered at: $deliveredAt', notified: true);
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
  void add(
    T item, {
    bool increment = false,
    bool shouldNotifyListeners = true,
  }) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot add new item after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();
    _add(item, increment);
    emit(this);
    _log(
      'Item added: ${item.key}',
      notified: shouldNotifyListeners,
    );
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Adds multiple items to the cart.
  ///
  /// - [increment] adds quantities if item already exists.
  /// - [skipIfExist] skips items already in the cart.
  /// - [shouldNotifyListeners] determines if [notifyListeners] is called.
  void addItems(
    List<T> items, {
    bool increment = false,
    bool skipIfExist = false,
    bool shouldNotifyListeners = true,
  }) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot add new items after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();
    for (final item in items) {
      if (skipIfExist && _items.containsKey(item.key)) continue;
      _add(item, increment);
    }
    emit(this);
    _log(
      'Items have been added: $items',
      notified: shouldNotifyListeners,
    );
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Removes all items not included in the provided list.
  void removeItemsNotInList(
    List<T> items, {
    bool shouldNotifyListeners = true,
  }) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot remove items not in list after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();
    final keepKeys = items.map((e) => e.key).toSet();
    for (final item in itemsList) {
      if (!keepKeys.contains(item.key)) _delete(item);
    }
    emit(this);
    _log(
      'Items have been removed: $items',
      notified: shouldNotifyListeners,
    );
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Deletes a single item from the cart.
  void delete(T item, {bool shouldNotifyListeners = true}) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot delete item after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();
    _delete(item);
    emit(this);
    _log(
      'Item has been removed: ${item.key}',
      notified: shouldNotifyListeners,
    );
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Clears all items from the cart without affecting metadata.
  void resetItems({bool shouldNotifyListeners = true}) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot reset items after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();
    _log(
      'Items have been reset: $itemsList',
      notified: shouldNotifyListeners,
    );
    groups.clear();
    _items.clear();
    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Fully resets the cart and its metadata.
  void reset({bool shouldNotifyListeners = true}) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot reset cart after calling close'),
        StackTrace.current,
      );
    }

    try {
      groups.clear();
      _items.clear();
      _note = null;
      _deliveredAt = null;
      _expiresAt = null;
      addZeroQuantity = false;
      _metadata.clear();
      _isLocked = false;
      _logs.clear();
      removeItemCondition = null;

      emit(this);
      if (shouldNotifyListeners) notifyListeners();
    } catch (error, stackTrace) {
      _notifyOnErrorPlugins(error, stackTrace);
      rethrow;
    }
  }

  /// Clears a specific item group by ID.
  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    if (disposed) {
      _notifyOnErrorPlugins(
        StateError('Cannot clear items group after calling close'),
        StackTrace.current,
      );
    }
    _checkLock();

    groups.remove(groupId);
    _items.removeWhere((_, item) => item.group == groupId);
    _log(
      'Group has been removed from the cart: $groupId',
      notified: shouldNotifyListeners,
    );
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
      .._metadata.addAll(_metadata)
      .._deliveredAt = _deliveredAt;
  }

  /// Casts the cart to a different item type [G].
  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
      items: _items.cast<String, G>(),
      groups: groups.map((k, v) => MapEntry(k, v.cast<G>())),
    );
  }

  /// Applies an exchange rate to all items based on the target currency.
  void applyExchangeRate(
    CartCurrency cartCurrency, {
    bool shouldNotifyListeners = true,
  }) {
    _checkLock();

    removeExchangeRate();

    _cartCurrency = cartCurrency;
    final rate = cartCurrency.rate;

    _items.forEach((key, item) {
      item.price *= rate;

      // Update item in group if necessary
      final groupId = item.group;
      if (groups[groupId]?.items != null) {
        groups[groupId]!.items[key] = item;
      }
    });

    _log(
      'Applied exchange rate for ${cartCurrency.code}: $rate',
      notified: shouldNotifyListeners,
    );

    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Removes the applied exchange rate and reverts item prices.
  void removeExchangeRate({
    bool shouldNotifyListeners = true,
  }) {
    _checkLock();
    if (_cartCurrency == null) return;

    final rate = _cartCurrency!.rate;

    _items.forEach((key, item) {
      item.price /= rate;

      // Update item in group if necessary
      final groupId = item.group;
      if (groups[groupId]?.items != null) {
        groups[groupId]!.items[key] = item;
      }
    });

    _log(
      'Removed exchange rate for ${_cartCurrency!.code}: $rate',
      notified: shouldNotifyListeners,
    );

    _cartCurrency = null;

    emit(this);
    if (shouldNotifyListeners) notifyListeners();
  }

  /// Disposes of the cart and triggers [onDisposed].
  @override
  void dispose() {
    _notifyOnClosePlugins();
    _log('Cart has been disposed');
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
    _notifyOnChangedPlugins();
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
    _notifyOnChangedPlugins();
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
  /// Called whenever a [onChange] occurs in any [cart]
  /// A [onChange] occurs when a new value is emitted.
  /// [onChange] is called before a cart's state has been updated.
  @protected
  @mustCallSuper
  void onChange(FlexiCart<T> cart) {}

  /// Called whenever an [error] is thrown in the cart.
  /// The [stackTrace] argument may be [StackTrace.empty] if an error
  /// was received without a stack trace.
  @protected
  @mustCallSuper
  void onError(FlexiCart<T> cart, Object error, StackTrace stackTrace) {}

  /// Called whenever a [cart] is closed.
  /// [onClose] is called just before the [cart] is closed
  /// and indicates that the particular instance will no longer
  /// emit new states.
  @protected
  @mustCallSuper
  void onClose(FlexiCart<T> cart) {}
}

///
class CartCurrency {
  CartCurrency({required this.rate, required this.code});

  final num rate;
  final String code;
}
