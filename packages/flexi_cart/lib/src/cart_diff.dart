import 'package:flexi_cart/flexi_cart.dart';

/// Represents the difference between two states of a cart.
///
/// It tracks which items were:
/// - [added] — present in the new state but not in the old
/// - [removed] — present in the old state but not in the new
/// - [updated] — present in both, but changed (based on `==`)
class CartDiff<T> {
  /// Creates a new [CartDiff] instance with the specified lists.
  CartDiff({
    required this.added,
    required this.removed,
    required this.updated,
  });

  /// Items that were added in the new cart state.
  final List<T> added;

  /// Items that were removed from the old cart state.
  final List<T> removed;

  /// Items that exist in both states but have changed.
  final List<T> updated;

  /// Returns `true` if there are no differences between the two cart states.
  bool get isEmpty => added.isEmpty && removed.isEmpty && updated.isEmpty;
}

/// Calculates the difference between two item maps (old vs. new).
///
/// Compares the old state of a cart with a new state and returns a [CartDiff]
/// containing the items that were added, removed, or updated.
///
/// The [T] type must extend [ICartItem].
///
/// Example:
/// ```dart
/// final oldMap = {...cart.items}; // Take a snapshot
/// cart.add(newItem); // Mutate cart
/// final diff = calculateCartDiff(oldMap, cart.items);
/// print("Added: ${diff.added.length}");
/// print("Removed: ${diff.removed.length}");
/// print("Updated: ${diff.updated.length}");
/// ```
CartDiff<T> calculateCartDiff<T extends ICartItem>(
  Map<String, T> oldItems,
  Map<String, T> newItems,
) {
  final added = <T>[];
  final removed = <T>[];
  final updated = <T>[];

  final oldKeys = oldItems.keys.toSet();
  final newKeys = newItems.keys.toSet();

  final addedKeys = newKeys.difference(oldKeys);
  final removedKeys = oldKeys.difference(newKeys);
  final possibleUpdatedKeys = newKeys.intersection(oldKeys);

  for (final key in addedKeys) {
    added.add(newItems[key]!);
  }

  for (final key in removedKeys) {
    removed.add(oldItems[key]!);
  }

  for (final key in possibleUpdatedKeys) {
    final oldItem = oldItems[key]!;
    final newItem = newItems[key]!;
    if (oldItem != newItem) {
      updated.add(newItem);
    }
  }

  return CartDiff(added: added, removed: removed, updated: updated);
}
