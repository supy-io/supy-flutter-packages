import 'package:flutter/material.dart';
import 'package:flexi_cart/flexi_cart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

void main() => runApp(const ShineShopApp());

class ShineShopApp extends StatelessWidget {
  const ShineShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.pinkAccent,
      ),
      debugShowCheckedModeBanner: false,
      home: ChangeNotifierProvider(
        create: (_) => FlexiCart<Product>(),
        child: const ShineHomePage(),
      ),
    );
  }
}

class Product extends ICartItem {
  Product({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1,
    this.icon,
    super.group = 'shine-products',
  });

  final IconData? icon;
}

class ShineHomePage extends StatelessWidget {
  const ShineHomePage({super.key});

  List<Product> get items => [
        Product(
            id: '1',
            name: 'Glow Serum',
            price: 29.99,
            icon: LucideIcons.sunMedium),
        Product(
            id: '2',
            name: 'Hydra Mask',
            price: 19.99,
            icon: LucideIcons.droplet),
        Product(
            id: '3',
            name: 'Soft Cleanser',
            price: 14.99,
            icon: LucideIcons.cloudDrizzle),
        Product(
            id: '4',
            name: 'Radiance Toner',
            price: 21.99,
            icon: LucideIcons.sparkles),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shine Beauty'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => _showCart(context),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _ProductCard(item: items[i]),
      ),
      floatingActionButton: const _FloatingCartButton(),
    );
  }

  void _showCart(BuildContext context) {
    final cart = context.read<FlexiCart<Product>>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your Cart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final item in cart.itemsList)
              ListTile(
                leading: Icon(item.icon, size: 28),
                title: Text(item.name),
                subtitle: Text(
                    'x${item.quantity} = \$${item.totalPrice().toStringAsFixed(2)}'),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: \$${cart.totalPrice().toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final Product item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, size: 48, color: theme.colorScheme.primary),
            Text(item.name, style: theme.textTheme.titleMedium),
            Text('\$${item.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            CartInput(
              decimalDigits: 1,
              item: item,
              size: 16,
              style: CartInputStyle(
                textStyle: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                activeBackgroundColor: theme.colorScheme.primary,
                iconTheme: theme.iconTheme
                    .copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCartButton extends StatelessWidget {
  const _FloatingCartButton();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<FlexiCart<Product>>();
    final count = cart.itemsList.length;

    return FloatingActionButton.extended(
      icon: const Icon(Icons.shopping_cart_outlined),
      label: Text('Cart ($count)'),
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open the cart from top right!')),
      ),
    );
  }
}
