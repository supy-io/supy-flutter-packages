## 1.0.3+1
- refactor: move cart persistence methods to FlexiCart and rename CartCacheProvider
- Moves `toMap`, `saveToCache`, and `deleteFromCache` methods from the `FlexiCartPersistence` extension directly into the `FlexiCart` class.
- Renames `CartCacheProvider` to `ICartCacheProvider` and updates all usages.
- The `provider` parameter in `saveToCache`, `deleteFromCache`, and `restoreFromCache` is now required.

## 1.0.3
- Added cart persistence with `saveToCache`, `restoreFromCache` and `deleteFromCache`
- Added functionality to save, restore, and delete cart state using a `CartCacheProvider`.
This includes:
- `FlexiCartPersistence` extension with `toMap`, `toJsonString`, `saveToCache`, `restoreFromCache`, and `deleteFromCache` methods.
- `CartCacheProvider` abstract class for custom cache implementations.
- `restoreFrom` method in `FlexiCart` to restore state from another cart instance.
- Serialization support for `CartOptions`, `BehaviorOptions`, and `ValidatorOptions`.
- New tests for cart persistence using `shared_preferences`.
- Example app demonstrating cart caching.

## 1.0.2+3
- Added optional focusNode parameter to CartInput widget

## 1.0.2+2
- Added textInputAction and onSubmitted callbacks to CartInput widget

## 1.0.2+1
- Added AutoFocus to `CartInput` widget.


## 1.0.2
- Added `keepZeroOrNullQuantityItems` option to behavior options

## 1.0.1
- introduced a new `throwWhenDisposed` boolean option to `BehaviorOptions`.
When set to `true` (default), the cart will throw a `CartDisposedException` if an attempt is made to modify it after it has been disposed.
When set to `false`, such attempts will be silently ignored.

## 1.0.0+1
- Reduces the width of screenshots in `README.md` from `200` to `165` for better layout.
- Minor code formatting changes include removing an extra newline in `cart_hooks_test.dart` and adjusting spacing in `cart_hooks.dart`.

## 1.0.0
# Breaking changes:
- Removed 'onDisposed' from flexi_cart.dart, use hooks.onDisposed instead.
- Removed 'onAddItem' from flexi_cart.dart, use hooks.onItemAdded instead.
- Removed 'onDeleteItem' from flexi_cart.dart, use hooks.onItemDeleted instead.
- Removed 'removeItemCondition' from flexi_cart.dart, use options.behaviorOptions.itemFilter instead.
- Removed 'setMetadata' from flexi_cart.dart, use setMetadataEntry instead.
- Removed 'getMetadata' from flexi_cart.dart, use getMetadataEntry instead.
- Removed 'removeMetadata' from flexi_cart.dart, use removeMetadataEntry instead.
# Features:
- Added 'options' to flexi_cart.dart, which includes all previous options and more.
- Added 'options.validatorOptions' to CartOptions.
- Added 'options.behaviorOptions' to CartOptions.

## 0.4.0+2
updates the following screenshots with improved image quality and file size:

- `currencies.png`
- `fresh_market.png`
- `fresh_market_vertical.png`
- `multi_cart.png`
- `shine_beauty.png`
- `shiny_eats.png`
The images have been processed to enhance clarity while reducing overall file sizes.

## 0.4.0+1
- update unit tests to use `CartCurrency` class
- update README to include `CartCurrency` usage examples
- update example app to demonstrate `CartCurrency` functionality

## 0.4.0
New methods:
- `applyExchangeRate(CartCurrency cartCurrency)`: Multiplies all item prices by the given exchange rate and sets the cart's currency.
- `removeExchangeRate()`: Reverts item prices to their original values before the last exchange rate application.

A new class `CartCurrency` is introduced to hold the currency code and exchange rate.

Tests have been added to verify:
- Correct price multiplication after applying an exchange rate.
- Restoration of original prices after removing an exchange rate.
- No change if `removeExchangeRate` is called without a currency applied.
- Price updates when multiple exchange rates are applied sequentially (the new rate is applied to the current prices, not the original ones).


## 0.3.0

- Added a private `_metadata` map to store key-value pairs.
- Added a public getter `metadata` which returns an unmodifiable view of the `_metadata`.
- Introduced `setMetadata(String key, dynamic value)` to add or update metadata entries.
- Introduced `getMetadata<D>(String key)` to retrieve metadata values by key.
- Introduced `removeMetadata(String key)` to remove metadata entries.
- Ensured metadata is cleared during `reset()`.
- Metadata operations can optionally trigger listener notifications.
- The `reset()` method now clears metadata, lock status, and logs, providing a more complete reset.

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
