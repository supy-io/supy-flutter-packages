//
// import 'package:flexi_cart/flexi_cart.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   group('RecommendationOptions Tests', () {
//     late RecommendationOptions recommendationOptions;
//     late FlexiCart cart;
//     late List<Product> sampleProducts;
//
//     setUp(() {
//       sampleProducts = [
//         Product(id: '1', name: 'Phone', price: 500.0, category:
//         'Electronics'),
//         Product(id: '2', name: 'Case', price: 20.0,
//         category: 'Accessories'),
//         Product(id: '3', name: 'Charger', price: 30.0,
//         category: 'Accessories'),
//         Product(id: '4', name: 'Tablet', price: 300.0,
//         category: 'Electronics'),
//         Product(id: '5', name: 'Headphones', price: 100.0,
//         category: 'Audio'),
//       ];
//
//       cart = FlexiCart();
//       recommendationOptions = RecommendationOptions();
//     });
//
//     test('should return empty list when no suggestion function is provided',
//     () {
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, isEmpty);
//     });
//
//     test('should return recommendations from custom function', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[1], sampleProducts[2]],
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, hasLength(2));
//       expect(recommendations, contains(sampleProducts[1]));
//       expect(recommendations, contains(sampleProducts[2]));
//     });
//
//     test('should respect minimum cart value requirement', () {
//       cart.addItem(CartItem(product: sampleProducts[0], quantity: 1,
//       price: 500.0));
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[1]],
//         config: const RecommendationConfig(
//           minCartValue: 600.0,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, isEmpty);
//     });
//
//     test('should limit number of recommendations', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => sampleProducts,
//         config: const RecommendationConfig(
//           maxRecommendations: 2,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, hasLength(2));
//     });
//
//     test('should exclude cart items when configured', () {
//       cart.addItem(CartItem(product: sampleProducts[0],
//       quantity: 1, price: 500.0));
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => sampleProducts,
//         config: const RecommendationConfig(
//           excludeCartItems: true,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, isNot(contains(sampleProducts[0])));
//     });
//
//     test('should include cart items when configured to do so', () {
//       cart.addItem(CartItem(product: sampleProducts[0], quantity: 1,
//       price: 500.0));
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[0]],
//         config: const RecommendationConfig(
//           excludeCartItems: false,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, contains(sampleProducts[0]));
//     });
//
//     test('should apply custom filtering', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => sampleProducts,
//         filterRecommendations: (product, cart) =>
//         (product as Product).category == 'Electronics',
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, hasLength(2));
//       expect(recommendations.every((p) => (p as Product).category ==
//       'Electronics'), isTrue);
//     });
//
//     test('should apply custom sorting', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => sampleProducts,
//         sortRecommendations: (a, b) =>
//             (a as Product).price.compareTo((b as Product).price),
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, isNotEmpty);
//
//       // Check if sorted by price (ascending)
//       for (int i = 0; i < recommendations.length - 1; i++) {
//         final currentPrice = (recommendations[i] as Product).price;
//         final nextPrice = (recommendations[i + 1] as Product).price;
//         expect(currentPrice, lessThanOrEqualTo(nextPrice));
//       }
//     });
//
//     test('should trigger onRecommendationGenerated callback', () {
//       FlexiCart? callbackCart;
//       List<dynamic>? callbackRecommendations;
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[0]],
//         onRecommendationGenerated: (cart, recommendations) {
//           callbackCart = cart;
//           callbackRecommendations = recommendations;
//         },
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       recommendationOptions.recommend(cart);
//
//       expect(callbackCart, equals(cart));
//       expect(callbackRecommendations, isNotNull);
//       expect(callbackRecommendations, hasLength(1));
//     });
//
//     test('should handle errors and trigger error callback', () {
//       dynamic callbackError;
//       FlexiCart? callbackCart;
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => throw Exception('Test error'),
//         onRecommendationError: (cart, error) {
//           callbackCart = cart;
//           callbackError = error;
//         },
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//
//       expect(recommendations, isEmpty);
//       expect(callbackError, isNotNull);
//       expect(callbackCart, equals(cart));
//     });
//
//     test('should cache recommendations when enabled', () {
//       cart.addItem(CartItem(product: sampleProducts[0],
//       quantity: 1, price: 500.0));
//
//       int callCount = 0;
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) {
//           callCount++;
//           return [sampleProducts[1]];
//         },
//         config: const RecommendationConfig(
//           enableCaching: true,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       // First call
//       final recommendations1 = recommendationOptions.recommend(cart);
//       expect(callCount, equals(1));
//       expect(recommendations1, hasLength(1));
//
//       // Second call should use cache
//       final recommendations2 = recommendationOptions.recommend(cart);
//       expect(callCount, equals(1)); // Should not increment
//       expect(recommendations2, hasLength(1));
//     });
//
//     test('should clear cache', () {
//       cart.addItem(CartItem(product: sampleProducts[0],
//       quantity: 1, price: 500.0));
//
//       int callCount = 0;
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) {
//           callCount++;
//           return [sampleProducts[1]];
//         },
//         config: const RecommendationConfig(
//           enableCaching: true,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       // First call
//       recommendationOptions.recommend(cart);
//       expect(callCount, equals(1));
//
//       // Clear cache
//       recommendationOptions.clearCache();
//
//       // Second call should not use cache
//       recommendationOptions.recommend(cart);
//       expect(callCount, equals(2));
//     });
//
//     test('should provide cache statistics', () {
//       cart.addItem(CartItem(product: sampleProducts[0],
//       quantity: 1, price: 500.0));
//
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[1]],
//         config: const RecommendationConfig(
//           enableCaching: true,
//           strategies: [RecommendationStrategy.custom],
//         ),
//       );
//
//       // Generate some cache entries
//       recommendationOptions.recommend(cart);
//
//       final stats = recommendationOptions.getCacheStats();
//       expect(stats['totalEntries'], equals(1));
//       expect(stats['validEntries'], equals(1));
//       expect(stats['expiredEntries'], equals(0));
//     });
//
//     test('should remove duplicates from recommendations', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [
//           sampleProducts[0],
//           sampleProducts[1],
//           sampleProducts[0], // Duplicate
//           sampleProducts[1], // Duplicate
//         ],
//         config: const RecommendationConfig(strategies:
//         [RecommendationStrategy.custom]),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       expect(recommendations, hasLength(2));
//       expect(recommendations.toSet(), hasLength(2)); // Ensure no duplicates
//     });
//
//     test('should work with multiple strategies', () {
//       recommendationOptions = RecommendationOptions(
//         suggestProducts: (cart) => [sampleProducts[0]],
//         config: const RecommendationConfig(
//           strategies: [
//             RecommendationStrategy.custom,
//             RecommendationStrategy.similarCategories,
//           ],
//         ),
//       );
//
//       final recommendations = recommendationOptions.recommend(cart);
//       // Should work even if some strategies return empty lists
//       expect(recommendations, isNotNull);
//     });
//   });
//
//   group('RecommendationConfig Tests', () {
//     test('should have default values', () {
//       const config = RecommendationConfig();
//
//       expect(config.maxRecommendations, equals(5));
//       expect(config.minCartValue, equals(0.0));
//       expect(config.excludeCartItems, isTrue);
//       expect(config.enableCaching, isTrue);
//       expect(config.cacheExpirationMinutes, equals(30));
//       expect(config.strategies,
//       equals([RecommendationStrategy.similarCategories]));
//     });
//
//     test('should accept custom values', () {
//       const config = RecommendationConfig(
//         maxRecommendations: 10,
//         minCartValue: 100.0,
//         excludeCartItems: false,
//         enableCaching: false,
//         cacheExpirationMinutes: 60,
//         strategies: [RecommendationStrategy.custom,
//         RecommendationStrategy.priceRange],
//       );
//
//       expect(config.maxRecommendations, equals(10));
//       expect(config.minCartValue, equals(100.0));
//       expect(config.excludeCartItems, isFalse);
//       expect(config.enableCaching, isFalse);
//       expect(config.cacheExpirationMinutes, equals(60));
//       expect(config.strategies, hasLength(2));
//     });
//   });
// }
