import 'dart:math';
import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:uuid/uuid.dart';

class CartItem extends ICartItem {
  CartItem({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1.0,
    super.group = 'test-group',
  });
}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.deepPurple,
      ),
      home: ChangeNotifierProvider(
        create: (BuildContext context) => FlexiCart()
          ..registerPlugin(CartPrintPlugin())
          ..add(CartItem(
            id: '1',
            name: 'Name',
            price: 1,
            quantity: 1.56789,
          )),
        child: const Example(),
      ),
    ),
  );
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  late final FlexiCart readCart;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<FlexiCart>();
    final items = cart.getItemsGroup('aaa');

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlexiCart Example'),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: deleteGroup,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Total: ${cart.totalPrice()}"),

            const SizedBox(height: 16),
            _buildLabeledInput(
              label: "1. Show Zero Quantity",
              description:
                  "Shows input even if quantity is zero using `showZeroQty: true`.",
              child: CartInput(
                item: CartItem(
                    id: 'zero-visible',
                    name: 'ZeroVisible',
                    price: 2.5,
                    quantity: 0),
                showZeroQty: true,
                onChanged: (item) => debugPrint("Zero shown: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "2. Disabled Input",
              description:
                  "Input is read-only and disabled using `enabled: false`.",
              child: CartInput(
                item: CartItem(
                    id: 'disabled',
                    name: 'DisabledItem',
                    price: 5.0,
                    quantity: 2.5),
                enabled: false,
                onChanged: (item) => debugPrint("Shouldn’t change: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "3. Hide Buttons",
              description:
                  "No increment/decrement buttons using `hideButtons: true`.",
              child: CartInput(
                item: CartItem(
                    id: 'no-buttons',
                    name: 'NoButtons',
                    price: 3.0,
                    quantity: 1.0),
                hideButtons: true,
                onChanged: (item) => debugPrint("No buttons: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "4. High Precision (3 decimals)",
              description:
                  "Displays quantity with 3 decimal digits using `decimalDigits: 3`.",
              child: CartInput(
                item: CartItem(
                    id: 'high-precision',
                    name: 'Precision',
                    price: 9.99,
                    quantity: 0.123456),
                decimalDigits: 3,
                onChanged: (item) => debugPrint("3-decimal: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "5. Initial Value Override",
              description: "Sets the starting value using `initialValue: 4.5`.",
              child: CartInput(
                item: CartItem(
                    id: 'initial-override', name: 'InitOverride', price: 10),
                initialValue: 4.5,
                onChanged: (item) => debugPrint("Initial override: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "6. Custom Input Decoration",
              description: "Customized TextField using `inputDecoration`.",
              child: CartInput(
                item: CartItem(
                    id: 'custom-decoration',
                    name: 'Styled',
                    price: 5,
                    quantity: 1),
                inputDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  labelText: 'Qty',
                ),
                onChanged: (item) => debugPrint("Styled input: $item"),
              ),
            ),

            _buildLabeledInput(
              label: "7. Grouped Item (group: aaa)",
              description:
                  "Belongs to group 'aaa' and will appear below in the dynamic list.",
              child: CartInput(
                item: CartItem(
                    id: 'grouped-item',
                    name: 'Grouped',
                    price: 6.0,
                    quantity: 1,
                    group: 'aaa'),
                onChanged: (item) => debugPrint("Grouped item: $item"),
              ),
            ),
            // _buildLabeledInput(
            //   label: "8. Custom Step Size",
            //   description: "Quantity changes in steps of 0.5 instead of 1.0 using `step: 0.5`.",
            //   child: CartInput(
            //     item: CartItem(id: 'step', name: 'Half-Step', price: 2.0, quantity: 1.0),
            //     step: 0.5,
            //     onChanged: (item) => debugPrint("Stepped: $item"),
            //   ),
            // ),
            // _buildLabeledInput(
            //   label: "9. Min/Max Limits",
            //   description: "Restricts quantity between 1 and 5 using `minValue` and `maxValue`.",
            //   child: CartInput(
            //     item: CartItem(id: 'limits', name: 'Limited', price: 1.0, quantity: 3),
            //     minValue: 1,
            //     maxValue: 5,
            //     onChanged: (item) => debugPrint("Limited: $item"),
            //   ),
            // ),
            _buildLabeledInput(
              label: "11. Input with Prefix & Suffix Icons",
              description:
                  "Adds icons inside input field using `inputDecoration`.",
              child: CartInput(
                item: CartItem(
                    id: 'icons', name: 'Icons', price: 6.5, quantity: 1),
                inputDecoration: const InputDecoration(
                  prefixIcon: Icon(Icons.shopping_cart),
                  suffixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                onChanged: (item) => debugPrint("With Icons: $item"),
              ),
            ),
            // _buildLabeledInput(
            //   label: "12. Large Input for Accessibility",
            //   description: "Larger font and padding for accessibility using `style`.",
            //   child: CartInput(
            //     item: CartItem(id: 'big', name: 'BigText', price: 3.0, quantity: 1),
            //     inputDecoration: const InputDecoration(
            //       border: OutlineInputBorder(),
            //     ),
            //     style: const TextStyle(fontSize: 24),
            //     onChanged: (item) => debugPrint("Big text: $item"),
            //   ),
            // ),
            //
            // _buildLabeledInput(
            //   label: "13. Mimic Custom Buttons",
            //   description: "Custom + and - buttons using your own layout outside `CartInput`.",
            //   child: Row(
            //     children: [
            //       IconButton(
            //         icon: const Icon(Icons.remove),
            //         onPressed: () {
            //           final cart = context.read<FlexiCart>();
            //           final item = cart.getById('custom')!;
            //           cart.update(item.copyWith(quantity: item.quantity - 1));
            //         },
            //       ),
            //       Expanded(
            //         child: CartInput(
            //           item: CartItem(id: 'custom', name: 'CustomBtn', price: 4.0, quantity: 1),
            //           hideButtons: true,
            //           onChanged: (item) => debugPrint("Manual update: $item"),
            //         ),
            //       ),
            //       IconButton(
            //         icon: const Icon(Icons.add),
            //         onPressed: () {
            //           final cart = context.read<FlexiCart>();
            //           final item = cart.getById('custom')!;
            //           cart.update(item.copyWith(quantity: item.quantity + 1));
            //         },
            //       ),
            //     ],
            //   ),
            // ),
            _buildLabeledInput(
              label: "14. Decimal Only, No Buttons",
              description:
                  "Starts with 2.75, allows only input via keyboard (no increment buttons).",
              child: CartInput(
                item: CartItem(
                    id: 'decimal-nobutton',
                    name: 'DecimalOnly',
                    price: 8.0,
                    quantity: 2.75),
                decimalDigits: 2,
                hideButtons: true,
                onChanged: (item) =>
                    debugPrint("Decimal keyboard input: $item"),
              ),
            ),

            // _buildLabeledInput(
            //   label: "15. With Helper Text",
            //   description: "Adds instructional text under the input field.",
            //   child: CartInput(
            //     item: CartItem(id: 'helper', name: 'HelperField', price: 4.5, quantity: 1),
            //     inputDecoration: const InputDecoration(
            //       labelText: 'Qty',
            //       helperText: 'Enter quantity between 1–10',
            //       border: OutlineInputBorder(),
            //     ),
            //     minValue: 1,
            //     maxValue: 10,
            //     onChanged: (item) => debugPrint("Helper field: $item"),
            //   ),
            // ),
            // _buildLabeledInput(
            //   label: "16. Right-Aligned, Bold Text",
            //   description: "Text aligned to the right with bold style for numeric focus.",
            //   child: CartInput(
            //     item: CartItem(id: 'right-align', name: 'RightAlign', price: 3.5, quantity: 5),
            //     textAlign: TextAlign.right,
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //       fontSize: 18,
            //       color: Colors.deepPurple,
            //     ),
            //     onChanged: (item) => debugPrint("Right aligned: $item"),
            //   ),
            // ),
            // _buildLabeledInput(
            //   label: "17. Live Update to Cart",
            //   description: "Each change is instantly pushed to the global cart state.",
            //   child: Builder(builder: (context) {
            //     final cart = context.read<FlexiCart>();
            //     final item = CartItem(id: 'live', name: 'LiveUpdate', price: 6.0, quantity: 1);
            //     cart.add(item); // ensure it's in the cart
            //
            //     return CartInput(
            //       item: item,
            //       onChanged: (updated) => cart.update(updated),
            //     );
            //   }),
            // ),

            // _buildLabeledInput(
            //   label: "18. Allow Negative Quantity",
            //   description: "Rare case where you want to support negative values (e.g., returns).",
            //   child: CartInput(
            //     item: CartItem(id: 'negative', name: 'Returns', price: 2.0, quantity: -1),
            //     minValue: -10,
            //     maxValue: 10,
            //     onChanged: (item) => debugPrint("Negative allowed: $item"),
            //   ),
            // ),

            // Localizations.override(
            //   context: context,
            //   locale: const Locale('ar'), // or 'de', 'it', etc.
            //   child: _buildLabeledInput(
            //     label: "19. Locale with , decimal",
            //     description: "Simulates French locale where decimal separator is a comma.",
            //     child: CartInput(
            //       item: CartItem(id: 'locale', name: 'CommaDecimal', price: 7.0, quantity: 1.5),
            //       decimalDigits: 2,
            //       onChanged: (item) => debugPrint("Locale input: $item"),
            //     ),
            //   ),
            // ),
            // _buildLabeledInput(
            //   label: "20. Numeric Keyboard",
            //   description: "Only shows numeric keyboard with decimal dot using `keyboardType`.",
            //   child: CartInput(
            //     item: CartItem(id: 'keyboard', name: 'NumOnly', price: 1.0, quantity: 2),
            //     keyboardType: const TextInputType.numberWithOptions(decimal: true),
            //     onChanged: (item) => debugPrint("Typed number: $item"),
            //   ),
            // ),
            const Divider(height: 32),
            const Text('Grouped Cart Items (group: aaa)',
                style: TextStyle(fontWeight: FontWeight.bold)),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: Dismissible(
                    key: Key(item.key),
                    onDismissed: (_) => _delete(item),
                    background: Container(
                      color: Colors.red,
                      child: const Icon(Icons.delete),
                    ),
                    child: ListTile(
                      leading: Text(item.group),
                      title: Text(item.name),
                      subtitle: Text('Price: ${item.price}'),
                      trailing: SizedBox(
                        width: 180,
                        child: CartInput(
                          item: item,
                          onChanged: (item) => debugPrint("Changed: $item"),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    readCart = context.read<FlexiCart>();
  }

  @override
  void dispose() {
    readCart.dispose();
    super.dispose();
  }

  Widget _buildLabeledInput({
    required String label,
    required String description,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  CartItem _generateItem() {
    var randomNames = RandomNames(Zone.us);
    final random = Random();
    final price = random.nextInt(10) * 10.0;
    return CartItem(
      id: const Uuid().v4(),
      name: randomNames.manName(),
      group: 'aaa',
      price: price,
    );
  }

  void deleteGroup() {
    final cart = context.read<FlexiCart>();
    cart.clearItemsGroup('aaa');
  }

  void _add() {
    final cart = context.read<FlexiCart>();
    cart.add(_generateItem());
  }

  void _delete(ICartItem item) {
    final cart = context.read<FlexiCart>();
    cart.delete(item);
  }
}

final class CartPrintPlugin extends ICartPlugin {
  @override
  void onChange(FlexiCart<ICartItem> cart) {
    debugPrint('Cart logs: ${cart.logs}');
    super.onChange(cart);
  }

  @override
  void onClose(FlexiCart<ICartItem> cart) {
    debugPrint('Cart closed: ${cart.logs}');
    super.onClose(cart);
  }

  @override
  void onError(FlexiCart<ICartItem> cart, Object error, StackTrace stackTrace) {
    super.onError(cart, error, stackTrace);
    debugPrint('Cart error: $error');
  }
}
