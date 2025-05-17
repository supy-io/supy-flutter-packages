import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flexi_cart/flexi_cart.dart';

class ShoppingCartItem extends ICartItem {
  ShoppingCartItem({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1.0,
    super.group = 'test-group',
    required this.iconData,
  });

  final IconData iconData;
}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: ChangeNotifierProvider(
        create: (_) => FlexiCart<ShoppingCartItem>(),
        child: const ShopPage(),
      ),
    ),
  );
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Axis axis = Axis.horizontal;
  final items = [
    ShoppingCartItem(
      id: '1',
      name: 'Apple',
      price: 0.99,
      iconData: LucideIcons.apple,
    ),
    ShoppingCartItem(
      id: '2',
      name: 'Banana',
      price: 0.49,
      iconData: LucideIcons.banana,
    ),
    ShoppingCartItem(
      id: '3',
      name: 'Vegan',
      price: 0.5,
      iconData: LucideIcons.vegan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fresh Market'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.swipe_right_sharp),
            onPressed: () {
              setState(() {
                if (axis == Axis.vertical) {
                  axis = Axis.horizontal;
                } else {
                  axis = Axis.vertical;
                }
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        item.iconData,
                        size: 40,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IntrinsicWidth(
                      child: CartInput(
                        decimalDigits: 1,
                        size: 15,
                        axis: axis,
                        item: item,
                        style: CartInputStyle(
                          activeBackgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          iconTheme: Theme.of(context).iconTheme.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final cart = context.watch<FlexiCart<ShoppingCartItem>>();

          return BottomAppBar(
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${cart.totalPrice().toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: cart.isEmpty()
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            useSafeArea: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            builder: (_) => _buildCartSummary(cart),
                          );
                        },
                  child: const Text('View Cart'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartSummary(FlexiCart cart) {
    final items = cart.itemsList;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cart Summary',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Card(
              elevation: 0,
              child: ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'x${item.quantity} = \$${item.totalPrice().toStringAsFixed(2)}',
                ),
              ),
            ),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${cart.totalPrice().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
