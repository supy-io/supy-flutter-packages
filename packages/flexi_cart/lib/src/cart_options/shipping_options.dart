// part of 'cart_options.dart';
//
// /// Represents a shipping method with its properties
// class ShippingMethod {
//   /// Creates a new [ShippingMethod] with required and optional parameters.
//   const ShippingMethod({
//     required this.id,
//     required this.name,
//     this.description = '',
//     this.baseCost = 0.0,
//     this.estimatedDays = 0,
//     this.isDefault = false,
//   });
//
//   /// Unique identifier for the shipping method.
//   final String id;
//
//   /// Name of the shipping method (e.g., "Standard", "Express").
//   final String name;
//
//   /// Optional description of the shipping method.
//   final String description;
//
//   /// Base cost of the shipping method.
//   final double baseCost;
//
//   /// Estimated delivery time in days.
//   final int estimatedDays;
//
//   /// Whether this method is marked as the default option.
//   final bool isDefault;
//
//   /// Returns a string representation of the shipping method.
//   ShippingMethod copyWith({
//     String? id,
//     String? name,
//     String? description,
//     double? baseCost,
//     int? estimatedDays,
//     bool? isDefault,
//   }) {
//     return ShippingMethod(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       baseCost: baseCost ?? this.baseCost,
//       estimatedDays: estimatedDays ?? this.estimatedDays,
//       isDefault: isDefault ?? this.isDefault,
//     );
//   }
//
//   /// Returns a string representation of the shipping method.
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is ShippingMethod &&
//           runtimeType == other.runtimeType &&
//           id == other.id;
//
//   @override
//   int get hashCode => id.hashCode;
// }
//
// /// Defines shipping-related calculations and available methods.
// class ShippingOptions {
//   /// Creates a set of options for configuring
//   /// shipping behavior in a [FlexiCart].
//   ShippingOptions({
//     this.shippingCostCalculator,
//     this.shippingLabel = 'Shipping',
//     this.availableMethods,
//     this.selectedMethodId,
//     this.freeShippingThreshold,
//     this.freeShippingMessage = 'Free shipping on orders over',
//     this.allowMethodSelection = true,
//     this.defaultToFastest = false,
//   });
//
//   /// Function to calculate the total shipping cost.
//   double Function(FlexiCart cart, ShippingMethod? method)?
//       shippingCostCalculator;
//
//   /// Label to display for shipping charges.
//   String shippingLabel;
//
//   /// Optional list of available shipping methods.
//   List<ShippingMethod>? availableMethods;
//
//   /// Currently selected shipping method ID.
//   String? selectedMethodId;
//
//   /// Minimum order amount for free shipping.
//   double? freeShippingThreshold;
//
//   /// Message to display for free shipping promotion.
//   String freeShippingMessage;
//
//   /// Whether users can select different shipping methods.
//   bool allowMethodSelection;
//
//   /// Whether to default to the fastest shipping method.
//   bool defaultToFastest;
//
//   /// Gets the currently selected shipping method.
//   ShippingMethod? get selectedMethod {
//     if (availableMethods == null || selectedMethodId == null) return null;
//
//     return availableMethods!.firstWhereOrNull(
//           (method) => method.id == selectedMethodId,
//         ) ??
//         availableMethods?.firstOrNull;
//   }
//
//   /// Gets the default shipping method.
//   ShippingMethod? get defaultMethod {
//     if (availableMethods == null || availableMethods!.isEmpty) return null;
//
//     // First try to find explicitly marked default
//     try {
//       return availableMethods!.firstWhere((method) => method.isDefault);
//     } catch (e) {
//       // If no default marked, use fastest or first method
//       if (defaultToFastest) {
//         return getFastestMethod();
//       }
//       return availableMethods!.first;
//     }
//   }
//
//   /// Gets the fastest shipping method (lowest estimated days).
//   ShippingMethod? getFastestMethod() {
//     if (availableMethods == null || availableMethods!.isEmpty) return null;
//
//     return availableMethods!.reduce(
//       (current, next) =>
//           current.estimatedDays < next.estimatedDays ? current : next,
//     );
//   }
//
//   /// Gets the cheapest shipping method (lowest base cost).
//   ShippingMethod? getCheapestMethod() {
//     if (availableMethods == null || availableMethods!.isEmpty) return null;
//
//     return availableMethods!.reduce(
//         (current, next) =>
//         current.baseCost < next.baseCost ? current : next,);
//   }
//
//   /// Checks if the cart qualifies for free shipping.
//   bool qualifiesForFreeShipping(FlexiCart cart) {
//     if (freeShippingThreshold == null) return false;
//     return cart.totalPrice() >= freeShippingThreshold!;
//   }
//
//   /// Gets the amount needed to qualify for free shipping.
//   double amountNeededForFreeShipping(FlexiCart cart) {
//     if (freeShippingThreshold == null) return 0;
//     final needed = freeShippingThreshold! - cart.totalPrice();
//     return needed > 0 ? needed : 0.0;
//   }
//
//   /// Selects a shipping method by ID.
//   bool selectMethod(String methodId) {
//     if (availableMethods == null || !allowMethodSelection) return false;
//
//     final methodExists =
//         availableMethods!.any((method) => method.id == methodId);
//     if (methodExists) {
//       selectedMethodId = methodId;
//       return true;
//     }
//     return false;
//   }
//
//   /// Adds a new shipping method.
//   void addMethod(ShippingMethod method) {
//     availableMethods ??= [];
//
//     // Remove existing method with same ID
//     availableMethods!.removeWhere((m) => m.id == method.id);
//
//     // Add new method
//     availableMethods!.add(method);
//
//     // Auto-select if it's the first method or marked as default
//     if (selectedMethodId == null || method.isDefault) {
//       selectedMethodId = method.id;
//     }
//   }
//
//   /// Removes a shipping method by ID.
//   /// Removes a shipping method by ID and updates selection if needed.
//   bool removeMethod(String methodId) {
//     if (availableMethods == null || availableMethods!.isEmpty) return false;
//
//     final initialLength = availableMethods!.length;
//     availableMethods!.removeWhere((method) => method.id == methodId);
//     final removed = initialLength != availableMethods!.length;
//
//     if (removed && selectedMethodId == methodId) {
//       selectedMethodId = defaultMethod?.id;
//     }
//
//     return removed;
//   }
//
//   /// Gets available method names for display.
//   List<String> get methodNames {
//     return availableMethods?.map((method) => method.name).toList() ?? [];
//   }
//
//   /// Gets methods sorted by cost (ascending).
//   List<ShippingMethod> getMethodsSortedByCost() {
//     if (availableMethods == null) return [];
//
//     final methods = List<ShippingMethod>.from(availableMethods!)
//       ..sort((a, b) => a.baseCost.compareTo(b.baseCost));
//     return methods;
//   }
//
//   /// Gets methods sorted by delivery time (ascending).
//   List<ShippingMethod> getMethodsSortedBySpeed() {
//     if (availableMethods == null) return [];
//
//     final methods = List<ShippingMethod>.from(availableMethods!)
//       ..sort((a, b) => a.estimatedDays.compareTo(b.estimatedDays));
//     return methods;
//   }
//
//   /// Computes the shipping cost or returns 0.0 if not defined.
//   double calculate(FlexiCart cart) {
//     // Check for free shipping first
//     if (qualifiesForFreeShipping(cart)) return 0;
//
//     final method = selectedMethod ?? defaultMethod;
//
//     if (shippingCostCalculator != null) {
//       return shippingCostCalculator!(cart, method);
//     }
//
//     // Fallback to method's base cost
//     return method?.baseCost ?? 0.0;
//   }
//
//   /// Gets a formatted string for free shipping promotion.
//   String getFreeShippingMessage() {
//     if (freeShippingThreshold == null) return '';
//     return '$freeShippingMessage \$${freeShippingThreshold!.toStringAsFixed(2)}';
//   }
//
//   /// Validates the shipping configuration.
//   List<String> validate() {
//     final errors = <String>[];
//
//     if (availableMethods != null && availableMethods!.isNotEmpty) {
//       // Check for duplicate IDs
//       final ids = availableMethods!.map((m) => m.id).toList();
//       final uniqueIds = ids.toSet();
//       if (ids.length != uniqueIds.length) {
//         errors.add('Duplicate shipping method IDs found');
//       }
//
//       // Check if selected method exists
//       if (selectedMethodId != null &&
//           !availableMethods!.any((m) => m.id == selectedMethodId)) {
//         errors.add('Selected shipping method does not exist');
//       }
//     }
//
//     if (freeShippingThreshold != null && freeShippingThreshold! < 0) {
//       errors.add('Free shipping threshold cannot be negative');
//     }
//
//     return errors;
//   }
//
//   /// Creates a copy of this [ShippingOptions] with updated values.
//   ShippingOptions copyWith({
//     double Function(FlexiCart cart, ShippingMethod? method)?
//         shippingCostCalculator,
//     String? shippingLabel,
//     List<ShippingMethod>? availableMethods,
//     String? selectedMethodId,
//     double? freeShippingThreshold,
//     String? freeShippingMessage,
//     bool? allowMethodSelection,
//     bool? defaultToFastest,
//   }) {
//     return ShippingOptions(
//       shippingCostCalculator:
//           shippingCostCalculator ?? this.shippingCostCalculator,
//       shippingLabel: shippingLabel ?? this.shippingLabel,
//       availableMethods: availableMethods ?? this.availableMethods,
//       selectedMethodId: selectedMethodId ?? this.selectedMethodId,
//       freeShippingThreshold:
//           freeShippingThreshold ?? this.freeShippingThreshold,
//       freeShippingMessage: freeShippingMessage ?? this.freeShippingMessage,
//       allowMethodSelection: allowMethodSelection ??
//       this.allowMethodSelection,
//       defaultToFastest: defaultToFastest ?? this.defaultToFastest,
//     );
//   }
//
//   @override
//   String toString() {
//     return
//     'ShippingOptions(methods: ${availableMethods?.length ?? 0}, '
//         'selected: $selectedMethodId,
//         freeThreshold: $freeShippingThreshold)';
//   }
// }
