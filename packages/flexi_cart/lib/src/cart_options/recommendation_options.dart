part of 'cart_options.dart';

/// Defines the types of recommendation strategies available.
enum RecommendationStrategy {
  /// Suggests items often purchased together with cart items.
  frequentlyBoughtTogether,

  /// Suggests items from similar product categories.
  similarCategories,

  /// Suggests items within a similar price range.
  priceRange,

  /// Suggests items based on user purchase history.
  userHistory,

  /// Uses a custom recommendation strategy provided by the developer.
  custom,
}

/// Holds configuration options for generating product recommendations.
class RecommendationConfig {
  /// Creates a new instance of [RecommendationConfig].
  const RecommendationConfig({
    this.maxRecommendations = 5,
    this.minCartValue = 0.0,
    this.excludeCartItems = true,
    this.enableCaching = true,
    this.cacheExpirationMinutes = 30,
    this.strategies = const [RecommendationStrategy.similarCategories],
  });

  /// The maximum number of recommendations to return.
  final int maxRecommendations;

  /// Minimum total cart value required to generate recommendations.
  final double minCartValue;

  /// Whether to exclude products already in the cart from recommendations.
  final bool excludeCartItems;

  /// Enables caching of generated recommendations.
  final bool enableCaching;

  /// Number of minutes after which a cached recommendation expires.
  final int cacheExpirationMinutes;

  /// List of recommendation strategies to apply.
  final List<RecommendationStrategy> strategies;
}

/// Stores cached recommendation results with their creation timestamp.
class _CachedRecommendation {
  /// Constructs a cached recommendation with [recommendations] and [timestamp].
  _CachedRecommendation(this.recommendations, this.timestamp);

  /// The list of cached recommended items.
  final List<ICartItem> recommendations;

  /// The timestamp when these recommendations were generated.
  final DateTime timestamp;

  /// Determines if the cached data is expired based on [expirationMinutes].
  bool isExpired(int expirationMinutes) {
    return DateTime.now().difference(timestamp).inMinutes > expirationMinutes;
  }
}

/// Provides dynamic product recommendations based on cart contents and strategy.
class RecommendationOptions {
  /// Creates a new instance of [RecommendationOptions].
  RecommendationOptions({
    this.suggestProducts,
    this.config = const RecommendationConfig(),
    this.onRecommendationGenerated,
    this.onRecommendationError,
    this.filterRecommendations,
    this.sortRecommendations,
    this.productCategoryMapper,
    this.priceRangeCalculator,
  });

  /// Configuration options for the recommendation engine.
  final RecommendationConfig config;

  /// Optional custom function to generate recommendations manually.
  final List<ICartItem> Function(FlexiCart cart)? suggestProducts;

  /// Callback triggered when recommendations are successfully generated.
  final void Function(FlexiCart cart, List<ICartItem> recommendations)?
      onRecommendationGenerated;

  /// Callback triggered when recommendation generation fails.
  final void Function(FlexiCart cart, Object error)? onRecommendationError;

  /// Optional custom filter function to refine recommended products.
  final bool Function(ICartItem product, FlexiCart cart)? filterRecommendations;

  /// Optional comparator function to sort recommended products.
  final int Function(ICartItem a, ICartItem b)? sortRecommendations;

  /// Maps a product to its category for category-based recommendation logic.
  final String Function(ICartItem product)? productCategoryMapper;

  /// Calculates the price of a product for price-based recommendation logic.
  final double Function(ICartItem cartItem)? priceRangeCalculator;

  /// Internal cache for storing generated recommendations.
  final Map<String, _CachedRecommendation> _recommendationCache = {};

  /// Generates a list of recommended products for the given [cart].
  List<ICartItem> recommend(FlexiCart cart) {
    try {
      if (cart.totalPrice() < config.minCartValue) {
        return [];
      }

      final cacheKey = _generateCacheKey(cart);
      if (config.enableCaching) {
        final cached = _recommendationCache[cacheKey];
        if (cached != null &&
            !cached.isExpired(config.cacheExpirationMinutes)) {
          return cached.recommendations;
        }
      }

      var recommendations = <ICartItem>[];

      for (final strategy in config.strategies) {
        recommendations.addAll(_getRecommendationsByStrategy(strategy, cart));
      }

      recommendations = _removeDuplicates(recommendations);

      if (config.excludeCartItems) {
        recommendations = _excludeCartItems(recommendations, cart);
      }

      if (filterRecommendations != null) {
        recommendations = recommendations
            .where((product) => filterRecommendations!(product, cart))
            .toList();
      }

      if (sortRecommendations != null) {
        recommendations.sort(sortRecommendations);
      }

      if (recommendations.length > config.maxRecommendations) {
        recommendations =
            recommendations.take(config.maxRecommendations).toList();
      }

      if (config.enableCaching) {
        _recommendationCache[cacheKey] =
            _CachedRecommendation(recommendations, DateTime.now());
      }

      onRecommendationGenerated?.call(cart, recommendations);
      return recommendations;
    } catch (error) {
      onRecommendationError?.call(cart, error);
      return [];
    }
  }

