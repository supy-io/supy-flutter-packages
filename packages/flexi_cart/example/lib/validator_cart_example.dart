import 'package:flutter/material.dart';
import 'package:flexi_cart/flexi_cart.dart';
import 'package:provider/provider.dart';

// --- Validators ---
class MaxItemsValidator extends ICartValidator {
  final int maxItems;

  const MaxItemsValidator(this.maxItems);

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalQuantity() > maxItems) {
      return {
        'max_items_exceeded':
            'You can only add up to $maxItems items in the cart.'
      };
    }
    return null;
  }
}

class MinTotalPriceValidator extends ICartValidator {
  final double minPrice;

  const MinTotalPriceValidator(this.minPrice);

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalPrice() < minPrice) {
      return {
        'min_total_price':
            'Minimum order amount is \$${minPrice.toStringAsFixed(2)}.'
      };
    }
    return null;
  }
}

class MaxTotalPriceValidator extends ICartValidator {
  final double maxPrice;

  const MaxTotalPriceValidator(this.maxPrice);

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalPrice() > maxPrice) {
      return {
        'max_total_price':
            'Maximum order amount is \$${maxPrice.toStringAsFixed(2)}.'
      };
    }
    return null;
  }
}

class MinQuantityValidator extends ICartValidator {
  final int minQuantity;

  const MinQuantityValidator(this.minQuantity);

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    for (var item in cart.itemsList) {
      if (item.notNullQty() < minQuantity) {
        return {
          'min_quantity': 'Each item must have at least $minQuantity quantity.'
        };
      }
    }
    return null;
  }
}

// --- Product Item ---
class ProductItem extends ICartItem {
  ProductItem({
    required super.price,
    super.quantity = 1,
    super.group = 'default',
    required super.id,
    required super.name,
  });
}

// --- Main App ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fancy Flexi Cart',
      theme: ThemeData(
        colorSchemeSeed: Colors.tealAccent,
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) {
          final cart = FlexiCart<ProductItem>(
            options: CartOptions(
              validatorOptions: ValidatorOptions(
                autoValidate: true,
                validators: [
                  const MaxItemsValidator(5),
                  const MinTotalPriceValidator(5.0),
                  const MaxTotalPriceValidator(100.0),
                  const MinQuantityValidator(3),
                ],
                promoCodeValidator: (code) {
                  if (code.toLowerCase() == 'flutter50') return null;
                  if (code.toLowerCase() == 'save20') return null;
                  return 'Invalid promo code';
                },
              ),
            ),
          );
          return cart;
        },
        child: const CartPage(),
      ),
    );
  }
}

