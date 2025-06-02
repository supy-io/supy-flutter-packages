# FlexiCart Validator - Complete Guide

The FlexiCart validator system provides comprehensive validation capabilities for your shopping
cart, including custom validators, promo code validation, and automatic validation on cart changes.

## Table of Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Validator Options](#validator-options)
- [Custom Validators](#custom-validators)
- [Promo Code Validation](#promo-code-validation)
- [Auto Validation](#auto-validation)
- [API Reference](#api-reference)
- [Examples](#examples)

## Installation

The validator is built into FlexiCart. Simply import FlexiCart and you'll have access to all
validation features:

```dart
import 'package:flexi_cart/flexi_cart.dart';
```

## Basic Usage

### Creating a Cart with Validation

```dart
// Create a cart with validator options
final cart = FlexiCart(
  options: CartOptions(
    // creating validator options
    validatorOptions: ValidatorOptions(
      autoValidate: true, // Enable automatic validation
    ),
  ),
);
```

-  Add a single validation to the cart
```dart
cart.addValidator(CartValidators.cartMaxTotal(/*maximum price*/));
```

- Or add a list of validators to the cart
```dart
cart.addValidators(
[
CartValidators.cartMaxTotal(/*maximum price*/),
CartValidators.cartMinTotal(/*minimum price*/),
CartValidators.cartNotEmpty(),
CartValidators.cartMaxItemCount(/*maximum items quantities*/),
CartValidators.cartMinLength(/*minimum item length*/),
CartValidators.cartMaxLength(/*maximum item length*/),
CartValidators.cartContains(/*required item id*/),
CartValidators.cartRequiredField(/*required field name in metadata*/),
],
);
}
```

### Checking Validation Status
-  Check if cart has validators
```dart
  if (cart.hasValidators) {
print('Cart has ${cart.validators.length} validators');
}
```

-  Get current validation errors
```dart
  final currentErrors = cart.validationErrors;
if (currentErrors.isNotEmpty) {
print('Current validation errors: $currentErrors');
}
```

## Validator Options

### ValidatorOptions Properties

| Property             | Type                        | Default | Description                                 |
|----------------------|-----------------------------|---------|---------------------------------------------|
| `validators`         | `List<ICartValidator>?`     | `[]`    | List of custom validator functions          |
| `promoCode`          | `String?`                   | `null`  | Current promotional code                    |
| `promoCodeValidator` | `String? Function(String)?` | `null`  | Function to validate promo codes            |
| `autoValidate`       | `bool`                      | `false` | Enable automatic validation on cart changes |



## Custom Validators

### Creating Custom Validators
An abstract interface for validating the state of a `FlexiCart`.

Implementations of `ICartValidator` should define custom business logic to ensure that a cart meets specific conditions—such as a minimum order value, maximum item quantity, or other domain-specific constraints.

#### Returns
A `Map<String, dynamic>` containing validation errors.

- Each key identifies the validation rule.
- Each value is a human-readable error message.
- Returns null or an empty map if the cart is valid.

 ```dart
class MinimumOrderValidator extends ICartValidator {
  final double minimumAmount;

  const MinimumOrderValidator(this.minimumAmount);

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    if (cart.totalPrice() < minimumAmount) {
      return {
        'minimum_order': 'Minimum order amount is \$${minimumAmount.toStringAsFixed(2)}'
      };
    }
    return null; // No validation errors
  }
}
```

You can register multiple validators in `ValidatorOptions` to enforce
comprehensive cart validation rules.
  ```dart
abstract class ICartValidator {
  /// Validates the given [cart].
  /// Returns a map of validation errors, or `null` if no errors are found.
  Map<String, dynamic>? validate(FlexiCart cart);
}
```

### Adding and Managing Validators

- Add a single validator
```dart
 cart.addValidator(
CartValidators.cartMaxTotal(/*maximum price*/),
);
```
- Add multiple validators
```dart
  cart.addValidators([
CartValidators.cartMaxTotal(/*maximum price*/),
CartValidators.cartMinTotal(/*minimum price*/),
]);
```
- Remove a specific validator
```dart
  cart.removeValidator(
CartValidators.cartMinTotal(/*minimum price*/),
);
```
- Clear all validators
```dart
  cart.clearValidators();
```

- Get current validators
```dart
  final currentValidators = cart.validators;
print('Number of validators: ${currentValidators.length}');
}
```

### Complex Validator Examples

```dart
//// Validates product-specific rules such as purchase limits and stock availability.
///
/// Enforces:
/// - A limit of 2 alcohol items per order.
/// - That item quantities do not exceed available stock.

class ProductLimitValidator extends ICartValidator {
  const ProductLimitValidator();

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    final errors = <String, dynamic>{};

    for (final item in cart.items.cast<Product>) {
      // Limit alcohol products
      if (item.product.category == 'drink' && item.quantity > 2) {
        errors['drink_limit'] = 'Maximum 2 drink items per order';
      }

      // Check stock availability
      if (item.quantity > item.product.stock) {
        errors['stock_${item.product.id}'] =
        '${item.product.name} only has ${item.product.stock} items in stock';
      }
    }

    return errors.isEmpty ? null : errors;
  }
}
```
```dart
/// Validates whether the user's location is eligible for shipping.
///
/// Uses `getCurrentUserLocation()` and `isShippingAvailable(location)`
/// to determine if shipping is allowed to the user's area.

class ShippingValidator extends ICartValidator {
  const ShippingValidator();

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    final userLocation = getCurrentUserLocation(); // Replace with your actual logic

    if (!isShippingAvailable(userLocation)) {
      return {
        'shipping': 'Shipping not available to your location',
      };
    }

    return null;
  }
}

```

## Promo Code Validation

### Setting Up Promo Code Validation

```dart
// Set promo code validator
cart.setPromoCodeValidator((String code) {
return switch (code.toUpperCase()) {
'SAVE10' => null, // Valid
'WELCOME' => null, // Valid
'EXPIRED20' => 'This promo code has expired', // Invalid
_ => 'Invalid promo code', // Default case
};
});

// Set a promo code
cart.setPromoCode('SAVE10');

// Get current promo code
final currentPromo = cart.promoCode;
print('Current promo code: $currentPromo');

// Validation will automatically check promo code
final errors = cart.validate();
if (errors.containsKey('promoCode')) {
print('Promo code error: ${errors['promoCode']}');
}
```

### Advanced Promo Code Validation

```dart
// Complex promo code validator with business logic
String? advancedPromoValidator(String code) {
  var isFirstTimeCustomer = false; // Simulate first-time customer check
  final now = DateTime.now();

  return switch (code.toUpperCase()) {
    'FIRSTTIME' when !isFirstTimeCustomer =>
    'This code is only for first-time customers',
    'SUMMER2024' when now.isAfter(DateTime(2024, 8, 31)) =>
    'This promotional code has expired',
    'BULK50' when cart.totalQuantity() < 10 =>
    'This code requires minimum 10 items',
    'FLUTTER50' => null, // Valid code
    'SAVE20' => null, // Valid code
    _ => 'Invalid promotional code',
  };
}

cart.setPromoCodeValidator(advancedPromoValidator);
```

## Auto Validation

### Enabling Auto Validation

```dart
// Enable auto validation during cart creation
final cart = FlexiCart(
  options: CartOptions(
    validatorOptions: ValidatorOptions(
      autoValidate: true,
    ),
  ),
);

// Or set it later but it will override any validatorOptions 
cart.setValidatorOptions(
ValidatorOptions(autoValidate: true),
);
```

### How Auto Validation Works

When `autoValidate` is enabled, validation runs automatically whenever:

- `notifyListeners()` is called;


```dart
// With auto validation enabled, this will trigger validation
cart.add(CartItem(id: id, name: name, price: price),shouldNotifyListeners: true)
/// shouldNotifyListeners is true by default

// Check validation errors immediately
if (cart.validationErrors.isNotEmpty) {
print('Validation failed: ${cart.validationErrors}');
}
```
- When `autoValidate` is disabled, you need to call `cart.validate();` each time you do cart action


```dart
  final cart = FlexiCart<ProductItem>(
    options: CartOptions(
      validatorOptions: ValidatorOptions(
        autoValidate: false,
      ),
    ),
  );
  // With auto validation enabled, this will trigger validation
  cart.add(
      CartItem(id: id, name: name, price: price), shouldNotifyListeners: true)

  /// shouldNotifyListeners is true by default

  final validationErrors = cart.validate();
// Check validation errors immediately
  if (validationErrors.isNotEmpty) {
    print('Validation failed: ${cart.validationErrors}');
  }
```
## API Reference

### FlexiCart Validation Methods

| Method                             | Return Type            | Description                              |
|------------------------------------|------------------------|------------------------------------------|
| `validate()`                       | `Map<String, dynamic>` | Manually validate cart and return errors |
| `addValidator(validator)`          | `void`                 | Add a single validator                   |
| `removeValidator(validator)`       | `void`                 | Remove a specific validator              |
| `addValidators(validators)`        | `void`                 | Add multiple validators                  |
| `clearValidators()`                | `void`                 | Remove all validators                    |
| `setPromoCode(code)`               | `void`                 | Set promotional code                     |
| `setPromoCodeValidator(validator)` | `void`                 | Set promo code validator                 |
| `setValidatorOptions(options)`     | `void`                 | Set complete validator options           |

### FlexiCart Validation Properties

| Property           | Type                   | Description                     |
|--------------------|------------------------|---------------------------------|
| `hasValidators`    | `bool`                 | Whether cart has any validators |
| `validators`       | `List<ICartValidator>` | List of current validators      |
| `validationErrors` | `Map<String, dynamic>` | Current validation errors       |
| `promoCode`        | `String?`              | Current promotional code        |

### ValidatorOptions Methods

| Method                       | Return Type            | Description                      |
|------------------------------|------------------------|----------------------------------|
| `validate(cart)`             | `Map<String, dynamic>` | Execute all validators           |
| `addValidator(validator)`    | `void`                 | Add validator to options         |
| `removeValidator(validator)` | `void`                 | Remove validator from options    |
| `addValidators(validators)`  | `void`                 | Add multiple validators          |
| `clearValidators()`          | `void`                 | Clear all validators             |
| `copyWith(...)`              | `ValidatorOptions`     | Create copy with modified values |

## Examples

### Complete E-commerce Validation Setup

```dart
class _MinimumOrderValidator extends ICartValidator {
  _MinimumOrderValidator(this.minAmount);

  final double minAmount;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    return (cart.totalPrice() < minAmount) ?
    {
      'minimum_order': 'Minimum order: \$${minAmount.toStringAsFixed(2)}',
    } : null;
  }
}
/// Validator that limits the total quantity of items in the cart.
class _MaximumItemsValidator extends ICartValidator {
  const _MaximumItemsValidator(this.maxItems);

  final int maxItems;

  @override
  Map<String, dynamic>? validate(FlexiCart cart) {
    return (cart.totalQuantity() > maxItems) ?
    {
      'max_items': 'Maximum $maxItems items allowed',
    } : null;
  }
}
class CartValidationService {
  static List<ICartValidator> getStandardValidators() {
    return [
      _MinimumOrderValidator(25.0),
      _MaximumItemsValidator(50.0)
    ];
  }


  static String? promoCodeValidator(String code) {
    // Your promo code validation logic
    final validCodes = ['SAVE10', 'WELCOME20', 'BULK15'];

    if (!validCodes.contains(code.toUpperCase())) {
      return 'Invalid promotional code';
    }

    return null;
  }
}


// Usage
final cart = FlexiCart(
  options: CartOptions(
    validatorOptions: ValidatorOptions(
      validators: CartValidationService.getStandardValidators(),
      promoCodeValidator: CartValidationService.promoCodeValidator,
      autoValidate: true,
    ),
  ),
);
```

### Reactive UI with Validation

```dart
class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late FlexiCart cart;

  @override
  void initState() {
    super.initState();
    cart = FlexiCart(
      options: CartOptions(
        validatorOptions: ValidatorOptions(
          autoValidate: true,
          validators: [
            const EmptyCartValidator(),
            const MinimumSubtotalValidator(10.0),
          ],
        ),
      ),
    );

    cart.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    setState(() {}); // Update UI when cart changes
  }

  @override
  Widget build(BuildContext context) {
    final errors = cart.validationErrors;

    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: Column(
        children: [
          // Cart item list
          Expanded(child: CartItemsList(cart: cart)),

          // Display validation errors if any
          if (errors.isNotEmpty)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.entries
                    .map((e) => Text(
                  e.value.toString(),
                  style: TextStyle(color: Colors.red),
                ))
                    .toList(),
              ),
            ),

          // Checkout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: errors.isEmpty ? _checkout : null,
              child: Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    final validationResult = cart.validate();

    if (validationResult.isEmpty) {
      // Proceed with checkout
      Navigator.push(context, CheckoutRoute());
    } else {
      // Optional: show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix validation errors')),
      );
    }
  }

  @override
  void dispose() {
    cart.removeListener(_onCartChanged);
    super.dispose();
  }
}

```

## Best Practices

1. **Use Auto Validation**: Enable `autoValidate` for real-time feedback
2. **Keep Validators Simple**: Each validator should check one specific condition
3. **Provide Clear Messages**: Return user-friendly error messages
4. **Handle Edge Cases**: Consider empty carts, zero quantities, etc.
5. **Performance**: Avoid heavy computations in validators since they run frequently
6. **Separation of Concerns**: Keep validation logic separate from UI logic

## Troubleshooting

### Common Issues

**Validation not triggering automatically:**

- Ensure `autoValidate` is set to `true`
- Check that validators return proper error maps

**Promo code validation not working:**

- Verify `promoCodeValidator` is set before setting promo code
- Check that validator returns `null` for valid codes

**Performance issues:**

- Avoid complex operations in validators
- Consider debouncing validation in high-frequency scenarios

---

*This documentation covers FlexiCart validator system. For more information about other FlexiCart
features, check the main documentation.*