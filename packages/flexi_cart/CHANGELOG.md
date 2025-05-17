## 0.2.0

- Added `CartInputTheme` as a `ThemeExtension` for consistent styling.
- Introduced `CartInputStyle` to define visual and structural styles.
- `CartInput` now supports `Axis.vertical` layout and custom border styles.
- Updated `CartInput` to use `AnimatedPhysicalModel` for styled layout with elevation.
- Added `BuildContext.safeRead` and `safeWatch` extensions for safer Provider access.
- Updated tests to cover new theming capabilities and widget enhancements.
- Updated dependencies in the example app.
- Minor refactor in `mixins.dart` to prevent notifying listeners after disposal.
- Corrected method name in README from `onCartChanged` to `onChange`.
- introduces a new example application called `ShineShopApp` that showcases the usage of the
  `flexi_cart`
- introduces a new example application called `Shiny Eats` that showcases the usage of the
  `flexi_cart`
- introduces a new example application called `Shpping App` that showcases the usage of the
  `flexi_cart`

## 0.1.6

- Update the README to reflect current usage examples.
- Remove the deprecated `onCartChanged` method from `ICartPlugin`.
- Clean up internal calls to the removed method.

## 0.1.5

- Introduced new callbacks in the `ICartPlugin` interface: `onChange`, `onError`, and `onClose`.
  These provide plugins with more granular notifications about the cart's lifecycle and state
  changes.
- `onChange`: Called whenever a change occurs in the cart.
- `onError`: Called when an error is thrown within the cart.
- `onClose`: Called just before the cart is disposed.
- The deprecated `onCartChanged` method will be removed soon.
- Updated logging to include whether a listener was notified for cart actions.
- Added tests to verify plugin notifications for the new callbacks.
- Modified example to use the new plugin callbacks for printing cart logs, errors, and close events.

## 0.1.4

- Removed the `tax` and `discount` fields from the `CartItem` class in `cart_item.dart`.

## 0.1.3

- Adds support for locking and unlocking the cart to prevent accidental modifications.
- Implements cart expiration with a set duration.
- Introduces internal logging for debugging cart changes.
- Implements Stream for state emission.
- Adds a plugin architecture for extending cart functionality.
- Includes a new `CartDiff` class to track differences between cart states.
- Adds `setExpiration`, `lock`, `unlock`, `registerPlugin` and `logs` options.
- Enhances the README.md file with new usage examples.
- Adds unit tests for the new functionalities.

## 0.1.2

- **Update Links** update package metadata

## 0.1.1

- **License Update:** Changed the LICENSE file to the MIT License and updated the copyright to
  abed-supy-io.
- **Pubspec Update:** Updated the package description, version to 0.1.1, repository, issue tracker,
  homepage and add `topics` to pubspec.yaml.
- **Cart Input Formatter:** Modified the `formatEditUpdate` method in `cart_input_formatter.dart` to
  handle empty strings and special characters like ',' and '.' more gracefully.
- **Cart Test:** added `decrement` test case in `flexi_cart_test.dart`.
- **Cart Input Widget:** Added a condition to `_onTextChanged` in `cart_input_widget.dart` to handle
  zero quantity.
- **Cart Input Widget:** remove unused  `_quantityNotifier.removeListener` in `dispose`.
- **Cart Mixins:** remove unused `dispose` in `CartChangeNotifierDisposeMixin`
- **FlexiCartTest**: added `resetItems` and  `reset` test case in `flexi_cart_test.dart`.
- **example**: updated example app and add more test cases.
- **FlexiCart**: exported `mixins.dart` in  `flexi_cart.dart`.
- **FlexiCartInputTest**: fix type in `CartInput`.
- **Added** `CONTRIBUTING.md` with guidelines for contributing.

## 0.1.0

- Introduced `CartQuantityInputFormatter` for quantity fields, allowing customizable decimal
  precision.
- Introduced `CartPriceInputFormatter` for price fields, allowing customizable decimal precision.
- Added `CartInputNumberFormatter` as a base class to normalize Arabic digits, limit decimal places,
  and constrain values.
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

- Added `setNote()` & `setDeliveredAt()` functions instead of setters, with `shouldNotifyListeners`
  toggle.

## 0.0.3

- Added `Ordable` property.

## 0.0.2

- Updated README file.

## 0.0.1

- Initial version.