// --- Cart Page ---
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  late final FlexiCart<ProductItem> cart;
  final TextEditingController promoController = TextEditingController();

  final List<ICartValidator> availableValidators = [
    const MaxItemsValidator(5),
    const MinTotalPriceValidator(5.0),
    const MaxTotalPriceValidator(100.0),
    const MinQuantityValidator(3),
  ];

  final List<ProductItem> availableProducts = [
    ProductItem(id: 'apple', name: 'Apple', price: 2.5),
    ProductItem(id: 'banana', name: 'Banana', price: 1.2),
    ProductItem(id: 'orange', name: 'Orange', price: 1.8),
    ProductItem(id: 'mango', name: 'Mango', price: 3.0),
  ];

  @override
  void initState() {
    super.initState();
    cart = Provider.of<FlexiCart<ProductItem>>(context, listen: false);

    promoController.addListener(() {
      final code = promoController.text.trim();
      cart.setPromoCode(code.isEmpty ? null : code);
    });
  }

  @override
  void dispose() {
    promoController.dispose();
    cart.dispose();
    super.dispose();
  }

  void _addItem(ProductItem product) {
    cart.add(
        ProductItem(
          id: product.id,
          name: product.name,
          price: product.price,
        ),
        increment: true);
  }

  void _removeItem(ProductItem item) => cart.delete(item);

  void _changeQuantity(ProductItem item, int change) {
    final newQuantity = item.notNullQty() + change;
    if (newQuantity <= 0) {
      _removeItem(item);
    } else {
      cart.add(item..quantity = newQuantity);
    }
  }

  void _toggleValidator(ICartValidator validator) {
    setState(() {
      if (cart.validators.contains(validator)) {
        cart.removeValidator(validator);
      } else {
        cart.addValidator(validator);
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    context.watch<FlexiCart<ProductItem>>();
    final items = cart.itemsList;
    final errors = cart.validationErrors.values.toList();
    final hasPromo = cart.promoCode?.isNotEmpty ?? false;
    final promoError = cart.validationErrors['promoCode'] as String?;
    final promoValid = hasPromo && promoError == null;

    final discountPercent = (cart.promoCode?.toLowerCase() == 'flutter50')
        ? 0.5
        : (cart.promoCode?.toLowerCase() == 'save20')
            ? 0.2
            : 0.0;

    final totalPrice = cart.totalPrice();
    final discountedPrice = totalPrice * (1 - discountPercent);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Fancy Flexi Cart'),
                    floating: true,
                    pinned: true,
                    snap: true,
                    centerTitle: true,
                    elevation: 4,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (errors.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: errors
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Text(
                                          "- ${e.toString()}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        Text("Promo Code",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800)),
                        SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: promoController,
                                decoration: InputDecoration(
                                  filled: true,
                                  isDense: true,
                                  hintText: 'Promo Code',
                                  fillColor: Colors.teal.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  errorText: promoError,
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (promoValid)
                                        const Icon(Icons.check_circle,
                                            color: Colors.green),
                                    ],
                                  ),
                                ),
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                  if (!promoValid) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text('Promo code error: $promoError'),
                                      backgroundColor: Colors.red.shade400,
                                    ));
                                  } else if (promoValid) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Promo code applied!'),
                                      backgroundColor: Colors.green,
                                    ));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: promoValid
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      if (promoError != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Promo code error: $promoError'),
                                          backgroundColor: Colors.red.shade400,
                                        ));
                                      } else if (promoValid) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Promo code applied!'),
                                          backgroundColor: Colors.green,
                                        ));
                                      }
                                    }
                                  : null,
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: Colors.teal.shade300,
                          thickness: .5,
                        ),
                        Text("Available Validators",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800)),
                        SizedBox(
                          height: 8,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: availableValidators.map((validator) {
                            final isActive =
                                cart.validators.contains(validator);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.teal.shade100
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FilterChip(
                                selected: isActive,
                                label: Text(
                                  validator is MaxItemsValidator
                                      ? 'Max Items (${validator.maxItems})'
                                      : validator is MinTotalPriceValidator
                                          ? 'Min Price \$${validator.minPrice}'
                                          : validator is MaxTotalPriceValidator
                                              ? 'Max Price \$${validator.maxPrice}'
                                              : validator
                                                      is MinQuantityValidator
                                                  ? 'Min Qty ${validator.minQuantity}'
                                                  : 'Validator',
                                  style: TextStyle(
                                      color: isActive
                                          ? Colors.teal.shade900
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600),
                                ),
                                onSelected: (_) => _toggleValidator(validator),
                                selectedColor: Colors.transparent,
                                showCheckmark: false,
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: Colors.teal.shade300,
                          thickness: .5,
                        ),
                        Text("Available Products",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: availableProducts.map((product) {
                            return FilledButton.tonal(
                              onPressed: () => _addItem(product),
                              child: Text('Add ${product.name}'),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        if (items.isEmpty)
                          const Center(
                            child: Text(
                              'Your cart is empty',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  if (items.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Price: \$${item.price.toStringAsFixed(2)} × ${item.quantity} = \$${(item.price * item.notNullQty()).toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _changeQuantity(item, -1),
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    onPressed: () => _changeQuantity(item, 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                              onLongPress: () => _removeItem(item),
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
            Material(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('\$${totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (discountPercent > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount (${(discountPercent * 100).toInt()}%):',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            '-\$${(totalPrice * discountPercent).toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
