import 'dart:async';

import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter/material.dart';

/// A callback function that determines whether an
/// item should be removed from the cart.
typedef RemoveCallBack<T> = bool Function(T item);

/// A reactive and extensible shopping cart that supports item grouping,
/// custom metadata, locking, expiration, and plugin extensions.
///
/// This class is designed for flexibility and use in state management
/// systems such as Provider, Riverpod, or GetX.
class FlexiCart<T extends ICartItem> extends ChangeNotifier
    with
        CartChangeNotifierDisposeMixin,
        CartStreamMixin<FlexiCart<T>>,
        CartPluginsMixin,
        CartHistoryMixin,
        CartLockMixin,
        CartMetadataMixin {
  /// Constructs a [FlexiCart] instance.
  ///
  /// - [items] is an optional initial map of items.
  /// - [groups] is an optional map of item groups.

  FlexiCart({
    Map<String, T>? items,
    Map<String, CartItemsGroup<T>>? groups,
    this.hooks,
    CartOptions? options,
  })  : _options = options ?? CartOptions(),
        _items = items ?? {},
        groups = groups ?? {},
        _createdAt = DateTime.now(),
        _lastActivity = DateTime.now() {
    final validatorOptions = _options.validatorOptions;

    if (validatorOptions.autoValidate) {
      // Automatically validate the cart if auto-validation is enabled
      _validateIfNeeded();
      addListener(_validateIfNeeded);
    }
    // Initialize session if options are provided
    _initializeSession();

    // Start session monitoring
    _startSessionMonitoring();
  }

  /// Class have Callbacks
  final CartHooks? hooks;

  /// Options for the cart, including validation and discount options.
  CartOptions _options;

  /// Returns the current options for the cart.
  CartOptions get options => _options;

  /// Internal storage for cart items.
  final Map<String, T> _items;

  /// Storage for item groups.
  Map<String, CartItemsGroup<T>> groups;

  /// Optional note for the cart (e.g., special instructions).
  String? _note;

  /// Delivery timestamp.
  DateTime? _deliveredAt;

  /// Expiration timestamp of the cart.
  DateTime? _expiresAt;

  /// Whether to allow items with quantity zero in the cart.
  bool addZeroQuantity = false;

  /// Currency if needed for the cart.
  CartCurrency? _cartCurrency;

  /// Internal logs of cart events.

  /// Returns all cart items as a map.
  Map<String, T> get items => _items;

  /// Returns all cart items as a list.
  List<T> get itemsList => _items.values.toList();

  /// Returns the note for the cart.
  String? get note => _note;

  /// Returns the delivery timestamp.
  DateTime? get deliveredAt => _deliveredAt;

  /// Returns true if the cart has expired.
  bool get isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Returns the CartCurrency.
  CartCurrency? get cartCurrency => _cartCurrency;

  // =============== VALIDATOR MANAGEMENT INTEGRATION ===============
  /// set promo code for the cart.
  void setPromoCode(
    String? code, {
    bool shouldNotifyListeners = true,
  }) =>
      _updateOptions(
        _options = _options.copyWith(
          validatorOptions: _options.validatorOptions.copyWith(
            promoCode: code,
          ),
        ),
        'Set promo code: $code',
        shouldNotifyListeners,
      );

  /// Returns the current promo code.
  String? get promoCode => _options.validatorOptions.promoCode;

  /// Sets a custom validator for the promo code.
  void setPromoCodeValidator(
    String? Function(String code)? promoCodeValidator, {
    bool shouldNotifyListeners = false,
  }) =>
      _updateOptions(
        _options = _options.copyWith(
          validatorOptions: _options.validatorOptions.copyWith(
            promoCodeValidator: promoCodeValidator,
          ),
        ),
        'Set promo code validator',
        shouldNotifyListeners,
      );

  /// [ValidatorOptions] is used to validate the cart state

  /// Returns true if the cart is locked.
  Map<String, dynamic> validate() {
    final validatorOptions = _options.validatorOptions;
    return validatorOptions.validate(this);
  }

  /// Returns true if the cart has any validators.
  bool get hasValidators => _options.validatorOptions.hasValidators;

  /// Returns the list of validators.
  List<ICartValidator> get validators {
    return _options.validatorOptions.validators;
  }

  /// add a validator to the validators.
  void addValidator(ICartValidator validator) {
    _options.validatorOptions.addValidator(validator);
    _validateIfNeeded();
  }

  /// Removes a validator from the list.
  void removeValidator(ICartValidator validator) {
    _options.validatorOptions.removeValidator(validator);
    _validateIfNeeded();
  }

  /// Adds multiple validators.
  void addValidators(List<ICartValidator> validators) {
    _options.validatorOptions.addValidators(validators);
    _validateIfNeeded();
  }

  /// Clears all validators.
  void clearValidators() {
    _options.validatorOptions.clearValidators();
    _validateIfNeeded();
  }

  /// Returns the current validation errors as a map.

  Map<String, dynamic> validationErrors = {};

  void _validateIfNeeded() {
    final errors = validate();
    validationErrors = errors;
    if (errors.isNotEmpty) {
      _log('Auto-validation errors: $errors');
    } else {
      _log('Auto-validation passed');
    }
  }

  /// sets custom validator options for the cart.
  void setValidatorOptions(
    ValidatorOptions validatorOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        validatorOptions: validatorOptions,
      ),
      'Set custom validator options',
      shouldNotifyListeners,
    );
  }

  // =============== END VALIDATOR MANAGEMENT INTEGRATION ===============

  /// Sets custom behavior options for the cart.
  void setBehaviorOptions(
    BehaviorOptions behaviorOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        behaviorOptions: behaviorOptions,
      ),
      'Set custom behavior options',
      shouldNotifyListeners,
    );
  }

  // =============== SESSION MANAGEMENT INTEGRATION ===============

  /// Session creation timestamp
  final DateTime _createdAt;

  /// Last activity timestamp
  DateTime _lastActivity;

  /// Session monitoring timer
  Timer? _sessionTimer;

  /// Whether session has been warned about expiration
  bool _hasBeenWarned = false;

  /// Session extension count for metrics
  int _sessionExtensions = 0;

  /// Total session duration for metrics
  Duration get _totalSessionDuration => DateTime.now().difference(_createdAt);

  /// Session ID - generated or custom
  String get sessionId =>
      _options.sessionOptions.sessionId ?? _generateSessionId();

  /// Returns session creation time
  DateTime get sessionCreatedAt => _createdAt;

  /// Returns last activity time
  DateTime get lastActivity => _lastActivity;

  /// Returns session extension count
  int get sessionExtensions => _sessionExtensions;

  /// Returns total session duration
  Duration get totalSessionDuration => _totalSessionDuration;

  /// Sets custom session options for the cart.
  void setSessionOptions(
    SessionOptions sessionOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        sessionOptions: sessionOptions,
      ),
      'Set custom session options',
      shouldNotifyListeners,
    );

    // Reinitialize session with new options
    _initializeSession();
    _restartSessionMonitoring();
  }

  /// Checks if the session has expired
  bool get isSessionExpired {
    final sessionOptions = _options.sessionOptions;

    return sessionOptions.isExpired(
      _createdAt,
      lastActivity: _lastActivity,
    );
  }

  /// Gets time remaining before session expires
  Duration? getSessionTimeRemaining() {
    final sessionOptions = _options.sessionOptions;

    return sessionOptions.getTimeRemaining(
      _createdAt,
      lastActivity: _lastActivity,
    );
  }

  /// Extends the session by updating last activity
  void extendSession({bool shouldNotifyListeners = false}) {
    final sessionOptions = _options.sessionOptions;

    _performCartOperation(
      operation: () {
        _lastActivity = DateTime.now();
        _sessionExtensions++;
        _hasBeenWarned = false; // Reset warning flag

        // Trigger extension callback
        final timeRemaining = getSessionTimeRemaining();
        if (timeRemaining != null) {
          sessionOptions.onSessionExtend?.call(timeRemaining);
        }
      },
      logMessage: 'Session extended - Extensions: $_sessionExtensions',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Manually expire the session
  void expireSession({bool shouldNotifyListeners = false}) {
    final sessionOptions = _options.sessionOptions;

    _performCartOperation(
      operation: () {
        // Set last activity to a time that would cause expiration
        if (sessionOptions.expiresIn != null) {
          _lastActivity = _createdAt.subtract(sessionOptions.expiresIn!);
        }

        _handleSessionExpiration();
      },
      logMessage: 'Session manually expired',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Gets session metrics as a map
  Map<String, dynamic> getSessionMetrics() {
    final sessionOptions = _options.sessionOptions;
    if (sessionOptions.enableSessionMetrics != true) {
      return {};
    }

    return {
      'sessionId': sessionId,
      'createdAt': _createdAt.toIso8601String(),
      'lastActivity': _lastActivity.toIso8601String(),
      'totalDuration': _totalSessionDuration.inSeconds,
      'extensions': _sessionExtensions,
      'isExpired': isSessionExpired,
      'timeRemaining': getSessionTimeRemaining()?.inSeconds,
      'customMetadata': sessionOptions.customMetadata,
    };
  }

  /// Initialize session when cart is created
  void _initializeSession() {
    final sessionOptions = _options.sessionOptions

      // Generate session ID if not provided
      ..sessionId ??= _generateSessionId();

    // Trigger session start callback
    sessionOptions.onSessionStart?.call(sessionId);

    _log('Session initialized - ID: $sessionId');
  }

  /// Start monitoring session expiration
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();

    // Check every 30 seconds
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkSessionStatus();
    });
  }

  /// Restart session monitoring with new options
  void _restartSessionMonitoring() {
    _sessionTimer?.cancel();
    _hasBeenWarned = false;
    _startSessionMonitoring();
  }

  /// Check session status and handle warnings/expiration
  void _checkSessionStatus() {
    final sessionOptions = _options.sessionOptions;

    if (isSessionExpired) {
      _handleSessionExpiration();
      return;
    }

    // Check for warning
    if (!_hasBeenWarned &&
        sessionOptions.shouldWarn(_createdAt, lastActivity: _lastActivity)) {
      final timeRemaining = getSessionTimeRemaining();
      if (timeRemaining != null) {
        sessionOptions.onSessionWarning?.call(timeRemaining);
        _hasBeenWarned = true;
        _log('Session warning triggered - Time remaining:'
            ' ${timeRemaining.inMinutes} minutes');
      }
    }
  }

  /// Handle session expiration
  void _handleSessionExpiration() {
    final sessionOptions = _options.sessionOptions;

    _sessionTimer?.cancel();

    _log(
      'Session expired - ID: $sessionId, Duration:'
      ' ${_totalSessionDuration.inMinutes} minutes',
    );

    // Trigger expiration callback
    sessionOptions.onSessionExpire?.call();

    // Optionally clear cart data
    // reset(shouldNotifyListeners: true);
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'cart_session_$random';
  }

  /// Update last activity timestamp (call this on user interactions)
  // void _updateActivity() {
  //   final sessionOptions = _options.sessionOptions;
  //   if (sessionOptions.autoExtendOnActivity == true) {
  //     extendSession();
  //   } else {
  //     _lastActivity = DateTime.now();
  //   }
  // }

// =============== END SESSION MANAGEMENT INTEGRATION ===============

// =============== SHIPPING OPTIONS INTEGRATION ===============
  /// Shipping Integration Features Added:
  ///
  /// Core Shipping Methods:
  /// - setShippingOptions() - Set complete shipping configuration
  /// - getShippingCost() - Calculate shipping cost
  /// - getSelectedShippingMethod() - Get currently selected method
  /// - selectShippingMethod() - Select a shipping method
  /// - addShippingMethod() - Add new shipping method
  /// - removeShippingMethod() - Remove shipping method
  ///
  /// Convenience Methods:
  /// - qualifiesForFreeShipping() - Check free shipping eligibility
  /// - getAmountNeededForFreeShipping() - Amount needed for free shipping
  /// - getFastestShippingMethod() - Get fastest delivery option
  /// - getCheapestShippingMethod() - Get cheapest shipping option
  /// - getShippingMethods() - Get all available methods
  ///
  /// Enhanced Total Calculations:
  /// - getTotalWithShipping() - Total price including shipping
  /// - getFinalTotalWithShipping() - Final total with tax, discount,
  /// and shipping

  /// Sets custom shipping options for the cart.
  void setShippingOptions(
    ShippingOptions shippingOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        shippingOptions: shippingOptions,
      ),
      'Set custom shipping options',
      shouldNotifyListeners,
    );
  }

  /// Returns the calculated shipping cost.
  double getShippingCost() => _options.shippingOptions.calculate(this);

  /// Returns the label used for shipping display.
  String get shippingLabel => _options.shippingOptions.shippingLabel;

  /// Returns the currently selected shipping method.
  ShippingMethod? getSelectedShippingMethod() =>
      _options.shippingOptions.selectedMethod;

  /// Returns the default shipping method.
  ShippingMethod? getDefaultShippingMethod() =>
      _options.shippingOptions.defaultMethod;

  /// Selects a shipping method by ID.
  bool selectShippingMethod(
    String methodId, {
    bool shouldNotifyListeners = false,
  }) {
    final success = _options.shippingOptions.selectMethod(methodId);
    if (success) {
      _updateOptions(
        _options,
        'Selected shipping method: $methodId',
        shouldNotifyListeners,
      );
    }
    return success;
  }

  /// Adds a new shipping method to available options.
  void addShippingMethod(
    ShippingMethod method, {
    bool shouldNotifyListeners = false,
  }) {
    _performCartOperation(
      operation: () {
        _options.shippingOptions.addMethod(method);
      },
      logMessage: 'Added shipping method: ${method.name} (${method.id})',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Removes a shipping method by ID.
  bool removeShippingMethod(
    String methodId, {
    bool shouldNotifyListeners = false,
  }) {
    var removed = false;
    _performCartOperation(
      operation: () {
        removed = _options.shippingOptions.removeMethod(methodId);
      },
      logMessage: 'Removed shipping method: $methodId',
      shouldNotifyListeners: shouldNotifyListeners,
    );
    return removed;
  }

  /// Returns all available shipping methods.
  List<ShippingMethod> getShippingMethods() =>
      _options.shippingOptions.availableMethods ?? [];

  /// Returns shipping methods sorted by cost (cheapest first).
  List<ShippingMethod> getShippingMethodsSortedByCost() =>
      _options.shippingOptions.getMethodsSortedByCost();

  /// Returns shipping methods sorted by delivery speed (fastest first).
  List<ShippingMethod> getShippingMethodsSortedBySpeed() =>
      _options.shippingOptions.getMethodsSortedBySpeed();

  /// Returns the fastest available shipping method.
  ShippingMethod? getFastestShippingMethod() =>
      _options.shippingOptions.getFastestMethod();

  /// Returns the cheapest available shipping method.
  ShippingMethod? getCheapestShippingMethod() =>
      _options.shippingOptions.getCheapestMethod();

  /// Checks if the cart qualifies for free shipping.
  bool qualifiesForFreeShipping() =>
      _options.shippingOptions.qualifiesForFreeShipping(this);

  /// Returns the amount needed to qualify for free shipping.
  double getAmountNeededForFreeShipping() =>
      _options.shippingOptions.amountNeededForFreeShipping(this);

  /// Returns the free shipping promotional message.
  String getFreeShippingMessage() =>
      _options.shippingOptions.getFreeShippingMessage();

  /// Sets the free shipping threshold.
  void setFreeShippingThreshold(
    double? threshold, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        shippingOptions: _options.shippingOptions.copyWith(
          freeShippingThreshold: threshold,
        ),
      ),
      'Set free shipping threshold: $threshold',
      shouldNotifyListeners,
    );
  }

  /// Returns the current free shipping threshold.
  double? get freeShippingThreshold =>
      _options.shippingOptions.freeShippingThreshold;

  /// Sets a custom shipping cost calculator.
  void setShippingCostCalculator(
    double Function(FlexiCart cart, ShippingMethod? method)? calculator, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        shippingOptions: _options.shippingOptions.copyWith(
          shippingCostCalculator: calculator,
        ),
      ),
      'Set custom shipping cost calculator',
      shouldNotifyListeners,
    );
  }

  /// Returns the total price including shipping.
  double getTotalWithShipping() {
    final baseTotal = totalPrice();
    final shippingCost = getShippingCost();
    return baseTotal + shippingCost;
  }

  /// Returns the final total including tax, discount, and shipping.
  double getFinalTotalWithShipping() {
    final baseTotal = totalPrice();
    final discountAmount = discount();
    final tax = getTotalTax();
    final shippingCost = getShippingCost();

    if (_options.taxOptions.includeTaxInTotal) {
      return baseTotal - discountAmount + tax + shippingCost;
    }
    return baseTotal - discountAmount + shippingCost;
  }

  /// Validates the shipping configuration and returns any errors.
  List<String> validateShippingOptions() => _options.shippingOptions.validate();

