import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A generic quantity input widget for cart items implementing [ICartItem].
///
/// This widget displays a numeric input field (with optional increment/decrement buttons)
/// and allows users to modify the quantity of a cart item.
/// It also integrates with
/// [FlexiCart] for automatic cart state updates and supports both
/// integer and fractional quantities.
///
/// The widget is highly customizable with support for:
/// - maximum quantity limits,
/// - decimal digit control,
/// - optional zero display,
/// - input formatting (e.g., Arabic numerals),
/// - input enable/disable states,
/// - external state management via [ValueChanged].
///
/// Example usage:
/// ```dart
/// CartInput<MyCartItem>(
///   item: item,
///   decimalDigits: 2,
///   maxQuantity: 1000,
///   onChanged: (updatedItem) {
///     print("New quantity: ${updatedItem.quantity}");
///   },
/// )
/// ```
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
  });

  /// The cart item to be displayed and updated.
  final T item;

  /// Initial quantity value to override cart value.
  final double? initialValue;

  /// Callback triggered when the quantity changes.
  final ValueChanged<T>? onChanged;

  /// If true, hides the "+" and "−" buttons.
  final bool hideButtons;

  /// If true, shows "0" instead of clearing the input when quantity is 0.
  final bool showZeroQty;

  /// Number of decimal digits allowed in the quantity.
  final int decimalDigits;

  /// Maximum quantity that can be input by the user.
  final int maxQuantity;

  /// Decoration applied to the quantity input field.
  final InputDecoration? inputDecoration;

  /// Text alignment inside the input field.
  final TextAlign textAlign;

  /// Whether the input field and buttons are enabled for interaction.
  final bool enabled;

  /// Optional custom input formatter. If null, defaults to
  /// [CartQuantityInputFormatter].
  final TextInputFormatter? inputFormatter;

  @override
  State<CartInput<T>> createState() => _CartInputState<T>();
}

class _CartInputState<T extends ICartItem> extends State<CartInput<T>> {
  late final FlexiCart _cart;
  late final TextEditingController _controller;
  late final ValueNotifier<double?> _quantityNotifier;

  @override
  void initState() {
    super.initState();
    _cart = context.read<FlexiCart>();
    _controller = TextEditingController();
    _quantityNotifier = ValueNotifier<double?>(widget.initialValue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuantity();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inCartQuantity =
        context.watch<FlexiCart>().items[widget.item.key]?.quantity;
    if (inCartQuantity != _quantity) {
      _initializeQuantity();
    }
  }

  /// Initializes quantity value from cart or external input.
  void _initializeQuantity() {
    final quantity =
        widget.initialValue ?? _cart.items[widget.item.key]?.quantity;

    _quantityNotifier
      ..removeListener(_onChanged)
      ..value = quantity;
    _updateText();
    _quantityNotifier.addListener(_onChanged);

    if (widget.initialValue != null &&
        _cart.items[widget.item.key]?.quantity == null) {
      _cart.add(widget.item..quantity = widget.initialValue);
    }
  }

  /// The current quantity value (nullable).
  double? get _quantity => _quantityNotifier.value;

  /// A guaranteed non-null quantity (returns 0 if null).
  double get _notNullQuantity => _quantity ?? 0;

  /// Updates the internal quantity notifier.
  set _quantity(double? value) => _quantityNotifier.value = value;

  /// Triggered when quantity changes, updates the cart and calls
  /// [_onChanged].
  void _onChanged() {
    final updatedItem = widget.item..quantity = _quantity;
    widget.onChanged?.call(updatedItem);
    _cart.add(updatedItem);
  }

  /// Triggered when input text is edited manually.
  void _onTextChanged(String value) {
    _quantity = value.isNotEmpty ? double.tryParse(value) : null;

    if (widget.showZeroQty && _quantity == null) {
      _updateText();
    }
  }

  /// Decreases the quantity by 1 or a small fraction if under 1.
  void _onDecreased() {
    final newQty = _notNullQuantity <= 1
        ? _underOneQuantity(inc: false)
        : _notNullQuantity - 1;
    _quantity = newQty;
    _updateText();
  }

  /// Increases the quantity by 1 or a small fraction if under 1.
  void _onIncreased() {
    final newQty = _notNullQuantity.betweenZeroAndOne
        ? _underOneQuantity()
        : _notNullQuantity + 1;
    _quantity = newQty;
    _updateText();
  }

  /// Adjusts values smaller than 1 by 0.05 (±50/1000).
  double _underOneQuantity({bool inc = true}) {
    final adjustment = inc ? 50 : -50;
    return ((_notNullQuantity * 1000) + adjustment) / 1000;
  }

  /// Updates the text in the input field based on current quantity.
  void _updateText() {
    if (_notNullQuantity == 0 && widget.showZeroQty || _notNullQuantity > 0) {
      _controller.text = _notNullQuantity.toStringAsFixed(widget.decimalDigits);
    } else {
      _controller.clear();
    }
  }

  /// Wraps a widget with a [ValueListenableBuilder]
  /// to rebuild on quantity change.
  Widget _quantityNotifierBuilder(Widget child) {
    return ValueListenableBuilder<double?>(
      valueListenable: _quantityNotifier,
      builder: (_, __, ___) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = widget.inputDecoration ??
        const InputDecoration(
          contentPadding: EdgeInsets.all(8),
          isDense: true,
          hintText: '--',
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!widget.hideButtons)
          _quantityNotifierBuilder(
            IconButton(
              onPressed: widget.enabled ? _onIncreased : null,
              icon: const Icon(Icons.add_circle_outline_outlined),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            key: ValueKey(widget.item.key),
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimalDigits > 0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              FilteringTextInputFormatter.deny(RegExp('-')),
              widget.inputFormatter ??
                  CartQuantityInputFormatter(
                    max: widget.maxQuantity,
                    fractionCount: widget.decimalDigits,
                  ),
            ],
            onChanged: _onTextChanged,
            style: _quantity != null && _quantity! > 0
                ? theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.primaryColor)
                : theme.textTheme.bodyMedium,
            textAlign: widget.textAlign,
            textAlignVertical: TextAlignVertical.center,
            decoration: decoration,
          ),
        ),
        const SizedBox(width: 8),
        if (!widget.hideButtons)
          _quantityNotifierBuilder(
            IconButton(
              onPressed: widget.enabled ? _onDecreased : null,
              icon: const Icon(Icons.remove_circle_outline_outlined),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// Extension methods for numeric logic.
extension on double {
  /// Returns true if value is between 0 and 1 (exclusive).
  bool get betweenZeroAndOne => this > 0 && this < 1;
}
