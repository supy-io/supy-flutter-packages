import 'package:flexi_cart/src/qty_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'cart.dart';
import 'cart_item.dart';

class CartInput<T extends ICartItem> extends StatefulWidget {
  const CartInput({
    super.key,
    required this.item,
    this.hideButtons = false,
    this.showZeroQty = false,
    this.inputDecoration,
    this.onChanged,
    this.decimalDigits = 2,
    this.maxQuantity = 999999,
    this.textAlign = TextAlign.center,
  });

  final ICartItem item;
  final bool hideButtons;
  final bool showZeroQty;
  final InputDecoration? inputDecoration;
  final ValueChanged<T>? onChanged;
  final int decimalDigits;
  final int maxQuantity;
  final TextAlign textAlign;

  @override
  State<CartInput> createState() => _CartInputState();
}

class _CartInputState extends State<CartInput> {
  late final FlexiCart _cart;

  final _quantityValueNotifier = ValueNotifier<double?>(null);

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cart = context.read<FlexiCart>();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<FlexiCart>();
    final inCartQuantity = _cart.items[widget.item.key]?.quantity;
    if (inCartQuantity != _quantity) {
      _init();
    }
  }

  void _init() {
    final key = widget.item.key;

    final quantity = _cart.items[key]?.quantity;

    _quantityValueNotifier.removeListener(_onChanged);

    _quantityValueNotifier.value = quantity;

    _updateText();

    _quantityValueNotifier.addListener(_onChanged);
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.item.key;
    final themeData = Theme.of(context);
    final textTheme = themeData.textTheme;
    final textStyle = textTheme.bodyMedium;
    final inputDecoration = widget.inputDecoration ??
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
              onPressed: _onIncreased,
              icon: const Icon(Icons.add_circle_outline_outlined),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            clipBehavior: Clip.antiAlias,
            key: ValueKey(key),
            controller: _controller,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimalDigits > 0,
            ),
            inputFormatters: <TextInputFormatter>[
              //white space is not allowed
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              // //signed is not allowed
              FilteringTextInputFormatter.deny(RegExp(r'-')),

              QuantityInputFormatter(widget.maxQuantity),
            ],
            onChanged: _onTextChanged,
            style: _quantity != null && _quantity! > 0
                ? textStyle?.copyWith(color: themeData.primaryColor)
                : textStyle,
            textAlign: widget.textAlign,
            decoration: inputDecoration,
          ),
        ),
        const SizedBox(width: 8),
        if (!widget.hideButtons)
          _quantityNotifierBuilder(
            IconButton(
              onPressed: _onDecreased,
              icon: const Icon(Icons.remove_circle_outline_outlined),
            ),
          )
      ],
    );
  }

  double? get _quantity => _quantityValueNotifier.value;

  double get _notNullQuantity => _quantityValueNotifier.value ?? 0;

  set _quantity(double? value) => _quantityValueNotifier.value = value;

  void _onChanged() {
    var item = widget.item..quantity = _quantity;
    widget.onChanged?.call(item);
    context.read<FlexiCart>().add(item);
  }

  void _onDecreased() {
    final newQuantity = _notNullQuantity.underOrEqualOne
        ? _underOneQuantity(inc: false)
        : _notNullQuantity - 1;
    _quantity = newQuantity;
    _updateText();
  }

  void _onIncreased() {
    final newQuantity = _notNullQuantity.betweenZeroAndOne
        ? _underOneQuantity()
        : _notNullQuantity + 1;
    _quantity = newQuantity;
    _updateText();
  }

  double _underOneQuantity({inc = true}) {
    final value = inc ? 50 : -50;
    return ((_notNullQuantity * 1000) + value) / 1000;
  }

  void _updateText() {
    if (_quantity == 0 && widget.showZeroQty || _notNullQuantity > 0) {
      _controller.text = _notNullQuantity.toStringAsFixed(widget.decimalDigits);
      return;
    }

    _controller.clear();
  }

  void _onTextChanged(String value) {
    _quantity = value.isNotEmpty ? double.parse(value) : null;
  }

  Widget _quantityNotifierBuilder(Widget child) {
    return ValueListenableBuilder(
      valueListenable: _quantityValueNotifier,
      builder: (context, value, _) => child,
    );
  }
}

extension on double {
  bool get betweenZeroAndOne => toInt() == 0 && this > 0;

  bool get underOrEqualOne => this <= 1 && this > 0;
}
