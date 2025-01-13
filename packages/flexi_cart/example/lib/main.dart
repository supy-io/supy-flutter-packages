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
        create: (BuildContext context) => FlexiCart(),
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
  @override
  Widget build(BuildContext context) {
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
      body: Builder(builder: (context) {
        final cart = context.watch<FlexiCart>();
        final items = cart.getItemsGroup('aaa');
        return Column(
          children: [
            Text("Total: ${cart.totalPrice()}"),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: Dismissible(
                      key: Key(item.key),
                      onDismissed: (direction) {
                        _delete(item);
                      },
                      background: Container(
                        color: Colors.red,
                        child: const Icon(Icons.delete),
                      ),
                      child: ListTile(
                        leading: Text(item.group),
                        title: Text(item.name),
                        subtitle: Text(item.price.toString()),
                        trailing: SizedBox(
                          width: 180,
                          child: CartInput(
                            item: item,
                            onChanged: (item) {
                              debugPrint("$item");
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  _generateItem() {
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
    cart.clearItemsGroup('ccc');
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
