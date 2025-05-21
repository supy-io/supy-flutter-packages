import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartInputStyle', () {
    test('Default constructor provides expected values', () {
      const style = CartInputStyle();

      expect(style.activeForegroundColor, Colors.black);
      expect(style.activeBackgroundColor, Colors.white);
      expect(style.foregroundColor, Colors.black);
      expect(style.shape, BoxShape.rectangle);
      expect(style.buttonAspectRatio, 1);
      expect(style.elevation, 0);
    });

    test('should create style with all default values', () {
      const style = CartInputStyle();
      expect(style.activeForegroundColor, equals(Colors.black));
      expect(style.activeBackgroundColor, equals(Colors.white));
      expect(style.foregroundColor, equals(Colors.black));
      expect(style.shape, equals(BoxShape.rectangle));
      expect(style.radius, const Radius.circular(20));
      expect(style.border, isNull);
      expect(style.shadowColor, isNull);
      expect(style.textStyle, isNull);
      expect(style.iconTheme, isA<IconThemeData>());
      expect(style.iconPlus, isNull);
      expect(style.iconMinus, isNull);
      expect(style.buttonAspectRatio, equals(1));
      expect(style.elevation, equals(0));
    });
    test('copyWith returns identical when no arguments are passed', () {
      const original = CartInputStyle();
      final copy = original.copyWith();

      expect(copy.activeForegroundColor, original.activeForegroundColor);
      expect(copy.activeBackgroundColor, original.activeBackgroundColor);
    });

    test('copyWith returns new instance with updated values', () {
      const original = CartInputStyle();
      final modified = original.copyWith(
        activeBackgroundColor: Colors.green,
        buttonAspectRatio: 1.5,
      );

      expect(modified.activeBackgroundColor, Colors.green);
      expect(modified.buttonAspectRatio, 1.5);
      expect(
        modified.activeForegroundColor,
        original.activeForegroundColor,
      ); // unchanged
    });

    test('copyWith noBorder = true removes border', () {
      const styleWithBorder = CartInputStyle(border: Border());
      final noBorderStyle = styleWithBorder.copyWith(noBorder: true);

      expect(noBorderStyle.border, isNull);
    });

    test('copyWith removes border when noBorder is true', () {
      final styleWithBorder = CartInputStyle(border: Border.all());
      final noBorderStyle = styleWithBorder.copyWith(noBorder: true);

      expect(noBorderStyle.border, null);
    });

    test('fromColorScheme creates style with color scheme mapping', () {
      const scheme = ColorScheme.dark();
      final style = CartInputStyle.fromColorScheme(scheme);

      expect(style.activeForegroundColor, scheme.primary);
      expect(style.activeBackgroundColor, scheme.surface);
      expect(style.foregroundColor, scheme.onPrimary);
    });

    test('fromTheme delegates to fromColorScheme and applies textStyle', () {
      final theme = ThemeData.light();
      final style = CartInputStyle.fromTheme(theme);

      expect(style.textStyle, theme.textTheme.bodyMedium);
      expect(style.activeBackgroundColor, theme.colorScheme.surface);
    });
  });

  group('CartInputTheme', () {
    test('lerp returns correct result', () {
      const theme1 = CartInputTheme(
        style: CartInputStyle(activeBackgroundColor: Colors.red),
      );
      const theme2 = CartInputTheme(
        style: CartInputStyle(activeBackgroundColor: Colors.green),
      );

      final lerpedLow = theme1.lerp(theme2, 0) as CartInputTheme;
      final lerpedHigh = theme1.lerp(theme2, 1) as CartInputTheme;

      expect(lerpedLow.style!.activeBackgroundColor, Colors.red);
      expect(lerpedHigh.style!.activeBackgroundColor, Colors.green);
    });
  });

  group('FlexiCartTheme.of()', () {
    testWidgets('returns default style when no extension is present',
        (tester) async {
      late CartInputStyle style;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = CartInputTheme.of(context);
              return Container();
            },
          ),
        ),
      );

      expect(style, isA<CartInputStyle>());
    });

    testWidgets('returns overridden style when extension is provided',
        (tester) async {
      const customStyle = CartInputStyle(activeBackgroundColor: Colors.orange);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData().copyWith(
            extensions: <ThemeExtension<dynamic>>[
              const CartInputTheme(style: customStyle),
            ],
          ),
          home: Builder(
            builder: (context) {
              final style = CartInputTheme.of(context);
              expect(style.activeBackgroundColor, Colors.orange);
              return Container();
            },
          ),
        ),
      );
    });
  });
}
