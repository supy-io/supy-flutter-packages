import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final cacheProvider = SharedPrefsProvider(prefs);
  runApp(
    MyApp(
      cacheProvider: cacheProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPrefsProvider cacheProvider;

  const MyApp({super.key, required this.cacheProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiCart Cache Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CartScreen(
        cacheProvider: cacheProvider,
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  final SharedPrefsProvider cacheProvider;

  const CartScreen({super.key, required this.cacheProvider});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FlexiCart<MyCartItem> cart = FlexiCart<MyCartItem>();
  static const cacheKey = 'my_cart_cache';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreCart();
    });
  }

  Future<void> _restoreCart() async {
    final restored = await cart.restoreFromCache(
      key: cacheKey,
      itemFromJson: MyCartItem.fromMap,
      provider: widget.cacheProvider,
      overrideThis: true, // override current cart instance
    );

    if (restored != null) {
      setState(() {});
      debugPrint('Cart restored: ${cart.items}');
    }
  }

  Future<void> _saveCart() async {
    await cart.saveToCache(
      key: cacheKey,
      itemToJson: (i) => i.toMap(),
      provider: widget.cacheProvider,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cart saved to cache!')));
  }

  void _addRandomItem() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = MyCartItem(
      key: 'item_$id',
      id: id,
      name: 'Item $id',
      price: (id.hashCode % 50).toDouble(),
    );
    setState(() {
      cart.add(item);
    });
  }

  void _clearCart() {
    setState(() {
      cart.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlexiCart + Cache')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: cart.items.values
                    .map(
                      (i) => ListTile(
                        title: Text(i.name),
                        subtitle:
                            Text('Price: \$${i.price}, Qty: ${i.quantity}'),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Note: ${cart.note ?? "-"}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FilledButton.tonal(
                          onPressed: _addRandomItem,
                          child: const Text('Add Item')),
                      FilledButton(
                        onPressed: _saveCart,
                        child: const Text('Save Cart'),
                      ),
                      FilledButton(
                        onPressed: _clearCart,
                        child: const Text('Clear Cart'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCartItem extends ICartItem {
  MyCartItem({
    required super.id,
    required super.name,
    required this.key,
    required super.price,
    super.group = 'default',
    super.groupName = 'Default',
    super.quantity = 1,
  });

  factory MyCartItem.fromMap(Map<String, dynamic> m) => MyCartItem(
        key: m['key'] as String,
        group: m['group'] as String? ?? 'default',
        groupName: m['groupName'] as String? ?? 'Default',
        price: (m['price'] as num).toDouble(),
        quantity:
            m['quantity'] != null ? (m['quantity'] as num).toDouble() : null,
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
      );

  @override
  final String key;

  Map<String, dynamic> toMap() => {
        'key': key,
        'group': group,
        'groupName': groupName,
        'price': price,
        'quantity': quantity,
        'id': id,
        'name': name,
        'metadata': metadata,
      };

  @override
  String toString() =>
      'MyCartItem(key:$key, group:$group, price:$price, qty:$quantity)';
}

class SharedPrefsProvider extends CartCacheProvider {
  SharedPrefsProvider(this.prefs);

  final SharedPreferences prefs;

  @override
  Future<void> delete(String key) async => prefs.remove(key);

  @override
  Future<String?> read(String key) async => prefs.getString(key);

  @override
  Future<void> write(String key, String value) async =>
      prefs.setString(key, value);
}
