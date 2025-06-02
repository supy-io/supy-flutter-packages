// import 'package:flexi_cart/flexi_cart.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import '../../helpers/mocks.dart';
//
// void main() {
//   group('DiscountOptions', () {
//     test('returns 0.0 when no discountCalculator is provided', () {
//       final discount = DiscountOptions();
//       final fakeCart = FlexiCart();
//       expect(discount.calculate(fakeCart), 0.0);
//     });
//
//     test('applies discountCalculator correctly', () {
//       final discount = DiscountOptions(
//         discountCalculator: (cart) => 10.0,
//       );
//
//       final fakeCart = FlexiCart();
//
//       expect(discount.calculate(fakeCart), 10.0);
//     });
//
//     test('returns custom label', () {
//       final discount = DiscountOptions(discountLabel: 'Summer Sale');
//       expect(discount.discountLabel, 'Summer Sale');
//     });
//
//     test('discountCalculator can depend on cart data', () {
//       final cart = FlexiCart()
//         ..add(MockItem(price: 10, id: 'id', name: 'name')); // Total = 10.0
//
//       final discount = DiscountOptions(
//         discountCalculator: (cart) => cart.totalPrice() * 0.1,
//       );
//       expect(discount.calculate(cart), 1.0);
//     });
//
//     test('returns 0.0 for empty cart with discountCalculator', () {
//       final discount = DiscountOptions(
//         discountCalculator: (cart) => cart.totalPrice() * 0.2,
//       );
//       final cart = FlexiCart(); // Total = 0.0
//       expect(discount.calculate(cart), 0.0);
//     });
//
//     test('handles discount greater than cart total', () {
//       final cart = FlexiCart()
//         ..add(MockItem(price: 10, id: 'id', name: 'name'));
//
//       final discount = DiscountOptions(
//         discountCalculator: (c) => 20.0,
//       );
//       expect(discount.calculate(cart), 20.0);
//     });
//
//     test('handles negative discount (e.g. penalty)', () {
//       final cart = FlexiCart()
//         ..add(MockItem(price: 10, id: 'id', name: 'name'));
//
//       final discount = DiscountOptions(
//         discountCalculator: (c) => -5.0,
//         allowNegative: true,
//       );
//
//       expect(
//         discount.calculate(cart),
//         -5.0,
//       );
//     });
//
//     test('handles very large discount', () {
//       final cart = FlexiCart()
//         ..add(MockItem(price: 1000000, id: 'id', name: 'name'));
//       final discount = DiscountOptions(
//         discountCalculator: (c) => 999999.99,
//       );
//
//       expect(discount.calculate(cart), closeTo(999999.99, 0.001));
//     });
//
//     test('handles floating point precision correctly', () {
//       final cart = FlexiCart()
//         ..add(
//           MockItem(price: 0.1, id: 'id', name: 'name'),
//         );
//       final discount = DiscountOptions(
//         discountCalculator: (c) => c.totalPrice() * 0.3,
//       );
//
//       expect(discount.calculate(cart), closeTo(0.03, 0.0001));
//     });
//
//     test('custom label remains correct regardless of logic', () {
//       final discount = DiscountOptions(
//         discountLabel: '💰 Cashback!',
//         discountCalculator: (cart) => 2.5,
//       );
//
//       final cart = FlexiCart();
//       expect(discount.discountLabel, '💰 Cashback!');
//       expect(discount.calculate(cart), 2.5);
//     });
//     test('check total with discount value', () {
//       final cart = FlexiCart(
//         options: CartOptions(
//           discountOptions: DiscountOptions(
//             discountLabel: '💰 Cashback!',
//             discountCalculator: (cart) => cart.totalPrice() * 0.25,
//           ),
//         ),
//       )..add(MockItem(price: 10, id: 'id', name: 'name'));
//       expect(cart.discount(), 2.5);
//       expect(cart.getTotalAfterDiscount(), 7.5);
//     });
//   });
// }
