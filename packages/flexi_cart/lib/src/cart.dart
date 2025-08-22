import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';

/// A reactive and extensible shopping cart that supports item grouping,
/// custom metadata, locking, expiration, and plugin extensions.
///
/// This class is designed for flexibility and use in state management
/// systems such as Provider, Riverpod, or GetX.
class FlexiCart<T extends ICartItem> extends ChangeNotifier
    with
        CartChangeNotifierDisposeMixin,
        CartStreamMixin<FlexiCart<T>>,
        CartPluginsMixin,
        CartHistoryMixin,
        CartLockMixin,
        CartMetadataMixin {
  /// Constructs a [FlexiCart] instance.
  ///
  /// - [items] is an optional initial map of items.
  /// - [groups] is an optional map of item groups.
  FlexiCart({
    Map<String, T>? items,
    Map<String, CartItemsGroup<T>>? groups,
    this.hooks,
    CartOptions? options,
  })  : _options = options ?? CartOptions(),
        _items = items ?? {},
        groups = groups ?? {} {
    final validatorOptions = _options.validatorOptions;

    if (validatorOptions.autoValidate) {
      // Automatically validate the cart if auto-validation is enabled
      _validateIfNeeded();
      addListener(_validateIfNeeded);
    }
  }

  /// Class have Callbacks
  final CartHooks? hooks;

  /// Options for the cart, including validation and discount options.
  CartOptions _options;

  /// Returns the current options for the cart.
  CartOptions get options => _options;

  /// Internal storage for cart items.
  final Map<String, T> _items;

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

  /// Currency if needed for the cart.
  CartCurrency? _cartCurrency;

  /// Internal logs of cart events.

  /// Returns all cart items as a map.
  Map<String, T> get items => _items;

  /// Returns all cart items as a list.
  List<T> get itemsList => _items.values.toList();

  /// Returns the note for the cart.
  String? get note => _note;

  /// Returns the delivery timestamp.
  DateTime? get deliveredAt => _deliveredAt;

  /// Returns true if the cart has expired.
  bool get isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Returns the CartCurrency.
  CartCurrency? get cartCurrency => _cartCurrency;

  // =============== VALIDATOR MANAGEMENT INTEGRATION ===============
  /// set promo code for the cart.
  void setPromoCode(
    String? code, {
    bool shouldNotifyListeners = true,
  }) =>
      _updateOptions(
        _options = _options.copyWith(
          validatorOptions: _options.validatorOptions.copyWith(
            promoCode: code,
          ),
        ),
        'Set promo code: $code',
        shouldNotifyListeners,
      );

  /// Returns the current promo code.
  String? get promoCode => _options.validatorOptions.promoCode;

  /// Sets a custom validator for the promo code.
  void setPromoCodeValidator(
    String? Function(String code)? promoCodeValidator, {
    bool shouldNotifyListeners = false,
  }) =>
      _updateOptions(
        _options = _options.copyWith(
          validatorOptions: _options.validatorOptions.copyWith(
            promoCodeValidator: promoCodeValidator,
          ),
        ),
        'Set promo code validator',
        shouldNotifyListeners,
      );

  /// [ValidatorOptions] is used to validate the cart state

  /// Returns true if the cart is locked.
  Map<String, dynamic> validate() {
    final validatorOptions = _options.validatorOptions;
    return validatorOptions.validate(this);
  }

  /// Returns true if the cart has any validators.
  bool get hasValidators => _options.validatorOptions.hasValidators;

  /// Returns the list of validators.
  List<ICartValidator> get validators {
    return _options.validatorOptions.validators;
  }

  /// add a validator to the validators.
  void addValidator(ICartValidator validator) {
    _options.validatorOptions.addValidator(validator);
    _validateIfNeeded();
  }

  /// Removes a validator from the list.
  void removeValidator(ICartValidator validator) {
    _options.validatorOptions.removeValidator(validator);
    _validateIfNeeded();
  }

  /// Adds multiple validators.
  void addValidators(List<ICartValidator> validators) {
    _options.validatorOptions.addValidators(validators);
    _validateIfNeeded();
  }

  /// Clears all validators.
  void clearValidators() {
    _options.validatorOptions.clearValidators();
    _validateIfNeeded();
  }

  /// Returns the current validation errors as a map.

  Map<String, dynamic> validationErrors = {};

  void _validateIfNeeded() {
    final errors = validate();
    validationErrors = errors;
    if (errors.isNotEmpty) {
      _log('Auto-validation errors: $errors');
    } else {
      _log('Auto-validation passed');
    }
  }

  /// sets custom validator options for the cart.
  void setValidatorOptions(
    ValidatorOptions validatorOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        validatorOptions: validatorOptions,
      ),
      'Set custom validator options',
      shouldNotifyListeners,
    );
  }

  // =============== END VALIDATOR MANAGEMENT INTEGRATION ===============

  /// Sets custom behavior options for the cart.
  void setBehaviorOptions(
    BehaviorOptions behaviorOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        behaviorOptions: behaviorOptions,
      ),
      'Set custom behavior options',
      shouldNotifyListeners,
    );
  }

  /// Sets the cart to expire after the given duration from now.
  void setExpiration(Duration duration, {bool shouldNotifyListeners = false}) {
    _performCartOperation(
      operation: () {
        _expiresAt = DateTime.now().add(duration);
      },
      logMessage: ' Set expiration to: ${DateTime.now().add(duration)}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Throws an exception if the cart is locked.
  void _checkLock() {
    if (isLocked) {
      final error = CartLockedException();
      _notifyOnErrorPlugins(error, StackTrace.current);
      throw error;
    }
  }

  /// Logs a message with a timestamp.
  void _log(String message, {bool notified = false}) {
    addHistory('$message - {notified: $notified}');
    final behaviorOptions = _options.behaviorOptions;
    if (behaviorOptions.enableLogging) {
      behaviorOptions.logger?.call(message);
    }
  }

  /// Notifies all registered plugins about a cart change.
  void _notifyOnChangedPlugins() {
    for (final plugin in plugins) {
      try {
        plugin.onChange(this);
      } on Exception catch (e, s) {
        debugPrint('Plugin onChange error: $e\n$s');
      }
    }
  }

  /// Notifies all registered plugins about a cart error.
  void _notifyOnErrorPlugins(Object error, StackTrace stackTrace) {
    for (final plugin in plugins) {
      plugin.onError(this, error, stackTrace);
    }
  }

  /// Throws an exception if the cart is disposed.
  void _checkDisposed() {
    checkIfDisposed(
      (exception) {
        _notifyOnErrorPlugins(exception, StackTrace.current);
      },
      throwIfDisposed: _options.behaviorOptions.throwWhenDisposed,
    );
  }

  /// Notifies all registered plugins about a cart close.
  void _notifyOnClosePlugins() {
    for (final plugin in plugins) {
      plugin.onClose(this);
    }
  }

  /// Sets a note for the cart.
  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _performCartOperation(
      operation: () {
        _note = note;
      },
      logMessage: 'Set Note with: $note',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Sets the delivery timestamp.
  void setDeliveredAt(
    DateTime? deliveredAt, {
    bool shouldNotifyListeners = false,
  }) {
    _performCartOperation(
      operation: () {
        _deliveredAt = deliveredAt;
      },
      logMessage: 'Set Delivered at: $deliveredAt',
      shouldNotifyListeners: shouldNotifyListeners,
    );
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
    _performCartOperation(
      operation: () {
        _add(item, increment);
      },
      logMessage: 'Item added: ${item.key}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
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
    _performCartOperation(
      operation: () {
        for (final item in items) {
          if (skipIfExist && _items.containsKey(item.key)) {
            continue;
          }
          _add(item, increment);
        }
      },
      logMessage: 'Items have been added: $items',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Removes all items not included in the provided list.
  void removeItemsNotInList(
    List<T> items, {
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        final keepKeys = items.map((e) => e.key).toSet();
        for (final item in itemsList) {
          if (!keepKeys.contains(item.key)) {
            _delete(item);
          }
        }
      },
      logMessage: 'Items have been removed: $items',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Deletes a single item from the cart.
  void delete(T item, {bool shouldNotifyListeners = true}) {
    _performCartOperation(
      operation: () {
        _delete(item);
      },
      logMessage: 'Item has been removed: ${item.key}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Clears all items from the cart without affecting metadata.
  void resetItems({bool shouldNotifyListeners = true}) {
    _performCartOperation(
      operation: () {
        groups.clear();
        _items.clear();
      },
      logMessage: 'Items have been reset: $itemsList',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Fully resets the cart and its metadata.
  void reset({bool shouldNotifyListeners = true}) {
    _checkDisposed();

    try {
      groups.clear();
      _items.clear();
      _note = null;
      _deliveredAt = null;
      _expiresAt = null;
      addZeroQuantity = false;
      clearAllMetadata();
      resetLock();
      clearHistory();
      _cartCurrency = null;

      emit(this);
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (error, stackTrace) {
      _notifyOnErrorPlugins(error, stackTrace);
      rethrow;
    }
  }

  /// Clears a specific item group by ID.
  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    _checkDisposed();
    _checkLock();

    _performCartOperation(
      operation: () {
        groups.remove(groupId);
        _items.removeWhere((_, item) => item.group == groupId);
      },
      logMessage: 'Group has been removed from the cart: $groupId',
      shouldNotifyListeners: shouldNotifyListeners,
    );
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
    _checkDisposed();

    return FlexiCart<T>(
      items: Map<String, T>.from(_items),
      groups: Map<String, CartItemsGroup<T>>.from(groups),
    )
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      ..addMetadataEntries(metadata)
      .._cartCurrency = _cartCurrency
      .._deliveredAt = _deliveredAt;
  }

  /// Casts the cart to a different item type [G].
  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
      items: _items.cast<String, G>(),
      groups: groups.map((k, v) => MapEntry(k, v.cast<G>())),
    )
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      ..addMetadataEntries(metadata)
      .._cartCurrency = _cartCurrency
      .._deliveredAt = _deliveredAt;
  }

  /// Applies an exchange rate to all items based on the target currency.
  void applyExchangeRate(
    CartCurrency cartCurrency, {
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        if (cartCurrency == _cartCurrency) {
          return;
        }
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
      },
      logMessage: 'Applied exchange rate for ${cartCurrency.code}:'
          ' ${cartCurrency.rate}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Removes the applied exchange rate and reverts item prices.
  void removeExchangeRate({
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        if (_cartCurrency == null) {
          return;
        }

        final rate = _cartCurrency!.rate;

        _items.forEach((key, item) {
          item.price /= rate;

          // Update item in group if necessary
          final groupId = item.group;
          if (groups[groupId]?.items != null) {
            groups[groupId]!.items[key] = item;
          }
        });

        _cartCurrency = null;
      },
      logMessage: 'Removed exchange rate',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Disposes of the cart and triggers [dispose].
  @override
  void dispose() {
    if (disposed) return;
    _notifyOnClosePlugins();
    _log('Cart has been disposed');
    hooks?.onDisposed?.call();
    disposeStream(); // call this if using the mixin's stream
    super.dispose();
  }

  /// Internal method to add an item and notify plugins.
  void _add(T item, bool increment) {
    final behaviorOptions = _options.behaviorOptions;

    /// Apply BehaviorOptions filters before proceeding
    if (!behaviorOptions.canAdd(item) && !items.containsKey(item.key)) {
      behaviorOptions.log('Add blocked by behavior options: ${item.key}');
      return;
    }

    if (!behaviorOptions.keepZeroOrNullQuantityItems) {
      final shouldDeleteZeroQty = !addZeroQuantity && item.quantity == 0;
      final shouldRemoveItem = !behaviorOptions.canAdd(item);

      if (shouldRemoveItem || item.quantity == null || shouldDeleteZeroQty) {
        _delete(item);
        return;
      }
    }
    hooks?.onItemAdded?.call(item);

    /// Override item price if resolver is provided on add only
    if (behaviorOptions.priceResolver != null &&
        !_items.containsKey(item.key)) {
      final resolvedPrice = behaviorOptions.resolvePrice(item);
      behaviorOptions.log('Resolved price for ${item.key}: $resolvedPrice');
      item.price = resolvedPrice;
    }
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
    hooks?.onItemDeleted?.call(item);
    _notifyOnChangedPlugins();
  }

  /// Removes an item from its group.
  void _deleteFromGroup(T item) {
    final group = groups[item.group];
    if (group != null) {
      group.remove(item);
      if (group.items.isEmpty) {
        groups.remove(item.group);
      }
    }
  }

  /// --- Private Helpers ---

  void _updateOptions(
    CartOptions newOptions,
    String logMessage,
    bool shouldNotifyListeners,
  ) {
    _performCartOperation(
      operation: () {
        _options = newOptions;
        _validateIfNeeded();
      },
      logMessage: logMessage,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Performs a cart operation with proper error handling and notifications.
  void _performCartOperation({
    required VoidCallback operation,
    required String logMessage,
    required bool shouldNotifyListeners,
  }) {
    _checkDisposed();
    _checkLock();

    operation();
    emit(this);
    _log(logMessage, notified: shouldNotifyListeners);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
