import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A highly customizable and reusable quantity input widget for cart items.
///
/// The `CartInput<T>` widget allows users to input and adjust
/// the quantity of an item
/// in a shopping cart, where the item implements [ICartItem].
/// It integrates with the
/// `FlexiCart` package to provide seamless cart updates,
/// state syncing, and user interaction.
///
/// ### Features
/// - Supports both integer and fractional quantities
/// - Customizable input field and button layout (vertical or horizontal)
/// - Optional increment/decrement buttons
/// - Integration with [FlexiCart] for cart updates
/// - Configurable max quantity, input formatting, decimal digit limits
/// - Callback for external state updates using [onChanged]
/// - Displays 0 as a placeholder based on [showZeroQty]
/// - Supports theming through [CartInputStyle] and [CartInputTheme]
///
/// ### Parameters:
/// - `item` *(required)*: The cart item of type `T`
/// - `initialValue`: Overrides the quantity from the cart
/// - `onChanged`: Callback triggered when the quantity is modified
/// - `hideButtons`: Whether to hide the increment/decrement buttons
/// - `showZeroQty`: Whether to show "0" instead of an empty field for null/zero quantity
/// - `decimalDigits`: Number of allowed digits after decimal
/// - `maxQuantity`: Maximum allowable quantity
/// - `inputDecoration`: Custom decoration for the input field
/// - `textAlign`: Text alignment within the field
/// - `enabled`: Enables or disables interaction with the input and buttons
/// - `inputFormatter`: Custom input formatter, defaults
/// to [CartQuantityInputFormatter]
/// - `axis`: Layout direction (horizontal or vertical)
/// - `style`: Themed style customization
/// - `size`: Size of buttons and vertical layout container
/// - `stepper`: Increment/decrement step value
/// - `keyboardType`: Optional keyboard input type
/// - `elevation`: Elevation of the container
///
/// ### Example:
/// ```dart
/// CartInput<MyCartItem>(
///   item: item,
///   decimalDigits: 2,
///   maxQuantity: 100,
///   onChanged: (updatedItem) {
///     print("Updated quantity: ${updatedItem.quantity}");
///   },
/// )
/// ```
///
/// ### Notes:
/// - Automatically adds the item to the cart if [initialValue]
/// is provided and the item
///   doesn't exist yet.
/// - Rebuilds internally when cart values change externally.
///
/// ### Internal Structure:
/// - Uses a [TextEditingController] to manage manual text input
/// - Uses [ValueNotifier] for reactive quantity changes
/// - Listens for post-frame callbacks and dependency changes to sync state
/// - Uses [AnimatedPhysicalModel] for styled layout with optional borders
/// and elevation
///
/// ### Extensions:
/// - `double.betweenZeroAndOne`: Utility to check if a double
/// is between 0 and 1
/// - `BuildContext.safeRead` / `safeWatch`: Safely access Provider without risk of errors

/// A generic quantity input widget for cart items implementing [ICartItem].
///
/// This widget allows users to modify item quantity using text input
/// and optional stepper buttons.
/// It integrates with [FlexiCart] for cart updates and
/// supports extensive customization options.
class CartInput<T extends ICartItem> extends StatefulWidget {
  /// CartInput Constructor
  const CartInput({
    required this.item,
    super.key,
    this.onChanged,
    this.hideButtons = false,
    this.showZeroQty = false,
    this.decimalDigits = 2,
    this.maxQuantity = 999999,
    this.inputDecoration,
    this.textAlign = TextAlign.center,
    this.enabled = true,
    this.inputFormatter,
    this.initialValue,
    this.axis = Axis.horizontal,
    this.style,
    this.size = 35.0,
    this.stepper = 1,
    this.elevation,
    this.keyboardType,
  });

  /// The cart item to be edited.
  final T item;

  /// Overrides the quantity in cart temporarily with a preset value.
  final double? initialValue;

  /// Callback when the quantity changes.
  final ValueChanged<T>? onChanged;

  /// If true, hides the increment and decrement buttons.
  final bool hideButtons;

  /// If true, shows "0" instead of clearing the field when quantity is zero.
  final bool showZeroQty;

  /// Maximum allowed decimal places.
  final int decimalDigits;

  /// Maximum allowable quantity.
  final int maxQuantity;

