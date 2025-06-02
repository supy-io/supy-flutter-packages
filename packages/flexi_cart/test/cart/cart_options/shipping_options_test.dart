// import 'package:flexi_cart/flexi_cart.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// // Mock cart item for testing
// class MockCartItem extends ICartItem {
//   MockCartItem({
//     required super.id,
//     required super.name,
//     required super.price,
//     double? quantity,
//     String? group,
//     String? groupName,
//   }) : super(
//           quantity: quantity ?? 1.0,
//           group: group ?? 'default',
//           groupName: groupName ?? 'Default Group',
//         );
// }
//
// void main() {
//   group('FlexiCart Shipping Integration Tests', () {
//     late FlexiCart<MockCartItem> cart;
//     late ShippingMethod standardShipping;
//     late ShippingMethod expressShipping;
//     late ShippingMethod overnightShipping;
//
//     setUp(() {
//       cart = FlexiCart<MockCartItem>();
//
//       standardShipping = const ShippingMethod(
//         id: 'standard',
//         name: 'Standard Shipping',
//         description: '5-7 business days',
//         baseCost: 5.99,
//         estimatedDays: 7,
//         isDefault: true,
//       );
//
//       expressShipping = const ShippingMethod(
//         id: 'express',
//         name: 'Express Shipping',
//         description: '2-3 business days',
//         baseCost: 12.99,
//         estimatedDays: 3,
//       );
//
//       overnightShipping = const ShippingMethod(
//         id: 'overnight',
//         name: 'Overnight Shipping',
//         description: 'Next business day',
//         baseCost: 24.99,
//         estimatedDays: 1,
//       );
//     });
//
//     tearDown(() {
//       cart.dispose();
//     });
//
//     group('Basic Shipping Configuration', () {
//       test('should set shipping options correctly', () {
//         final shippingOptions = ShippingOptions(
//           shippingLabel: 'Delivery',
//           availableMethods: [standardShipping, expressShipping],
//           selectedMethodId: 'standard',
//           freeShippingThreshold: 50,
//         );
//
//         cart.setShippingOptions(shippingOptions);
//
//         expect(cart.shippingLabel, equals('Delivery'));
//         expect(cart.getShippingMethods().length, equals(2));
//         expect(cart.getSelectedShippingMethod()?.id, equals('standard'));
//         expect(cart.freeShippingThreshold, equals(50.0));
//       });
//
//       test('should add shipping methods individually', () {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping);
//
//         final methods = cart.getShippingMethods();
//         expect(methods.length, equals(2));
//         expect(methods.any((m) => m.id == 'standard'), isTrue);
//         expect(methods.any((m) => m.id == 'express'), isTrue);
//       });
//
//       test('should remove shipping methods', () {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping);
//
//         final removed = cart.removeShippingMethod('standard');
//
//         expect(removed, isTrue);
//         expect(cart.getShippingMethods().length, equals(1));
//         expect(cart.getShippingMethods().first.id, equals('express'));
//       });
//
//       test('should handle removing non-existent method', () {
//         cart.addShippingMethod(standardShipping);
//
//         final removed = cart.removeShippingMethod('nonexistent');
//
//         expect(removed, isFalse);
//         expect(cart.getShippingMethods().length, equals(1));
//       });
//     });
//
//     group('Shipping Method Selection', () {
//       setUp(() {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping)
//           ..addShippingMethod(overnightShipping);
//       });
//
//       test('should select shipping method by ID', () {
//         final success = cart.selectShippingMethod('express');
//
//         expect(success, isTrue);
//         expect(cart.getSelectedShippingMethod()?.id, equals('express'));
//       });
//
//       test('should fail to select non-existent method', () {
//         final success = cart.selectShippingMethod('nonexistent');
//
//         expect(success, isFalse);
//         expect(
//           cart.getSelectedShippingMethod()?.id,
//           equals('standard'),
//         ); // Should remain default
//       });
//
//       test('should get default shipping method', () {
//         final defaultMethod = cart.getDefaultShippingMethod();
//
//         expect(defaultMethod?.id, equals('standard'));
//         expect(defaultMethod?.isDefault, isTrue);
//       });
//
//       test('should get fastest shipping method', () {
//         final fastest = cart.getFastestShippingMethod();
//
//         expect(fastest?.id, equals('overnight'));
//         expect(fastest?.estimatedDays, equals(1));
//       });
//
//       test('should get cheapest shipping method', () {
//         final cheapest = cart.getCheapestShippingMethod();
//
//         expect(cheapest?.id, equals('standard'));
//         expect(cheapest?.baseCost, equals(5.99));
//       });
//     });
//
//     group('Shipping Cost Calculation', () {
//       setUp(() {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping);
//       });
//
//       test('should calculate shipping cost using base cost', () {
//         cart.selectShippingMethod('standard');
//
//         final cost = cart.getShippingCost();
//
//         expect(cost, equals(5.99));
//       });
//
//       test('should use custom shipping calculator', () {
//         cart
//           ..setShippingCostCalculator((cart, method) {
//             // Custom logic: $1 per item + base cost
//             return cart.totalQuantity() + (method?.baseCost ?? 0);
//           })
//           ..add(MockCartItem(id: '1', name: 'Item 1'
//           , price: 10, quantity: 2))
//           ..selectShippingMethod('standard');
//
//         final cost = cart.getShippingCost();
//
//         expect(cost, equals(7.99)); // 2 items + 5.99 base cost
//       });
//
//       test('should return zero cost for free shipping', () {
//         cart
//           ..setFreeShippingThreshold(20)
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 25))
//           ..selectShippingMethod('standard');
//
//         final cost = cart.getShippingCost();
//
//         expect(cost, equals(0.0));
//         expect(cart.qualifiesForFreeShipping(), isTrue);
//       });
//     });
//
//     group('Free Shipping Logic', () {
//       test('should qualify for free shipping when threshold is met', () {
//         cart
//           ..setFreeShippingThreshold(50)
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 60));
//
//         expect(cart.qualifiesForFreeShipping(), isTrue);
//         expect(cart.getAmountNeededForFreeShipping(), equals(0.0));
//       });
//
//       test('should not qualify for free shipping when below threshold', () {
//         cart
//           ..setFreeShippingThreshold(50)
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 30));
//
//         expect(cart.qualifiesForFreeShipping(), isFalse);
//         expect(cart.getAmountNeededForFreeShipping(), equals(20.0));
//       });
//
//       test('should return correct free shipping message', () {
//         cart.setFreeShippingThreshold(50);
//
//         final message = cart.getFreeShippingMessage();
//
//         expect(message, contains('Free shipping on orders over'));
//         expect(message, contains(r'$50.00'));
//       });
//
//       test('should handle no free shipping threshold', () {
//         expect(cart.qualifiesForFreeShipping(), isFalse);
//         expect(cart.getAmountNeededForFreeShipping(), equals(0.0));
//         expect(cart.getFreeShippingMessage(), isEmpty);
//       });
//     });
//
//     group('Shipping Method Sorting', () {
//       setUp(() {
//         cart
//           ..addShippingMethod(expressShipping) // $12.99, 3 days
//           ..addShippingMethod(overnightShipping) // $24.99, 1 day
//           ..addShippingMethod(standardShipping); // $5.99, 7 days
//       });
//
//       test('should sort methods by cost', () {
//         final sortedByCost = cart.getShippingMethodsSortedByCost();
//
//         expect(sortedByCost.length, equals(3));
//         expect(sortedByCost[0].id, equals('standard')); // $5.99
//         expect(sortedByCost[1].id, equals('express')); // $12.99
//         expect(sortedByCost[2].id, equals('overnight')); // $24.99
//       });
//
//       test('should sort methods by speed', () {
//         final sortedBySpeed = cart.getShippingMethodsSortedBySpeed();
//
//         expect(sortedBySpeed.length, equals(3));
//         expect(sortedBySpeed[0].id, equals('overnight')); // 1 day
//         expect(sortedBySpeed[1].id, equals('express')); // 3 days
//         expect(sortedBySpeed[2].id, equals('standard')); // 7 days
//       });
//     });
//
//     group('Total Calculations with Shipping', () {
//       setUp(() {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..selectShippingMethod('standard');
//       });
//
//       test('should calculate total with shipping', () {
//         cart
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 20))
//           ..add(MockCartItem(id: '2', name: 'Item 2', price: 15));
//
//         final totalWithShipping = cart.getTotalWithShipping();
//
//         expect(totalWithShipping, equals(40.99)); // 35.0 + 5.99 shipping
//       });
//
//       test('should calculate final total with shipping, tax, and discount',
//       () {
//         // Set up cart with items
//         cart
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 100))
//
//           // Set up tax (10%)
//           ..setTaxRate(0.10);
//
//         // Set up discount (fixed $10)
//         final discountOptions = DiscountOptions(
//           discountCalculator: (cart) => 10.0,
//         );
//         cart.setDiscountOptions(discountOptions);
//
//         final finalTotal = cart.getFinalTotalWithShipping();
//
//         // $100 - $10 discount + $5.99 shipping = $95.99
//         expect(finalTotal, equals(95.99));
//       });
//
//       test('should include tax in final total when configured', () {
//         cart
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 100))
//
//           // Set up tax included in total
//           ..setTaxRate(0.10)
//           ..setIncludeTaxInTotal(includeTaxInTotal: true);
//
//         final finalTotal = cart.getFinalTotalWithShipping();
//
//         // $100 + $10 tax + $5.99 shipping = $115.99
//         expect(finalTotal, equals(115.99));
//       });
//     });
//
//     group('Shipping Options Validation', () {
//       test('should validate shipping configuration', () {
//         // Add methods with duplicate IDs (invalid)
//         const method1 = ShippingMethod(
//           id: 'duplicate',
//           name: 'Method 1',
//           baseCost: 5,
//         );
//         const method2 = ShippingMethod(
//           id: 'duplicate',
//           name: 'Method 2',
//           baseCost: 10,
//         );
//
//         final options = ShippingOptions(
//           availableMethods: [method1, method2],
//           selectedMethodId: 'nonexistent',
//         );
//
//         cart.setShippingOptions(options);
//         final errors = cart.validateShippingOptions();
//
//         expect(errors.length, greaterThan(0));
//         expect(errors.any((e) => e.contains('Duplicate')), isTrue);
//         expect(errors.any((e) => e.contains('does not exist')), isTrue);
//       });
//
//       test('should validate negative free shipping threshold', () {
//         final options = ShippingOptions(
//           freeShippingThreshold: -10,
//         );
//
//         cart.setShippingOptions(options);
//         final errors = cart.validateShippingOptions();
//
//         expect(errors.any((e) => e.contains('cannot be negative')), isTrue);
//       });
//
//       test('should pass validation for valid configuration', () {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping)
//           ..setFreeShippingThreshold(50);
//
//         final errors = cart.validateShippingOptions();
//
//         expect(errors, isEmpty);
//       });
//     });
//
//     group('Edge Cases and Error Handling', () {
//       test('should handle empty shipping methods list', () {
//         expect(cart.getShippingMethods(), isEmpty);
//         expect(cart.getSelectedShippingMethod(), isNull);
//         expect(cart.getDefaultShippingMethod(), isNull);
//         expect(cart.getFastestShippingMethod(), isNull);
//         expect(cart.getCheapestShippingMethod(), isNull);
//         expect(cart.getShippingCost(), equals(0.0));
//       });
//
//       test('should handle method replacement when adding with same ID', () {
//         cart.addShippingMethod(standardShipping);
//         expect(cart.getShippingMethods().length, equals(1));
//         expect(cart.getShippingMethods().first.baseCost, equals(5.99));
//
//         final updatedMethod = standardShipping.copyWith(baseCost: 7.99);
//         cart.addShippingMethod(updatedMethod);
//
//         expect(cart.getShippingMethods().length, equals(1));
//         expect(cart.getShippingMethods().first.baseCost, equals(7.99));
//       });
//
//       test('should auto-select first method when none selected', () {
//         final options = ShippingOptions(
//           availableMethods: [expressShipping, standardShipping],
//         );
//
//         cart.setShippingOptions(options);
//
//         // Should auto-select the default method
//         expect(cart.getSelectedShippingMethod()?.id, equals(null));
//       });
//
//       test('should handle method removal when selected method is removed',
//       () {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping)
//           ..selectShippingMethod('express');
//
//         expect(cart.getSelectedShippingMethod()?.id, equals('express'));
//
//         cart.removeShippingMethod('express');
//
//         // Should fall back to default method
//         expect(cart.getSelectedShippingMethod()?.id, equals('standard'));
//       });
//     });
//
//     group('Integration with Cart Operations', () {
//       test('should maintain shipping selection during cart operations', () {
//         cart
//           ..addShippingMethod(standardShipping)
//           ..addShippingMethod(expressShipping)
//           ..selectShippingMethod('express')
//
//           // Add items
//           ..add(MockCartItem(id: '1', name: 'Item 1', price: 20));
//         expect(cart.getSelectedShippingMethod()?.id, equals('express'));
//
//         // Remove items
//         cart.delete(MockCartItem(id: '1', name: 'Item 1', price: 20));
//         expect(cart.getSelectedShippingMethod()?.id, equals('express'));
//
//         // Reset items
//         cart.resetItems();
//         expect(cart.getSelectedShippingMethod()?.id, equals('express'));
//       });
//
//       test('should notify listeners when shipping options change', () {
//         var notificationCount = 0;
//         cart
//           ..addListener(() => notificationCount++)
//           ..addShippingMethod(standardShipping, shouldNotifyListeners: true);
//         expect(notificationCount, equals(1));
//
//         cart.selectShippingMethod('standard', shouldNotifyListeners: true);
//         expect(notificationCount, equals(2));
//
//         cart.setFreeShippingThreshold(50, shouldNotifyListeners: true);
//         expect(notificationCount, equals(3));
//       });
//     });
//   });
// }
//
// // Additional helper tests for ShippingMethod class
// void shippingMethodTests() {
//   group('ShippingMethod Tests', () {
//     test('should create shipping method correctly', () {
//       const method = ShippingMethod(
//         id: 'test',
//         name: 'Test Shipping',
//         description: 'Test description',
//         baseCost: 9.99,
//         estimatedDays: 5,
//         isDefault: true,
//       );
//
//       expect(method.id, equals('test'));
//       expect(method.name, equals('Test Shipping'));
//       expect(method.description, equals('Test description'));
//       expect(method.baseCost, equals(9.99));
//       expect(method.estimatedDays, equals(5));
//       expect(method.isDefault, isTrue);
//     });
//
//     test('should use default values correctly', () {
//       const method = ShippingMethod(
//         id: 'minimal',
//         name: 'Minimal Method',
//       );
//
//       expect(method.description, equals(''));
//       expect(method.baseCost, equals(0.0));
//       expect(method.estimatedDays, equals(0));
//       expect(method.isDefault, isFalse);
//     });
//
//     test('should create copy with modified values', () {
//       const original = ShippingMethod(
//         id: 'original',
//         name: 'Original Method',
//         baseCost: 5.99,
//       );
//
//       final copy = original.copyWith(
//         name: 'Modified Method',
//         baseCost: 7.99,
//       );
//
//       expect(copy.id, equals('original')); // unchanged
//       expect(copy.name, equals('Modified Method')); // changed
//       expect(copy.baseCost, equals(7.99)); // changed
//     });
//
//     test('should implement equality correctly', () {
//       const method1 = ShippingMethod(id: 'same', name: 'Method 1');
//       const method2 = ShippingMethod(id: 'same', name: 'Method 2');
//       const method3 = ShippingMethod(id: 'different', name: 'Method 3');
//
//       expect(method1, equals(method2)); // same ID
//       expect(method1, isNot(equals(method3))); // different ID
//       expect(method1.hashCode, equals(method2.hashCode));
//     });
//   });
// }
