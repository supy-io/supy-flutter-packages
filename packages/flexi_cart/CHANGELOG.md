## 0.1.1
**License Update:** Changed the LICENSE file to the MIT License and updated the copyright to abed-supy-io.
**Pubspec Update:** Updated the package description, version to 0.1.1, repository, issue tracker, homepage and add `topics` to pubspec.yaml.
**Cart Input Formatter:** Modified the `formatEditUpdate` method in `cart_input_formatter.dart` to handle empty strings and special characters like ',' and '.' more gracefully.
**Cart Test:** added `decrement` test case in `flexi_cart_test.dart`.
**Cart Input Widget:** Added a condition to `_onTextChanged` in `cart_input_widget.dart` to handle zero quantity.
**Cart Input Widget:** remove unused  `_quantityNotifier.removeListener` in `dispose`.
**Cart Mixins:** remove unused `dispose` in `CartChangeNotifierDisposeMixin`
**FlexiCartTest**: added `resetItems` and  `reset` test case in `flexi_cart_test.dart`.
**example**: updated example app and add more test cases.
**FlexiCart**: exported `mixins.dart` in  `flexi_cart.dart`.
**FlexiCartInputTest**: fix type in `CartInput`.
**Added** `CONTRIBUTING.md` with guidelines for contributing.

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
