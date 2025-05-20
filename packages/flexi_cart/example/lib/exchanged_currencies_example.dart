import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.light,

      ),
      home: ChangeNotifierProvider(
        create: (_) => FlexiCart(),
        child: Builder(
          builder: (context) {
            return const FlexiCartProPage();
          }
        ),
      ),
    ),
  );
}

final currencies = [
  CartCurrency(code: 'USD', rate: 1.0),
  CartCurrency(code: 'EUR', rate: 0.93),
  CartCurrency(code: 'GBP', rate: 0.81),
  CartCurrency(code: 'JPY', rate: 150.23),
  CartCurrency(code: 'AUD', rate: 1.48),
  CartCurrency(code: 'CAD', rate: 1.36),
];

final currencyNames = {
  'USD': 'United States Dollar',
  'EUR': 'Euro',
  'GBP': 'British Pound',
  'JPY': 'Japanese Yen',
  'AUD': 'Australian Dollar',
  'CAD': 'Canadian Dollar',
};

final currencyFlags = {
  'USD': '🇺🇸',
  'EUR': '🇪🇺',
  'GBP': '🇬🇧',
  'JPY': '🇯🇵',
  'AUD': '🇦🇺',
  'CAD': '🇨🇦',
};

class CartItem extends ICartItem {
  CartItem({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1,
    super.group = 'default',
  });
}

class FlexiCartProPage extends StatefulWidget {
  const FlexiCartProPage({super.key});

  @override
  State<FlexiCartProPage> createState() => _FlexiCartProPageState();
}

class _FlexiCartProPageState extends State<FlexiCartProPage>
    with SingleTickerProviderStateMixin {
  late final FlexiCart cart;
  CartCurrency selectedCurrency = currencies.first;
  late AnimationController _currencyAnimController;

  @override
  void initState() {
    super.initState();
    cart = context.read<FlexiCart>();
    cart.add(CartItem(id: '1', name: '💻 Laptop', price: 1299.99));
    cart.add(CartItem(id: '2', name: '📱 Smartphone', price: 749.49));
    cart.add(CartItem(id: '3', name: '🎧 Headphones', price: 199.99));

    _currencyAnimController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _currencyAnimController.dispose();
    super.dispose();
  }

  void _changeCurrency(CartCurrency? newCurrency) {
    if (newCurrency == null) return;
    cart.applyExchangeRate(newCurrency);
    setState(() => selectedCurrency = newCurrency);
  }

  void _changeQuantity(String id, int delta) {
    final item = cart.itemsList.firstWhere((element) => element.id == id);
    final newQty = (item.quantity ?? 1) + delta;
    if (newQty < 1) return;
    cart.add(item..quantity=newQty);
  }

  @override
  Widget build(BuildContext context) {
    final flag = currencyFlags[selectedCurrency.code] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_checkout_rounded),
            const SizedBox(width: 8),
            const Text('FlexiCart Pro'),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.2).animate(_currencyAnimController),
              child: Text(flag, style: const TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CurrencyDropdown(
              selected: selectedCurrency,
              onChanged: _changeCurrency,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: CartItemList(
                currency: selectedCurrency,
                onQuantityChange: _changeQuantity,
              ),
            ),
            const SizedBox(height: 16),
            CartSummary(currency: selectedCurrency),
          ],
        ),
      ),
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final CartCurrency selected;
  final ValueChanged<CartCurrency?> onChanged;

  const CurrencyDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CartCurrency>(

      value: selected,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Currency',
        prefixIcon: const Icon(Icons.currency_exchange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: currencies
          .map((c) => DropdownMenuItem(
        value: c,
        child: Row(
          children: [
            Text(currencyFlags[c.code] ?? ''),
            const SizedBox(width: 8),
            Text('${c.code} — ${currencyNames[c.code] ?? ''}'),
            const Spacer(),
            Text(c.rate.toStringAsFixed(2)),
          ],
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class CartItemList extends StatelessWidget {
  final CartCurrency currency;
  final void Function(String id, int delta) onQuantityChange;

  const CartItemList({
    super.key,
    required this.currency,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<FlexiCart>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: ListView.separated(
        key: ValueKey(cart.itemsList.length),
        itemCount: cart.itemsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = cart.itemsList[i];
          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [

                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Unit Price: ${formatCurrency(item.price, currency.code)}'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onQuantityChange(item.id, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity?.toInt() ?? 1}', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        onPressed: () => onQuantityChange(item.id, 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency(
                        (item.price * (item.quantity ?? 1)), currency.code),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartSummary extends StatelessWidget {
  final CartCurrency currency;

  const CartSummary({super.key, required this.currency});

  static const double taxRate = 0.08;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<FlexiCart>();
    final subtotal = cart.itemsList.fold<double>(
      0,
          (sum, item) => sum + (item.price * (item.quantity ?? 1)),
    );
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            _buildRow('Subtotal', formatCurrency(subtotal, currency.code)),
            const SizedBox(height: 6),
            _buildRow('Tax (8%)', formatCurrency(tax, currency.code)),
            const Divider(height: 24, thickness: 1),
            _buildRow('Total', formatCurrency(total, currency.code),
                isBold: true, fontSize: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
      ],
    );
  }
}

String formatCurrency(double amount, String code) {
  return NumberFormat.currency(name: code, symbol: getCurrencySymbol(code)).format(amount);
}

String getCurrencySymbol(String code) {
  // You can extend this for more currencies or use intl package defaults
  switch (code) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'JPY':
      return '¥';
    case 'AUD':
      return 'A\$';
    case 'CAD':
      return 'C\$';
    default:
      return code;
  }
}
