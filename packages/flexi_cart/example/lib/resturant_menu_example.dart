import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flexi_cart/flexi_cart.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MenuItem extends ICartItem {
  MenuItem({
    required super.id,
    required super.name,
    required super.price,
    required this.category,
    required this.icon,
    super.quantity = 0,
    super.description = '',
    this.tags = const [],
    this.available = true,
  });

  final String category;
  final IconData icon;
  final List<String> tags;
  final bool available;
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FlexiCart(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiny Eats',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<MenuItem> menuItems = [
    MenuItem(
      id: '1',
      name: 'Grilled Chicken',
      price: 12.99,
      icon: LucideIcons.drumstick,
      category: 'Mains',
      description: 'Grilled chicken with herbs and spices.',
      tags: ['spicy', 'protein'],
    ),
    MenuItem(
      id: '2',
      name: 'Margherita Pizza',
      price: 9.49,
      icon: LucideIcons.pizza,
      category: 'Mains',
      description: 'Classic margherita with basil and mozzarella.',
      tags: ['vegetarian'],
    ),
    MenuItem(
      id: '3',
      name: 'Cheesecake',
      price: 5.99,
      icon: LucideIcons.cake,
      category: 'Desserts',
      description: 'New York style creamy cheesecake.',
      tags: ['sweet'],
    ),
    MenuItem(
      id: '4',
      name: 'Green Salad',
      price: 4.99,
      icon: LucideIcons.salad,
      category: 'Starters',
      description: 'Fresh greens with vinaigrette.',
      tags: ['vegan', 'low-calorie'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<FlexiCart>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shiny Eats'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Reset Cart",
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: cart.isEmpty()
                ? null
                : () {
                    cart.reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cart cleared!')),
                    );
                  },
          ),
          IconButton(
            icon: Badge(
                isLabelVisible: cart.totalQuantity() > 0,
                label: Text(
                  '${cart.itemsList.length}',
                ),
                child: const Icon(LucideIcons.shoppingCart)),
            onPressed: () => _showCart(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(item.icon, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.titleMedium),
                          Text(item.description ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          Wrap(
                            spacing: 4,
                            children: item.tags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                          Text('\$${item.price.toStringAsFixed(2)}',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if ((cart.items[item.id]?.quantity ?? 0) > 0)
                      IconButton(
                          onPressed: () {
                            cart.delete(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Item removed from cart!')),
                            );
                          },
                          icon: Icon(Icons.delete)),
                    CartInput(
                      item: item,
                      size: 14,
                      decimalDigits: 0,
                      axis: Axis.vertical,
                      style: CartInputStyle(
                        activeBackgroundColor: theme.colorScheme.primary,
                        textStyle:
                            TextStyle(color: theme.colorScheme.onPrimary),
                        iconTheme:
                            IconThemeData(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCart(BuildContext context) {
    final cart = context.read<FlexiCart>();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your Order',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cart.itemsList.map(
              (item) => ListTile(
                title: Text(item.name),
                subtitle: Text(
                    '${item.quantity} × \$${item.price.toStringAsFixed(2)}'),
                trailing: Text('\$${item.totalPrice().toStringAsFixed(2)}'),
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Total: \$${cart.totalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Checkout'),
            )
          ],
        ),
      ),
    );
  }
}
