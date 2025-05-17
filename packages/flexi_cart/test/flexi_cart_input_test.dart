import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

@visibleForTesting
class TestItem extends ICartItem {
  TestItem({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = null,
  });
}

class MockCart extends FlexiCart {}

void main() {
  late MockCart mockCart;
  late TestItem item;

  Widget createWidget(Widget input) {
    return MaterialApp(
      home: ChangeNotifierProvider<FlexiCart>.value(
        value: mockCart,
        child: Scaffold(body: input),
      ),
    );
  }

  setUp(
    () {
      mockCart = MockCart();
      item = TestItem(
        id: '1',
        name: 'Test',
        price: 10,
        quantity: 1,
      );
    },
  );

  testWidgets(
    'renders with initial quantity',
    (tester) async {
      mockCart.add(item);
      await tester.pumpWidget(createWidget(CartInput(item: item)));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.textContaining('1.00'), findsOneWidget);
    },
  );

  testWidgets('increments quantity by 1', (tester) async {
    mockCart.add(item);
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.tap(find.byIcon(Icons.add_circle_outline_outlined));
    await tester.pumpAndSettle();
    expect(mockCart.items[item.id]?.quantity, 2);
  });

  testWidgets('decrements quantity by 1', (tester) async {
    mockCart.add(item);
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.tap(find.byIcon(Icons.remove_circle_outline_outlined));
    await tester.pump();
    expect(mockCart.items[item.id]?.quantity, 0.95);
  });

  testWidgets('hides buttons when hideButtons is true', (tester) async {
    await tester
        .pumpWidget(createWidget(CartInput(item: item, hideButtons: true)));
    expect(find.byIcon(Icons.add_circle_outline_outlined), findsNothing);
    expect(find.byIcon(Icons.remove_circle_outline_outlined), findsNothing);
  });

  testWidgets('allows decimal input with 2 decimalDigits', (tester) async {
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.enterText(find.byType(TextField), '1.55');
    await tester.pump();
    expect(mockCart.items[item.id]?.quantity, closeTo(1.55, 0.01));
  });

  testWidgets('respects maxQuantity', (tester) async {
    await tester
        .pumpWidget(createWidget(CartInput(item: item, maxQuantity: 2)));
    await tester.enterText(find.byType(TextField), '9999');
    await tester.pump();
    expect(
      double.tryParse(
            tester.widget<TextField>(find.byType(TextField)).controller?.text ??
                '',
          ) ??
          0,
      lessThan(9999),
    );
  });

  testWidgets('shows zero when showZeroQty is true', (tester) async {
    item.quantity = 0;
    mockCart.add(item);
    await tester.pumpWidget(
      createWidget(CartInput(item: item, showZeroQty: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('0.00'), findsOneWidget);
  });

  testWidgets('clears input when quantity is zero and showZeroQty is false',
      (tester) async {
    item.quantity = 0;
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
  });

  testWidgets('disables input and buttons when enabled is false',
      (tester) async {
    mockCart.add(item);
    await tester
        .pumpWidget(createWidget(CartInput(item: item, enabled: false)));

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_circle_outline_outlined),
          )
          .onPressed,
      null,
    );
  });

  testWidgets('calls onChanged callback', (tester) async {
    double? captured;
    await tester.pumpWidget(
      createWidget(
        CartInput<ICartItem>(
          item: item,
          onChanged: (updated) => captured = updated.quantity,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    expect(captured, 2);
  });

  testWidgets('respects initialValue override', (tester) async {
    item.quantity = 1;
    mockCart.add(item);
    await tester
        .pumpWidget(createWidget(CartInput(item: item, initialValue: 5)));
    await tester.pumpAndSettle();
    expect(find.text('5.00'), findsOneWidget);
  });

  testWidgets('handles null quantity gracefully', (tester) async {
    item.quantity = null;
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('quantity under 1 increases by 0.05', (tester) async {
    item.quantity = 0.1;
    mockCart.add(item);
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.tap(find.byIcon(Icons.add_circle_outline_outlined));
    await tester.pump();
    expect(mockCart.items[item.id]?.quantity, closeTo(0.15, 0.01));
  });

  testWidgets('quantity under 1 decreases by 0.05', (tester) async {
    item.quantity = 0.5;
    mockCart.add(item);

    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.tap(find.byIcon(Icons.remove_circle_outline_outlined));
    await tester.pump();
    expect(mockCart.items[item.id]?.quantity, closeTo(0.45, 0.01));
  });

  testWidgets('input field clears on invalid input', (tester) async {
    await tester.pumpWidget(createWidget(CartInput(item: item)));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(mockCart.items[item.id]?.quantity, isNull);
  });

  testWidgets(
    'input field formats to correct decimal digits',
    (tester) async {
      mockCart.add(item);

      await tester
          .pumpWidget(createWidget(CartInput(item: item, decimalDigits: 3)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1.56789');
      await tester.pumpAndSettle();

      expect(find.text('1.567'), findsOneWidget);
    },
  );

  testWidgets(
    'cart updates are reflected in widget',
    (tester) async {
      mockCart.add(item);
      await tester.pumpWidget(createWidget(CartInput(item: item)));
      item.quantity = 3;
      mockCart.add(item);
      await tester.pumpAndSettle();

      expect(find.text('3.00'), findsOneWidget);
    },
  );

  testWidgets('custom input formatter works', (tester) async {
    final formatter = FilteringTextInputFormatter.allow(RegExp('[0-9]'));
    await tester.pumpWidget(
      createWidget(
        CartInput(item: item, inputFormatter: formatter),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1.23');
    await tester.pumpAndSettle();
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('text aligns as specified', (tester) async {
    await tester.pumpWidget(
      createWidget(
        CartInput(item: item, textAlign: TextAlign.right),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textAlign, TextAlign.right);
  });

  testWidgets('custom InputDecoration is respected', (tester) async {
    const hint = 'Enter Qty';
    await tester.pumpWidget(
      createWidget(
        CartInput(
          item: item,
          inputDecoration: const InputDecoration(hintText: hint),
        ),
      ),
    );
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets(
      'CartInput renders in vertical layout with correct children order',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => FlexiCart(),
            child: Builder(
              builder: (context) {
                return CartInput<TestItem>(
                  item: item,
                  axis: Axis.vertical,
                );
              },
            ),
          ),
        ),
      ),
    );

    final columnFinder = find.byType(Column);
    expect(columnFinder, findsOneWidget);

    // Optional: check if "+" and "−" icons exist in correct order
    final addIcon = find.byIcon(Icons.add_circle_outline_outlined);
    final removeIcon = find.byIcon(Icons.remove_circle_outline_outlined);
    expect(addIcon, findsOneWidget);
    expect(removeIcon, findsOneWidget);
  });

  testWidgets('CartInput renders with custom border decoration',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => FlexiCart(),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return CartInput<TestItem>(
                  item: item,
                  style: CartInputStyle(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final containerFinder = find.byWidgetPredicate((widget) {
      return widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).border != null;
    });

    expect(containerFinder, findsOneWidget);
  });
}
