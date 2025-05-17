import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:flexi_cart/flexi_cart.dart';

class Product extends ICartItem {
  Product({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1,
  });

  double getQuantity() => quantity ?? 0;

  setQuantity(double value) => quantity = value;

  String getUniqueId() => id;

  Product copyWithQuantity(double qty) {
    return Product(id: id, name: name, price: price, quantity: qty);
  }
}

class SupplierItem extends ICartItem {
  final String code;
  final String title;
  final double cost;

  SupplierItem({
    required this.code,
    required this.title,
    required this.cost,
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 0,
  });

  double getQuantity() => quantity ?? 0;

  setQuantity(double value) => quantity = value;

  String getUniqueId() => code;

  SupplierItem copyWithQuantity(double qty) {
    return SupplierItem(
      code: code,
      title: title,
      cost: cost,
      quantity: qty,
      price: price,
      id: id,
      name: name,
    );
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FlexiCart<Product>()),
        ChangeNotifierProvider(create: (_) => FlexiCart<SupplierItem>()),
      ],
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
      title: 'FlexiCart Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const MultiCartPage(),
    );
  }
}

class MultiCartPage extends StatelessWidget {
  const MultiCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productCart = context.watch<FlexiCart<Product>>();
    final supplierCart = context.watch<FlexiCart<SupplierItem>>();

    final productTotal = productCart.items.values.fold<double>(
        0, (sum, item) => sum + item.price * (item.quantity ?? 0));
    final supplierTotal = supplierCart.items.values.fold<double>(
        0, (sum, item) => sum + item.price * (item.quantity ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛍️ FlexiCart Multi-Cart Demo"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CartSection<Product>(
              title: "🛒 Product Cart",
              cartItems: productCart.items,
              totalPrice: productTotal,
              onAdd: () {
                final product = Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: "Apple",
                  price: 1.99,
                );
                productCart.add(product);
              },
              onUpdate: productCart.add,
              onDelete: (item) => _confirmDelete(context, () {
                productCart.delete(item);
              }),
              itemBuilder: (item, onUpdate, onDelete) => CartItemTile<Product>(
                item: item,
                onUpdate: onUpdate,
                onDelete: onDelete,
                titleBuilder: (i) => Text("${i.name} x ${i.getQuantity()}",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitleBuilder: (i) =>
                    Text("Price: \$${i.price.toStringAsFixed(2)}"),
              ),
            ),
            const SizedBox(height: 15),
            CartSection<SupplierItem>(
              title: "🧺 Supplier Cart",
              cartItems: supplierCart.items,
              totalPrice: supplierTotal,
              onAdd: () {
                final item = SupplierItem(
                  code: "s${DateTime.now().millisecondsSinceEpoch}",
                  title: "Bulk Rice",
                  cost: 12.0,
                  quantity: 1,
                  name: "Bulk Rice",
                  id: "s${DateTime.now().millisecondsSinceEpoch}",
                  price: 12.0,
                );
                supplierCart.add(item);
              },
              onUpdate: supplierCart.add,
              onDelete: (item) => _confirmDelete(context, () {
                supplierCart.delete(item);
              }),
              itemBuilder: (item, onUpdate, onDelete) =>
                  CartItemTile<SupplierItem>(
                item: item,
                onUpdate: onUpdate,
                onDelete: onDelete,
                titleBuilder: (i) => Text("${i.title} x ${i.getQuantity()}",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitleBuilder: (i) =>
                    Text("Cost: \$${i.cost.toStringAsFixed(2)}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirmed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirmed();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class CartSection<T extends ICartItem> extends StatefulWidget {
  final String title;
  final Map<String, T> cartItems;
  final double totalPrice;
  final VoidCallback onAdd;
  final Function(T) onDelete;
  final Function(T) onUpdate;
  final Widget Function(T item, Function(T) onUpdate, Function(T) onDelete)
      itemBuilder;

  const CartSection({
    required this.title,
    required this.cartItems,
    required this.totalPrice,
    required this.onAdd,
    required this.onDelete,
    required this.onUpdate,
    required this.itemBuilder,
    super.key,
  });

  @override
  State<CartSection<T>> createState() => _CartSectionState<T>();
}

class _CartSectionState<T extends ICartItem> extends State<CartSection<T>> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (val) => setState(() => _expanded = val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          size: 28,
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          FilledButton.tonalIcon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Add Item"),
          ),
          const SizedBox(height: 14),
          if (widget.cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                "No items added yet.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...widget.cartItems.entries.map((entry) => widget.itemBuilder(
                entry.value,
                widget.onUpdate,
                widget.onDelete,
              )),
          const Divider(height: 24, thickness: 1.2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total: \$${widget.totalPrice.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class CartItemTile<T extends ICartItem> extends StatelessWidget {
  final T item;
  final void Function(T) onUpdate;
  final void Function(T) onDelete;
  final Widget Function(T) titleBuilder;
  final Widget Function(T) subtitleBuilder;

  const CartItemTile({
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    required this.titleBuilder,
    required this.subtitleBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      title: titleBuilder(item),
      subtitle: subtitleBuilder(item),
      trailing: SizedBox(
        width: 190,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CartInput<T>(
                item: item,
                onChanged: onUpdate,
              ),
            ),
            IconButton(
              icon: Icon(Iconsax.trash, color: Colors.red.shade700),
              tooltip: "Remove Item",
              onPressed: () => onDelete(item),
            ),
          ],
        ),
      ),
    );
  }
}
