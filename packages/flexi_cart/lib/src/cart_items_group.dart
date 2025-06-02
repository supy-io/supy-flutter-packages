import 'package:flexi_cart/src/models/cart_item.dart';

/// A group of cart items of type [T], each identified by a unique key.
///
/// This class provides utility methods to manage a group of items,
/// calculate totals, and support casting to different item types.
class CartItemsGroup<T extends ICartItem> {
  /// Creates a [CartItemsGroup] with the given [id], [name],
  /// and optional initial [items].
  ///
  /// If [items] is not provided, an empty map will be used.
  CartItemsGroup({
    required this.id,
    required this.name,
    Map<String, T>? items,
  }) : items = items ?? <String, T>{};

  /// A unique identifier for the group (e.g., vendor, category).
  final String id;

  /// The display name of the group.
  final String name;

  /// A map of cart items, where each item is keyed by a unique string.
  Map<String, T> items;

  /// Returns a list of all items in the group.
  List<T> get itemsList => items.values.toList();

  /// Adds an item to the group.
  ///
  /// If [replace] is true (default),
  /// it will overwrite an existing item with the same key.
  /// If [replace] is false, it will only add the item
  /// if the key does not already exist.
  void add(T item, {bool replace = true}) {
    if (replace) {
      items[item.key] = item;
    } else {
      items.putIfAbsent(item.key, () => item);
    }
  }

  /// Removes the given [item] from the group using its key.
  void remove(T item) {
    items.remove(item.key);
  }

  /// Clears all items from the group.
  void clear() {
    items.clear();
  }

  /// Casts this group to another item type [G] that also extends [ICartItem].
  ///
  /// Useful when converting between generic item types.
  CartItemsGroup<G> cast<G extends ICartItem>() {
    return CartItemsGroup<G>(
      id: id,
      name: name,
      items: items.cast<String, G>(),
    );
  }

  /// Calculates the total price of all items in the group.
  double totalPrice() =>
      itemsList.fold(0, (total, item) => total + item.totalPrice());

  /// Calculates the total quantity of all items in the group.
  double totalQty() =>
      itemsList.fold(0, (total, item) => total + item.notNullQty());
}
