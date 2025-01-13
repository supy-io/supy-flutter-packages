abstract class ICartItem {
  static const String defaultGroup = 'All';

  ICartItem({
    required this.id,
    required this.name,
    required this.price,
    this.groupName = defaultGroup,
    this.group = defaultGroup,
    this.image,
    this.orderable = true,
    this.unit = '',
    this.currency = '',
    this.quantity = 0,
    this.selected = false,
    this.extras = const {},
  });

  final String name;
  final String unit;
  final String currency;
  final String groupName;
  final String group;
  final String? image;
  final String id;
  final bool selected;
  final bool orderable;

  final Map<String, dynamic> extras;
  double? quantity;
  double price;

  double notNullQty() => quantity ?? 0.000;

  double totalPrice() => price * notNullQty();

  String get key => id;

  void increment({double inc = 1}) {
    quantity = notNullQty() + inc;
  }

  void decrement() {
    if (quantity != null && quantity! > 0) {
      quantity = quantity! + -1;
    }
  }
}

extension CartItemIterableExtension on Iterable<ICartItem> {
  double totalPrice() => fold(0.0, (total, item) => total + item.totalPrice());

  double totalQty() => fold(0.0, (total, item) => total + item.notNullQty());
}
