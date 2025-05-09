/// An abstract model representing a single item in a cart.
///
/// This base class can be extended or implemented to
/// create customized cart items.
/// It supports basic properties like ID, price, quantity,
/// metadata, and utility methods
/// for quantity and price calculation.
///
/// Example extension:
/// ```dart
/// class MyProduct extends ICartItem {
///   MyProduct({
///     required super.id,
///     required super.name,
///     required super.price,
///     super.image,
///     super.unit,
///     super.currency,
///   });
/// }
/// ```
abstract class ICartItem {
  /// CartItem Constructor
  ICartItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.groupName = defaultGroup,
    this.group = defaultGroup,
    this.image,
    this.orderable = true,
    this.unit = '',
    this.currency = '',
    this.quantity = 0,
    this.selected = false,
    this.extras = const {},
    this.metadata = const {},
  });

  /// Default group name used when none is specified.
  static const String defaultGroup = 'All';

  /// Unique identifier of the item (e.g., SKU).
  final String id;

  /// Human-readable name of the item.
  final String name;

  /// Optional description of the item.
  final String? description;

  /// Price per single unit (before tax/discount).
  double price;

  /// Quantity selected in the cart (nullable safe).
  double? quantity;

  /// Display unit (e.g., 'kg', 'pcs').
  final String unit;

  /// Currency code (e.g., 'USD').
  final String currency;

  /// Logical group the item belongs to (e.g., 'Beverages').
  final String group;

  /// Display name for the group (e.g., 'Drinks').
  final String groupName;

  /// URL or asset path to item image.
  final String? image;

  /// Whether this item can be ordered.
  final bool orderable;

  /// Whether this item is selected (used for bulk actions/UI).
  final bool selected;

  /// Additional attributes or custom properties.
  final Map<String, dynamic> extras;

  /// Metadata for extensibility (e.g., internal IDs, tags, flags).
  final Map<String, dynamic> metadata;

  /// Ensures quantity is treated as non-null (default is 0).
  double notNullQty() => quantity ?? 0.000;

  /// Total price after tax and discount.
  double totalPrice() {
    return price * notNullQty();
  }

  /// A unique key identifier used by cart systems (default: `id`).
  String get key => id;

  /// Increments the quantity by a given value.
  void increment({double inc = 1}) {
    quantity = notNullQty() + inc;
  }

  /// Decrements the quantity by 1 if greater than 0.
  void decrement() {
    if (quantity != null && quantity! > 0) {
      quantity = quantity! - 1;
    }
  }
}

/// Extension methods for list/iterable of cart items.
extension CartItemIterableExtension on Iterable<ICartItem> {
  /// Computes total price across all items (includes tax/discount).
  double totalPrice() => fold(0, (total, item) => total + item.totalPrice());

  /// Computes total quantity of all items.
  double totalQty() => fold(0, (total, item) => total + item.notNullQty());
}