// =============== END SHIPPING OPTIONS INTEGRATION ===============

  // =============== TAX OPTIONS INTEGRATION ===============
  /// Tax Integration Features Added:
  ///
  /// Core Tax Methods:
  ///
  /// setTaxOptions() - Set complete tax configuration
  /// getTotalTax() - Calculate total tax
  /// getAllTaxes() - Get all taxes as a map (for multi-tax scenarios)
  /// getFormattedTax() - Get formatted tax display
  ///
  ///
  /// Convenience Methods:
  ///
  /// setTaxRate() - Set simple tax rate
  /// setTaxCalculator() - Set custom tax calculation function
  /// setTaxRegion() - Set tax region
  /// setIncludeTaxInTotal() - Configure if tax is included in total
  /// setTaxExemption() - Set tax exemption logic
  ///
  ///
  /// Getters:
  ///
  /// taxLabel - Get tax display label
  /// taxRegion - Get current tax region
  /// includeTaxInTotal - Check if tax is included in total
  /// isTaxExempt - Check if cart is tax exempt
  ///
  ///
  /// Enhanced Total Calculations:
  ///
  /// getTotalWithTax() - Total price including tax (when configured)
  /// getFinalTotal() - Final total

  /// Sets custom tax options for the cart.
  void setTaxOptions(
    TaxOptions taxOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: taxOptions,
      ),
      'Set custom tax options',
      shouldNotifyListeners,
    );
  }

  /// Returns the total tax using the configured tax options.
  double getTotalTax() => _options.taxOptions.calculate(this);

  /// Returns all calculated taxes as a map (for multi-tax scenarios).
  Map<String, double> getAllTaxes() => _options.taxOptions.calculateAll(this);

  /// Returns the formatted tax amount.
  String getFormattedTax() => _options.taxOptions.formatTax(getTotalTax());

  /// Returns the label used for tax display.
  String get taxLabel => _options.taxOptions.taxLabel;

  /// Sets a simple tax rate for the cart.
  void setTaxRate(
    double taxRate, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: _options.taxOptions.copyWith(
          taxRate: taxRate,
        ),
      ),
      'Set tax rate: $taxRate',
      shouldNotifyListeners,
    );
  }

  /// Sets a custom tax calculator function.
  void setTaxCalculator(
    double Function(FlexiCart cart) taxCalculator, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: _options.taxOptions.copyWith(
          taxCalculator: taxCalculator,
        ),
      ),
      'Set custom tax calculator',
      shouldNotifyListeners,
    );
  }

  /// Sets the tax region for the cart.
  void setTaxRegion(
    String? taxRegion, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: _options.taxOptions.copyWith(
          taxRegion: taxRegion,
        ),
      ),
      'Set tax region: $taxRegion',
      shouldNotifyListeners,
    );
  }

  /// Returns the current tax region.
  String? get taxRegion => _options.taxOptions.taxRegion;

  /// Sets whether tax should be included in the total.
  void setIncludeTaxInTotal({
    bool includeTaxInTotal = false,
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: _options.taxOptions.copyWith(
          includeTaxInTotal: includeTaxInTotal,
        ),
      ),
      'Set include tax in total: $includeTaxInTotal',
      shouldNotifyListeners,
    );
  }

  /// Returns whether tax is included in the total.
  bool get includeTaxInTotal => _options.taxOptions.includeTaxInTotal;

  /// Sets a tax exemption function.
  void setTaxExemption(
    bool Function(FlexiCart cart)? isExempt, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        taxOptions: _options.taxOptions.copyWith(
          isExempt: isExempt,
        ),
      ),
      'Set tax exemption function',
      shouldNotifyListeners,
    );
  }

  /// Returns true if the cart is tax exempt.
  bool get isTaxExempt => _options.taxOptions.isExempt?.call(this) ?? false;

  /// Returns the total price including tax (if tax should be included).
  double getTotalWithTax() {
    final baseTotal = totalPrice();
    final tax = getTotalTax();

    if (_options.taxOptions.includeTaxInTotal) {
      return baseTotal + tax;
    }
    return baseTotal;
  }

  // =============== END TAX OPTIONS INTEGRATION ===============
  // flexi_cart_recommendations.dart

  // =============== RECOMMENDATION OPTIONS INTEGRATION ===============
  /// Recommendation Integration Features Added:
  ///
  /// Core Recommendation Methods:
  /// - setRecommendationOptions() - Set complete recommendation configuration
  /// - getRecommendations() - Get recommended products
  /// - clearRecommendationCache() - Clear cached recommendations
  /// - getRecommendationStats() - Get cache statistics
  ///
  /// Configuration Methods:
  /// - setMaxRecommendations() - Set maximum number of recommendations
  /// - setMinCartValue() - Set minimum cart value for recommendations
  /// - setRecommendationStrategies() - Set recommendation strategies
  /// - enableRecommendationCaching() - Enable/disable caching
  ///
  /// Custom Strategy Methods:
  /// - setCustomRecommendationFunction() - Set custom recommendation logic
  /// - setProductCategoryMapper() - Set category mapping function
  /// - setPriceRangeCalculator() - Set price calculation function
  ///
  /// Callback Methods:
  /// - setRecommendationCallbacks() - Set success/error callbacks

  /// Sets custom recommendation options for the cart.
  // void setRecommendationOptions(
  //   RecommendationOptions recommendationOptions, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   _updateOptions(
  //     options.copyWith(
  //       recommendationOptions: recommendationOptions,
  //     ),
  //     'Set custom recommendation options',
  //     shouldNotifyListeners,
  //   );
  // }
  //
  // /// Returns the current recommendation options.
  // RecommendationOptions get recommendationOptions =>
  //     options.recommendationOptions;
  //
  // /// Generates recommendations based on current cart contents.
  // List<T> getRecommendations() {
  //   final recOptions = recommendationOptions;
  //
  //   try {
  //     final recommendations = recOptions.recommend(this as FlexiCart);
  //     return recommendations.cast<T>();
  //   } catch (e) {
  //     debugPrint('Error generating recommendations: $e');
  //     return [];
  //   }
  // }
  //
  // /// Sets the maximum number of recommendations to return.
  // void setMaxRecommendations(
  //   int maxRecommendations, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config.copyWith(
  //         maxRecommendations: maxRecommendations,
  //       ),
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets the minimum cart value required for recommendations.
  // void setMinCartValueForRecommendations(
  //   double minCartValue, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config.copyWith(
  //         minCartValue: minCartValue,
  //       ),
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets the recommendation strategies to use.
  // void setRecommendationStrategies(
  //   List<RecommendationStrategy> strategies, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config.copyWith(
  //         strategies: strategies,
  //       ),
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Enables or disables recommendation caching.
  // void enableRecommendationCaching(
  //   bool enabled, {
  //   int? cacheExpirationMinutes,
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config.copyWith(
  //         enableCaching: enabled,
  //         cacheExpirationMinutes: cacheExpirationMinutes ??
  //             currentOptions.config.cacheExpirationMinutes,
  //       ),
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets a custom recommendation function.
  // void setCustomRecommendationFunction(
  //   List<ICartItem> Function(FlexiCart cart) suggestProducts, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config,
  //       suggestProducts: suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets a product category mapper function.
  // void setProductCategoryMapper(
  //   String Function(ICartItem product) categoryMapper, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config,
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: categoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets a price range calculator function.
  // void setPriceRangeCalculator(
  //   double Function(ICartItem cartItem) priceCalculator, {
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config,
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: priceCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets recommendation callbacks for success and error handling.
  // void setRecommendationCallbacks({
  //   void Function(FlexiCart cart, List<ICartItem> recommendations)? onGenerated,
  //   void Function(FlexiCart cart, Object error)? onError,
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config,
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: onGenerated,
  //       onRecommendationError: onError,
  //       filterRecommendations: currentOptions.filterRecommendations,
  //       sortRecommendations: currentOptions.sortRecommendations,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Sets recommendation filter and sort functions.
  // void setRecommendationFilters({
  //   bool Function(ICartItem product, FlexiCart cart)? filter,
  //   int Function(ICartItem a, ICartItem b)? sort,
  //   bool shouldNotifyListeners = false,
  // }) {
  //   final currentOptions = recommendationOptions;
  //   setRecommendationOptions(
  //     RecommendationOptions(
  //       config: currentOptions.config,
  //       suggestProducts: currentOptions.suggestProducts,
  //       onRecommendationGenerated: currentOptions.onRecommendationGenerated,
  //       onRecommendationError: currentOptions.onRecommendationError,
  //       filterRecommendations: filter,
  //       sortRecommendations: sort,
  //       productCategoryMapper: currentOptions.productCategoryMapper,
  //       priceRangeCalculator: currentOptions.priceRangeCalculator,
  //     ),
  //     shouldNotifyListeners: shouldNotifyListeners,
  //   );
  // }
  //
  // /// Clears the recommendation cache.
  // void clearRecommendationCache() {
  //   recommendationOptions.clearCache();
  // }
  //
  // /// Returns recommendation cache statistics.
  // Map<String, dynamic> getRecommendationCacheStats() {
  //   return recommendationOptions.getCacheStats();
  // }
  //
  // /// Checks if recommendations are available for the current cart.
  // bool hasRecommendations() {
  //   return getRecommendations().isNotEmpty;
  // }
  //
  // /// Gets the count of available recommendations.
  // int getRecommendationCount() {
  //   return getRecommendations().length;
  // }
  //
  // /// Checks if the cart meets the minimum value for recommendations.
  // bool meetsMinimumValueForRecommendations() {
  //   return totalPrice() >= recommendationOptions.config.minCartValue;
  // }
  //
  // /// Gets recommendations filtered by a specific strategy.
  // List<T> getRecommendationsByStrategy(RecommendationStrategy strategy) {
  //   final currentStrategies = recommendationOptions.config.strategies;
  //
  //   // Temporarily set single strategy
  //   setRecommendationStrategies([strategy], shouldNotifyListeners: false);
  //
  //   final recommendations = getRecommendations();
  //
  //   // Restore original strategies
  //   setRecommendationStrategies(currentStrategies,
  //       shouldNotifyListeners: false);
  //
  //   return recommendations;
  // }

// =============== END RECOMMENDATION OPTIONS INTEGRATION ===============

  /// Updates the cart options and logs the change.
  void setDiscountOptions(
    DiscountOptions discountOptions, {
    bool shouldNotifyListeners = false,
  }) {
    _updateOptions(
      _options = _options.copyWith(
        discountOptions: discountOptions,
      ),
      'Set custom discount options',
      shouldNotifyListeners,
    );
  }

  /// discountOptions is used to calculate the discount for the cart.
  double discount() {
    return _options.discountOptions.calculate(this);
  }

  /// Returns the label used for the discount.
  String get discountLabel => _options.discountOptions.discountLabel;

  /// Returns the total price minus any discounts.
  double getTotalAfterDiscount() => totalPrice() - discount();

  /// Returns the final total including tax and discounts.
  double getFinalTotal() {
    final baseTotal = totalPrice();
    final discountAmount = discount();
    final tax = getTotalTax();

    if (_options.taxOptions.includeTaxInTotal) {
      return baseTotal - discountAmount + tax;
    }
    return baseTotal - discountAmount;
  }

  /// Sets the cart to expire after the given duration from now.
  void setExpiration(Duration duration, {bool shouldNotifyListeners = false}) {
    _performCartOperation(
      operation: () {
        _expiresAt = DateTime.now().add(duration);
      },
      logMessage: ' Set expiration to: ${DateTime.now().add(duration)}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Throws an exception if the cart is locked.
  void _checkLock() {
    if (isLocked) {
      final error = CartLockedException();
      _notifyOnErrorPlugins(error, StackTrace.current);
      throw error;
    }
  }

  /// Logs a message with a timestamp.
  void _log(String message, {bool notified = false}) {
    addHistory('$message - {notified: $notified}');
    final behaviorOptions = _options.behaviorOptions;
    if (behaviorOptions.enableLogging) {
      behaviorOptions.logger?.call(message);
    }
  }

  /// Notifies all registered plugins about a cart change.
  void _notifyOnChangedPlugins() {
    for (final plugin in plugins) {
      try {
        plugin.onChange(this);
      } on Exception catch (e, s) {
        debugPrint('Plugin onChange error: $e\n$s');
      }
    }
  }

  /// Notifies all registered plugins about a cart error.
  void _notifyOnErrorPlugins(Object error, StackTrace stackTrace) {
    for (final plugin in plugins) {
      plugin.onError(this, error, stackTrace);
    }
  }

  /// Throws an exception if the cart is disposed.
  void _checkDisposed() {
    checkIfDisposed(
      (exception) {
        _notifyOnErrorPlugins(exception, StackTrace.current);
      },
    );
  }

  /// Notifies all registered plugins about a cart close.
  void _notifyOnClosePlugins() {
    for (final plugin in plugins) {
      plugin.onClose(this);
    }
  }

  /// Sets a note for the cart.
  void setNote(String? note, {bool shouldNotifyListeners = false}) {
    _performCartOperation(
      operation: () {
        _note = note;
      },
      logMessage: 'Set Note with: $note',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Sets the delivery timestamp.
  void setDeliveredAt(
    DateTime? deliveredAt, {
    bool shouldNotifyListeners = false,
  }) {
    _performCartOperation(
      operation: () {
        _deliveredAt = deliveredAt;
      },
      logMessage: 'Set Delivered at: $deliveredAt',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Calculates the total price of items in the cart.
  double totalPrice() =>
      itemsList.fold(0, (sum, item) => sum + item.totalPrice());

  /// Calculates the total quantity of all items.
  double totalQuantity() =>
      itemsList.fold(0, (sum, item) => sum + item.notNullQty());

  /// Checks if any item in the cart has a very high quantity.
  bool get checkForLargeValue => itemsList.any((e) => e.notNullQty() >= 100);

  /// Returns true if the cart has any items.
  bool isNotEmpty() => _items.isNotEmpty;

  /// Returns true if the cart is empty.
  bool isEmpty() => _items.isEmpty;

  /// Adds a single item to the cart.
  ///
  /// If [increment] is true and the item already exists, quantity is added.
  void add(
    T item, {
    bool increment = false,
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        _add(item, increment);
      },
      logMessage: 'Item added: ${item.key}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Adds multiple items to the cart.
  ///
  /// - [increment] adds quantities if item already exists.
  /// - [skipIfExist] skips items already in the cart.
  /// - [shouldNotifyListeners] determines if [notifyListeners] is called.
  void addItems(
    List<T> items, {
    bool increment = false,
    bool skipIfExist = false,
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        for (final item in items) {
          if (skipIfExist && _items.containsKey(item.key)) {
            continue;
          }
          _add(item, increment);
        }
      },
      logMessage: 'Items have been added: $items',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Removes all items not included in the provided list.
  void removeItemsNotInList(
    List<T> items, {
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        final keepKeys = items.map((e) => e.key).toSet();
        for (final item in itemsList) {
          if (!keepKeys.contains(item.key)) {
            _delete(item);
          }
        }
      },
      logMessage: 'Items have been removed: $items',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Deletes a single item from the cart.
  void delete(T item, {bool shouldNotifyListeners = true}) {
    _performCartOperation(
      operation: () {
        _delete(item);
      },
      logMessage: 'Item has been removed: ${item.key}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Clears all items from the cart without affecting metadata.
  void resetItems({bool shouldNotifyListeners = true}) {
    _performCartOperation(
      operation: () {
        groups.clear();
        _items.clear();
      },
      logMessage: 'Items have been reset: $itemsList',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Fully resets the cart and its metadata.
  void reset({bool shouldNotifyListeners = true}) {
    _checkDisposed();

    try {
      groups.clear();
      _items.clear();
      _note = null;
      _deliveredAt = null;
      _expiresAt = null;
      addZeroQuantity = false;
      clearAllMetadata();
      resetLock();
      clearHistory();
      _cartCurrency = null;

      emit(this);
      if (shouldNotifyListeners) {
        notifyListeners();
      }
    } catch (error, stackTrace) {
      _notifyOnErrorPlugins(error, stackTrace);
      rethrow;
    }
  }

  /// Clears a specific item group by ID.
  void clearItemsGroup(String groupId, {bool shouldNotifyListeners = true}) {
    _checkDisposed();
    _checkLock();

    _performCartOperation(
      operation: () {
        groups.remove(groupId);
        _items.removeWhere((_, item) => item.group == groupId);
      },
      logMessage: 'Group has been removed from the cart: $groupId',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Returns true if the given group is empty.
  bool isItemsGroupEmpty(String groupId) => getItemsGroup(groupId).isEmpty;

  /// Returns true if the given group is not empty.
  bool isNotItemsGroupEmpty(String groupId) =>
      getItemsGroup(groupId).isNotEmpty;

  /// Gets the list of items for a specific group.
  List<T> getItemsGroup(String groupId) =>
      groups[groupId]?.items.values.toList() ?? [];

  /// Returns the count of items in a specific group.
  int getItemsGroupLength(String groupId) => getItemsGroup(groupId).length;

  /// Returns a clone of the cart with copied items and metadata.
  FlexiCart<T> clone() {
    _checkDisposed();

    return FlexiCart<T>(
      items: Map<String, T>.from(_items),
      groups: Map<String, CartItemsGroup<T>>.from(groups),
    )
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      ..addMetadataEntries(metadata)
      .._cartCurrency = _cartCurrency
      .._deliveredAt = _deliveredAt;
  }

  /// Casts the cart to a different item type [G].
  FlexiCart<G> cast<G extends ICartItem>() {
    return FlexiCart<G>(
      items: _items.cast<String, G>(),
      groups: groups.map((k, v) => MapEntry(k, v.cast<G>())),
    )
      ..addZeroQuantity = addZeroQuantity
      .._note = _note
      ..addMetadataEntries(metadata)
      .._cartCurrency = _cartCurrency
      .._deliveredAt = _deliveredAt;
  }

  /// Applies an exchange rate to all items based on the target currency.
  void applyExchangeRate(
    CartCurrency cartCurrency, {
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        if (cartCurrency == _cartCurrency) {
          return;
        }
        removeExchangeRate();

        _cartCurrency = cartCurrency;
        final rate = cartCurrency.rate;

        _items.forEach((key, item) {
          item.price *= rate;

          // Update item in group if necessary
          final groupId = item.group;
          if (groups[groupId]?.items != null) {
            groups[groupId]!.items[key] = item;
          }
        });
      },
      logMessage: 'Applied exchange rate for ${cartCurrency.code}:'
          ' ${cartCurrency.rate}',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Removes the applied exchange rate and reverts item prices.
  void removeExchangeRate({
    bool shouldNotifyListeners = true,
  }) {
    _performCartOperation(
      operation: () {
        if (_cartCurrency == null) {
          return;
        }

        final rate = _cartCurrency!.rate;

        _items.forEach((key, item) {
          item.price /= rate;

          // Update item in group if necessary
          final groupId = item.group;
          if (groups[groupId]?.items != null) {
            groups[groupId]!.items[key] = item;
          }
        });

        _cartCurrency = null;
      },
      logMessage: 'Removed exchange rate',
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Disposes of the cart and triggers [dispose].
  @override
  void dispose() {
    super.dispose();
    _notifyOnClosePlugins();
    _log('Cart has been disposed');
    _sessionTimer?.cancel();
    hooks?.onDisposed?.call();
    disposeStream(); // call this if using the mixin's stream
  }

  /// Internal method to add an item and notify plugins.
  void _add(T item, bool increment) {
    final behaviorOptions = _options.behaviorOptions;

    /// Apply BehaviorOptions filters before proceeding
    if (!behaviorOptions.canAdd(item) && !items.containsKey(item.key)) {
      behaviorOptions.log('Add blocked by behavior options: ${item.key}');
      return;
    }

    final shouldDeleteZeroQty = !addZeroQuantity && item.quantity == 0;
    final shouldRemoveItem = !behaviorOptions.canAdd(item);

    if (shouldRemoveItem || item.quantity == null || shouldDeleteZeroQty) {
      _delete(item);
      return;
    }

    hooks?.onItemAdded?.call(item);

    /// Override item price if resolver is provided on add only
    if (behaviorOptions.priceResolver != null &&
        !_items.containsKey(item.key)) {
      final resolvedPrice = behaviorOptions.resolvePrice(item);
      behaviorOptions.log('Resolved price for ${item.key}: $resolvedPrice');
      item.price = resolvedPrice;
    }
    _addToItems(item, increment: increment);
    _addToGroup(item);
    _notifyOnChangedPlugins();
  }

  /// Adds an item to the item map.
  void _addToItems(T item, {bool increment = false}) {
    final key = item.key;
    if (increment && _items.containsKey(key)) {
      _items[key] = item
        ..quantity = item.notNullQty() + _items[key]!.notNullQty();
    } else {
      _items[key] = item;
    }
  }

  /// Adds an item to the appropriate group.
  void _addToGroup(T item) {
    groups.putIfAbsent(
      item.group,
      () => CartItemsGroup<T>(
        id: item.group,
        name: item.groupName,
      ),
    );
    groups[item.group]!.add(item);
  }

  /// Deletes an item from the item map and group.
  void _delete(T item) {
    _items.remove(item.key);
    _deleteFromGroup(item);
    hooks?.onItemDeleted?.call(item);
    _notifyOnChangedPlugins();
  }

  /// Removes an item from its group.
  void _deleteFromGroup(T item) {
    final group = groups[item.group];
    if (group != null) {
      group.remove(item);
      if (group.items.isEmpty) {
        groups.remove(item.group);
      }
    }
  }

  /// --- Private Helpers ---

  void _updateOptions(
    CartOptions newOptions,
    String logMessage,
    bool shouldNotifyListeners,
  ) {
    _performCartOperation(
      operation: () {
        _options = newOptions;
        _validateIfNeeded();
      },
      logMessage: logMessage,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Performs a cart operation with proper error handling and notifications.
  void _performCartOperation({
    required VoidCallback operation,
    required String logMessage,
    required bool shouldNotifyListeners,
  }) {
    _checkDisposed();
    _checkLock();

    operation();
    emit(this);
    _log(logMessage, notified: shouldNotifyListeners);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}