  /// Clears all cached recommendation data.
  void clearCache() {
    _recommendationCache.clear();
  }

  /// Returns statistics about the recommendation cache.
  ///
  /// Includes:
  /// - `totalEntries`: Total number of cache entries.
  /// - `expiredEntries`: Number of expired cache entries.
  /// - `validEntries`: Number of still-valid cache entries.
  Map<String, dynamic> getCacheStats() {
    final expired = _recommendationCache.values
        .where((cached) => cached.isExpired(config.cacheExpirationMinutes))
        .length;

    return {
      'totalEntries': _recommendationCache.length,
      'expiredEntries': expired,
      'validEntries': _recommendationCache.length - expired,
    };
  }

  /// Applies the appropriate strategy to get recommendations for [cart].
  List<ICartItem> _getRecommendationsByStrategy(
      RecommendationStrategy strategy, FlexiCart cart,) {
    switch (strategy) {
      case RecommendationStrategy.custom:
        return suggestProducts?.call(cart) ?? [];
      case RecommendationStrategy.similarCategories:
        return _getSimilarCategoryRecommendations(cart);
      case RecommendationStrategy.priceRange:
        return _getPriceRangeRecommendations(cart);
      case RecommendationStrategy.frequentlyBoughtTogether:
        return _getFrequentlyBoughtTogetherRecommendations(cart);
      case RecommendationStrategy.userHistory:
        return _getUserHistoryRecommendations(cart);
    }
  }

  /// Generates recommendations based on similar product categories.
  List<ICartItem> _getSimilarCategoryRecommendations(FlexiCart cart) {
    if (productCategoryMapper == null) return [];

    final cartCategories =
        cart.itemsList.map((item) => productCategoryMapper!(item)).toSet();

    // TODO: Implement fetching logic using category info
    return [];
  }

  /// Generates recommendations based on average cart price range.
  List<ICartItem> _getPriceRangeRecommendations(FlexiCart cart) {
    if (priceRangeCalculator == null || cart.items.isEmpty) return [];

    final avgPrice = cart.itemsList
            .map((item) => priceRangeCalculator!(item))
            .reduce((a, b) => a + b) /
        cart.items.length;

    // TODO: Implement fetching logic using avgPrice
    return [];
  }

  /// Placeholder for frequently bought together recommendation logic.
  List<ICartItem> _getFrequentlyBoughtTogetherRecommendations(FlexiCart cart) {
    // TODO: Implement real logic using analytics data
    return [];
  }

  /// Placeholder for user history-based recommendation logic.
  List<ICartItem> _getUserHistoryRecommendations(FlexiCart cart) {
    // TODO: Implement logic using user data
    return [];
  }

  /// Removes duplicate items based on their `product` identity.
  List<ICartItem> _removeDuplicates(List<ICartItem> recommendations) {
    final seen = <Object>{};
    return recommendations.where(seen.add).toList();
  }

  /// Filters out products that are already in the user's cart.
  List<ICartItem> _excludeCartItems(
      List<ICartItem> recommendations, FlexiCart cart,) {
    final cartProducts = cart.itemsList.map((item) => item).toSet();
    return recommendations
        .where((item) => !cartProducts.contains(item))
        .toList();
  }

  /// Generates a unique cache key for the current cart based on product hashes.
  String _generateCacheKey(FlexiCart cart) {
    final itemIds = cart.itemsList.map((item) => item.hashCode).toList()
      ..sort();
    return 'cart_${itemIds.join('_')}';
  }

  /// Creates a copy of this [RecommendationOptions] with optional overrides.
  RecommendationOptions copyWith({
    List<ICartItem> Function(FlexiCart cart)? suggestProducts,
    RecommendationConfig? config,
    void Function(FlexiCart cart, List<ICartItem> recommendations)?
        onRecommendationGenerated,
    void Function(FlexiCart cart, Object error)? onRecommendationError,
    bool Function(ICartItem product, FlexiCart cart)? filterRecommendations,
    int Function(ICartItem a, ICartItem b)? sortRecommendations,
    String Function(ICartItem product)? productCategoryMapper,
    double Function(ICartItem cartItem)? priceRangeCalculator,
  }) {
    return RecommendationOptions(
      suggestProducts: suggestProducts ?? this.suggestProducts,
      config: config ?? this.config,
      onRecommendationGenerated:
          onRecommendationGenerated ?? this.onRecommendationGenerated,
      onRecommendationError:
          onRecommendationError ?? this.onRecommendationError,
      filterRecommendations:
          filterRecommendations ?? this.filterRecommendations,
      sortRecommendations: sortRecommendations ?? this.sortRecommendations,
      productCategoryMapper:
          productCategoryMapper ?? this.productCategoryMapper,
      priceRangeCalculator: priceRangeCalculator ?? this.priceRangeCalculator,
    );
  }
}
