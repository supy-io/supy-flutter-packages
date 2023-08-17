import 'cart_item.dart';

class CartItemsGroup<T extends ICartItem> {
  CartItemsGroup({
    required this.id,
    required this.name,
    Map<String, T>? items,
  }) : items = items ?? <String, T>{};

  final String id;
  final String name;
  Map<String, T> items;

  List<T> get itemsList => items.values.toList();

  void add(T item, {bool replace = true}) {
    if (replace) {
      items[item.key] = item;
    } else {
      items.putIfAbsent(item.key, () => item);
    }
  }

  void remove(T item) {
    items.remove(item.key);
  }

  CartItemsGroup<G> cast<G extends ICartItem>() {
    return CartItemsGroup<G>(
      id: id,
      name: name,
      items: items.cast<String, G>(),
    );
  }

  double totalPrice() =>
      itemsList.fold(0.0, (total, item) => total + item.totalPrice());

  double totalQty() =>
      itemsList.fold(0.0, (total, item) => total + item.notNullQty());
}