  /// Decoration for the input field.
  final InputDecoration? inputDecoration;

  /// How text is aligned inside the input.
  final TextAlign textAlign;

  /// Enables/disables input field and buttons.
  final bool enabled;

  /// Custom input formatter. Defaults to [CartQuantityInputFormatter] if null.
  final TextInputFormatter? inputFormatter;

  /// Layout orientation (horizontal or vertical).
  final Axis axis;

  /// Optional style customization.
  final CartInputStyle? style;

  /// Width/height of buttons depending on axis.
  final double size;

  /// Quantity change step value.
  final int stepper;

  /// Optional custom keyboard type.
  final TextInputType? keyboardType;

  /// Container elevation shadow.
  final double? elevation;

  @override
  State<CartInput<T>> createState() => _CartInputState<T>();
}

class _CartInputState<T extends ICartItem> extends State<CartInput<T>> {
  late final FlexiCart _cart;
  late final TextEditingController _controller;
  late final ValueNotifier<double?> _quantityNotifier;

  /// Returns true if layout is vertical.
  bool get isVertical => widget.axis == Axis.vertical;

  @override
  void initState() {
    super.initState();
    _cart = readCart();
    _controller = TextEditingController();
    _quantityNotifier = ValueNotifier<double?>(widget.initialValue);

    // Initialize after first frame render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuantity();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Resync quantity if it changed from outside.
    final inCartQuantity = watchCart().items[widget.item.key]?.quantity;
    if (inCartQuantity != _quantity) {
      _initializeQuantity();
    }
  }

  /// Reads the cart with fallback.
  FlexiCart readCart() {
    return context.safeRead<FlexiCart<T>>() ?? context.read<FlexiCart>();
  }

  /// Watches the cart for changes with fallback.
  FlexiCart watchCart() {
    return context.safeWatch<FlexiCart<T>>() ?? context.watch<FlexiCart>();
  }

  /// Initializes quantity from cart or initialValue.
  void _initializeQuantity() {
    final quantity =
        widget.initialValue ?? _cart.items[widget.item.key]?.quantity;

    _quantityNotifier
      ..removeListener(_onChanged)
      ..value = quantity;

    _updateText();
    _quantityNotifier.addListener(_onChanged);

    // Add to cart if initial value is set and item doesn't exist.
    if (widget.initialValue != null &&
        _cart.items[widget.item.key]?.quantity == null) {
      _cart.add(
        widget.item..quantity = widget.initialValue,
        shouldNotifyListeners: false,
      );
    }
  }

  /// Current quantity (nullable).
  double? get _quantity => _quantityNotifier.value;

  /// Non-null quantity fallback to 0.
  double get _notNullQuantity => _quantity ?? 0;

  /// Setter for quantity notifier.
  set _quantity(double? value) => _quantityNotifier.value = value;

  /// Fires when quantity changes (input or buttons).
  void _onChanged() {
    final updatedItem = widget.item..quantity = _quantity;
    widget.onChanged?.call(updatedItem);
    _cart.add(updatedItem);
  }

  /// Handles manual input changes.
  void _onTextChanged(String value) {
    _quantity = value.isNotEmpty ? double.tryParse(value) : null;

    // Show "0" if enabled and value is cleared.
    if (widget.showZeroQty && _quantity == null) {
      _updateText();
    }
  }

  /// Decreases quantity by stepper or 0.05 for small values.
  void _onDecreased() {
    final newQty = _notNullQuantity <= 1
        ? _underOneQuantity(inc: false)
        : _notNullQuantity - widget.stepper;
    _quantity = newQty;
    _updateText();
  }

  /// Increases quantity by stepper or 0.05 for small values.
  void _onIncreased() {
    final newQty = _notNullQuantity.betweenZeroAndOne
        ? _underOneQuantity()
        : _notNullQuantity + widget.stepper;
    _quantity = newQty;
    _updateText();
  }

  /// Adjusts value by ±0.05 when between 0 and 1.
  double _underOneQuantity({bool inc = true}) {
    final adjustment = inc ? 50 : -50;
    return ((_notNullQuantity * 1000) + adjustment) / 1000;
  }

  /// Updates input text field from quantity.
  void _updateText() {
    if (_notNullQuantity == 0 && widget.showZeroQty || _notNullQuantity > 0) {
      _controller.text = _notNullQuantity.toStringAsFixed(widget.decimalDigits);
    } else {
      _controller.clear();
    }
  }

