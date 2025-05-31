import 'package:flutter/material.dart';

/// A custom [ThemeExtension] for the FlexiCart package.
///
/// This allows consistent styling for FlexiCart components through the
/// Flutter theme system.
class CartInputTheme extends ThemeExtension<CartInputTheme> {
  /// Creates a FlexiCart theme extension.
  const CartInputTheme({this.style});

  /// The style configuration for FlexiCart widgets.
  final CartInputStyle? style;

  /// Retrieves the [CartInputStyle] from the current [BuildContext].
  ///
  /// Falls back to a default style generated from the theme's [ColorScheme]
  /// if no custom style is found.
  static CartInputStyle of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<CartInputTheme>()?.style ??
        CartInputStyle.fromColorScheme(theme.colorScheme);
  }

  @override
  ThemeExtension<CartInputTheme> copyWith({CartInputStyle? style}) {
    return CartInputTheme(style: style ?? this.style?.copyWith());
  }

  @override
  ThemeExtension<CartInputTheme> lerp(
    ThemeExtension<CartInputTheme>? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return t > 0.5 ? other : this;
  }
}

/// Defines visual and structural styles for FlexiCart widgets.
class CartInputStyle {
  /// Constructs a [CartInputStyle] with optional customization.
  const CartInputStyle({
    this.activeForegroundColor = Colors.black,
    this.activeBackgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.shape = BoxShape.rectangle,
    this.radius = const Radius.circular(20),
    this.border,
    this.shadowColor,
    this.textStyle,
    this.iconTheme = const IconThemeData(),
    this.iconPlus,
    this.iconMinus,
    this.buttonAspectRatio = 1,
    this.elevation = 0,
  });

  /// Creates a style using values derived from a [ThemeData] instance.
  factory CartInputStyle.fromTheme(
    ThemeData theme, {
    BoxShape shape = BoxShape.rectangle,
    Radius radius = const Radius.circular(20),
    BoxBorder? border,
    IconData? iconPlus,
    IconData? iconMinus,
    double? buttonAspectRatio,
    double? elevation,
  }) {
    return CartInputStyle.fromColorScheme(
      theme.colorScheme,
      shape: shape,
      radius: radius,
      border: border,
      textStyle: theme.textTheme.bodyMedium,
      iconPlus: iconPlus,
      iconMinus: iconMinus,
      buttonAspectRatio: buttonAspectRatio,
      elevation: elevation,
    );
  }

  /// Creates a style using values derived from a [ColorScheme] instance.
  factory CartInputStyle.fromColorScheme(
    ColorScheme colorScheme, {
    BoxShape shape = BoxShape.rectangle,
    Radius radius = const Radius.circular(20),
    BoxBorder? border,
    TextStyle? textStyle,
    IconThemeData? iconTheme,
    IconData? iconPlus,
    IconData? iconMinus,
    double? buttonAspectRatio,
    double? elevation,
  }) {
    return CartInputStyle(
      activeForegroundColor: colorScheme.primary,
      activeBackgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onPrimary,
      shadowColor: colorScheme.shadow,
      shape: shape,
      radius: radius,
      border: border,
      textStyle: textStyle,
      iconTheme: iconTheme ?? const IconThemeData(),
      iconPlus: iconPlus,
      iconMinus: iconMinus,
      buttonAspectRatio: buttonAspectRatio ?? 1.5,
      elevation: elevation ?? 0,
    );
  }

  /// Foreground color when active (typically the icon/text color).
  final Color activeForegroundColor;

  /// Background color when active.
  final Color activeBackgroundColor;

  /// Foreground color when inactive.
  final Color foregroundColor;

  /// The shape of the button widget (rectangle or circle).
  final BoxShape shape;

  /// The border radius (only used if shape is rectangle).
  final Radius radius;

  /// Border to wrap the widget (optional).
  final BoxBorder? border;

  /// Optional shadow color for elevation.
  final Color? shadowColor;

  /// Text style for displaying numeric or text values.
  final TextStyle? textStyle;

  /// Icon styling configuration.
  final IconThemeData iconTheme;

  /// Icon used for the "add" button.
  final IconData? iconPlus;

  /// Icon used for the "subtract" button.
  final IconData? iconMinus;

  /// Aspect ratio of the buttons (width / height).
  final double buttonAspectRatio;

  /// Elevation of the widget (controls shadow depth).
  final double elevation;

  /// Returns a new [CartInputStyle] with specified fields replaced.
  ///
  /// Use [noBorder] to remove the existing border even if [border] is null.
  CartInputStyle copyWith({
    Color? activeForegroundColor,
    Color? activeBackgroundColor,
    Color? foregroundColor,
    Color? backgroundColor,
    BoxShape? shape,
    Radius? radius,
    BoxBorder? border,
    bool noBorder = false,
    Color? shadowColor,
    TextStyle? textStyle,
    IconThemeData? iconTheme,
    IconData? iconPlus,
    IconData? iconMinus,
    double? buttonAspectRatio,
    double? elevation,
  }) {
    return CartInputStyle(
      activeForegroundColor:
          activeForegroundColor ?? this.activeForegroundColor,
      activeBackgroundColor:
          activeBackgroundColor ?? this.activeBackgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      shape: shape ?? this.shape,
      radius: radius ?? this.radius,
      border: noBorder ? null : (border ?? this.border),
      shadowColor: shadowColor ?? this.shadowColor,
      textStyle: textStyle ?? this.textStyle,
      iconTheme: iconTheme ?? this.iconTheme,
      iconPlus: iconPlus ?? this.iconPlus,
      iconMinus: iconMinus ?? this.iconMinus,
      buttonAspectRatio: buttonAspectRatio ?? this.buttonAspectRatio,
      elevation: elevation ?? this.elevation,
    );
  }
}
