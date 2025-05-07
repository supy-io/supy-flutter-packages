## 0.1.0
- Introduced `CartQuantityInputFormatter` for quantity fields, allowing customizable decimal precision.
- Introduced `CartPriceInputFormatter` for price fields, allowing customizable decimal precision.
- Added `CartInputNumberFormatter` as a base class to normalize Arabic digits, limit decimal places, and constrain values.
- Deprecated `QuantityInputFormatter`, advising to use `CartQuantityInputFormatter` instead.
- Improved documentation.
- Added various example on cart input.
- Adds `description`, `metadata`, `tax`, and `discount` fields in the `ICartItem` model
- Added `CartChangeNotifierDisposeMixin` to handle the disposal of `ChangeNotifier`.
- Add flexi-cart formatter and mixin tests.
- Add flexi-cart input test.

## 0.0.9
- Added `ChangeNotifierDisposeMixin` to prevent calling `notifyListeners()` after dispose.
- Updated test cases to include `shouldNotifyListeners` option and assert `DateTime` type.

## 0.0.8
- Removed `removeNullQuantity` option & fixed cart logic.

## 0.0.7
- Added `removeNullQuantity` option.

## 0.0.5
- Allowed `,` in `CartInput` widget.
- Added group methods in cart.

## 0.0.4
- Added `setNote()` & `setDeliveredAt()` functions instead of setters, with `shouldNotifyListeners` toggle.

## 0.0.3
- Added `Ordable` property.

## 0.0.2
- Updated README file.

## 0.0.1
- Initial version.
