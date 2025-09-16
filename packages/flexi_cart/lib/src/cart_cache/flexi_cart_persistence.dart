import 'dart:convert';

import 'package:flexi_cart/flexi_cart.dart';

/// Persistence extensions for FlexiCart to serialize/deserialize cart state
extension FlexiCartPersistence<T extends ICartItem> on FlexiCart<T> {
  /// Convert the entire cart to a Map suitable for jsonEncode
  Map<String, dynamic> toMap({
    required Map<String, dynamic> Function(T item) itemToJson,
  }) {
    return {
      'items': items.map((key, item) => MapEntry(key, itemToJson(item))),
      // groups serialized as id -> { id, name, items: {key: itemKey} }
      'groups': groups.map((id, group) {
        final groupItemsMap = group.items.map((k, v) => MapEntry(k, k));
        return MapEntry(id, {
          'id': group.id,
          'name': group.name,
          'items': groupItemsMap,
        });
      }),
      'note': note,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'addZeroQuantity': addZeroQuantity,
      'cartCurrency': cartCurrency != null
          ? {
              'code': cartCurrency!.code,
              'rate': cartCurrency!.rate,
            }
          : null,
      'options': options.toMap.call(),
      'metadata': metadata,
    };
  }

  /// Create a map representation and encode to JSON string
  String toJsonString(
      {required Map<String, dynamic> Function(T item) itemToJson}) {
    final map = toMap(itemToJson: itemToJson);
    return jsonEncode(map);
  }

  /// Saves the cart state to cache using the provided [provider].

  Future<void> saveToCache({
    required String key,
    required Map<String, dynamic> Function(T item) itemToJson,
    CartCacheProvider? provider,
  }) async {
    final json = toJsonString(itemToJson: itemToJson);
    if (provider != null) {
      await provider.write(key, json);
      return;
    }
  }

  /// Deletes the cart state from cache using the provided [provider].
  Future<void> deleteFromCache({
    required String key,
    CartCacheProvider? provider,
  }) async {
    if (provider != null) {
      await provider.delete(key);
      return;
    }
  }
}