  /// Wraps a widget with quantity listener.
  Widget _quantityNotifierBuilder(Widget child) {
    return ValueListenableBuilder<double?>(
      valueListenable: _quantityNotifier,
      builder: (_, __, ___) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ?? CartInputTheme.of(context);

    final decoration = widget.inputDecoration ??
        (isVertical
            ? const InputDecoration(border: InputBorder.none)
            : const InputDecoration(
                isDense: true,
                hintText: '--',
              ));

    final borderRadius = BorderRadius.all(
      style.radius,
    );

    // The central input field
    final child = Container(
      alignment: Alignment.center,
      width: isVertical ? widget.size * 2 : double.infinity,
      child: TextField(
        key: ValueKey(widget.item.key),
        controller: _controller,
        enabled: widget.enabled,
        cursorColor: style.activeForegroundColor,
        keyboardType: widget.keyboardType ??
            TextInputType.numberWithOptions(decimal: widget.decimalDigits > 0),
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s|-')),
          widget.inputFormatter ??
              CartQuantityInputFormatter(
                max: widget.maxQuantity,
                fractionCount: widget.decimalDigits,
              ),
        ],
        onChanged: _onTextChanged,
        style: style.textStyle ??
            (_quantity != null && _quantity! > 0
                ? theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.primaryColor)
                : theme.textTheme.bodyMedium),
        textAlign: widget.textAlign,
        decoration: decoration,
      ),
    );

    // Create button + input + button layout
    final children = <Widget>[
      if (!widget.hideButtons)
        _quantityNotifierBuilder(
          IconButton(
            onPressed: widget.enabled ? _onIncreased : null,
            icon: Icon(
              style.iconPlus ?? Icons.add_circle_outline_outlined,
              color: style.iconTheme.color,
            ),
          ),
        ),
      if (isVertical) child else Expanded(child: child),
      if (!widget.hideButtons)
        _quantityNotifierBuilder(
          IconButton(
            onPressed: widget.enabled ? _onDecreased : null,
            icon: Icon(
              style.iconPlus ?? Icons.remove_circle_outline_outlined,
              color: style.iconTheme.color,
            ),
          ),
        ),
    ];

    // Optional border wrapping
    if (style.border != null) {
      if (isVertical) {
        children[0] = Container(
          decoration: BoxDecoration(
            border: Border(bottom: style.border!.top),
          ),
          child: children[0],
        );
        children[2] = Container(
          decoration: BoxDecoration(
            border: Border(top: style.border!.top),
          ),
          child: children[2],
        );
      } else {
        children[0] = Container(
          decoration: BoxDecoration(
            border: Border(left: style.border!.top),
          ),
          child: children[0],
        );
        children[2] = Container(
          decoration: BoxDecoration(
            border: Border(right: style.border!.top),
          ),
          child: children[2],
        );
      }
    }

    // Main interactive layout with elevation
    Widget body = AnimatedPhysicalModel(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      shape: style.shape,
      borderRadius: borderRadius,
      shadowColor: style.shadowColor ?? const Color.fromARGB(255, 0, 0, 0),
      color: style.activeBackgroundColor,
      elevation: widget.elevation ?? style.elevation,
      child: isVertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children.toList())
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: children.reversed.toList(),
            ),
    );

    // Apply outer border container if defined
    if (style.border != null) {
      body = AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        decoration: BoxDecoration(
          border: style.border,
          borderRadius: borderRadius,
        ),
        child: body,
      );
    }

    return body;
  }

  @override
  void dispose() {
    _quantityNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// Extension for checking if a value is between 0 and 1.
extension on double {
  bool get betweenZeroAndOne => this > 0 && this < 1;
}

/// Extension on [BuildContext] for safe Provider access.
///
/// These avoid exceptions if provider is not available in the tree.
extension on BuildContext {
  T? safeWatch<T>() {
    if (hasProvider<T>()) {
      return watch<T>();
    }
    return null;
  }

  T? safeRead<T>() {
    if (hasProvider<T>()) {
      return read<T>();
    }
    return null;
  }

  bool hasProvider<T>() {
    try {
      read<T>();
      return true;
    } on ProviderNotFoundException catch (_) {
      return false;
    }
  }
}
