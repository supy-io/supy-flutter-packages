import 'package:flexi_cart/flexi_cart.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock cart item for testing
class MockCartItem extends ICartItem {
  MockCartItem({
    required super.id,
    required super.name,
    required super.price,
    double? quantity,
    String? group,
  }) : super(
          quantity: quantity ?? 1.0,
          group: group ?? 'default',
        );
}

void main() {
  group('TaxOptions Tests', () {
    late FlexiCart<MockCartItem> cart;
    late MockCartItem item1;
    late MockCartItem item2;

    setUp(() {
      cart = FlexiCart<MockCartItem>();
      item1 = MockCartItem(
        id: '1',
        name: 'Item 1',
        price: 100,
        quantity: 2,
      );
      item2 = MockCartItem(
        id: '2',
        name: 'Item 2',
        price: 50,
        quantity: 1,
      );
      cart
        ..add(item1)
        ..add(item2);
      // Cart total: (100 * 2) + (50 * 1) = 250
    });

    group('Constructor Tests', () {
      test('should create TaxOptions with default values', () {
        final taxOptions = TaxOptions();

        expect(taxOptions.taxCalculator, isNull);
        expect(taxOptions.taxRate, isNull);
        expect(taxOptions.includeTaxInTotal, false);
        expect(taxOptions.taxLabel, 'Tax');
        expect(taxOptions.multiTaxCalculators, isEmpty);
        expect(taxOptions.taxRegion, isNull);
        expect(taxOptions.isExempt, isNull);
        expect(taxOptions.taxFormatter, isNull);
        expect(taxOptions.applyTaxPerItem, false);
      });

      test('should create TaxOptions with custom values', () {
        double customCalculator(FlexiCart cart) => 25;
        String customFormatter(double amount) =>
            '€${amount.toStringAsFixed(2)}';
        bool exemptFunction(FlexiCart cart) => false;

        final taxOptions = TaxOptions(
          taxCalculator: customCalculator,
          taxRate: 0.1,
          includeTaxInTotal: true,
          taxLabel: 'VAT',
          multiTaxCalculators: {
            'State': (cart) => 10.0,
            'Federal': (cart) => 15.0,
          },
          taxRegion: 'EU',
          isExempt: exemptFunction,
          taxFormatter: customFormatter,
          applyTaxPerItem: true,
        );

        expect(taxOptions.taxCalculator, equals(customCalculator));
        expect(taxOptions.taxRate, equals(0.1));
        expect(taxOptions.includeTaxInTotal, true);
        expect(taxOptions.taxLabel, equals('VAT'));
        expect(taxOptions.multiTaxCalculators, hasLength(2));
        expect(taxOptions.taxRegion, equals('EU'));
        expect(taxOptions.isExempt, equals(exemptFunction));
        expect(taxOptions.taxFormatter, equals(customFormatter));
        expect(taxOptions.applyTaxPerItem, true);
      });
    });

    group('Tax Calculation Tests', () {
      test('should return 0 when no tax configuration is provided', () {
        final taxOptions = TaxOptions();
        final tax = taxOptions.calculate(cart);

        expect(tax, equals(0.0));
      });

      test('should return 0 when cart is tax exempt', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1,
          isExempt: (cart) => true,
        );
        final tax = taxOptions.calculate(cart);

        expect(tax, equals(0.0));
      });

      test('should calculate tax using taxRate', () {
        final taxOptions = TaxOptions(taxRate: 0.08); // 8% tax
        final tax = taxOptions.calculate(cart);

        expect(tax, equals(20.0)); // 250 * 0.08 = 20
      });

      test('should use custom taxCalculator over taxRate', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1, // This should be ignored
          taxCalculator: (cart) => 30.0, // This should be used
        );
        final tax = taxOptions.calculate(cart);

        expect(tax, equals(30.0));
      });

      test('should prioritize exemption over other calculations', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1,
          taxCalculator: (cart) => 50.0,
          isExempt: (cart) => true,
        );
        final tax = taxOptions.calculate(cart);

        expect(tax, equals(0.0));
      });
    });

    group('Multi-Tax Calculator Tests', () {
      test('should calculate multiple taxes correctly', () {
        final taxOptions = TaxOptions(
          multiTaxCalculators: {
            'State Tax': (cart) => cart.totalPrice() * 0.05, // 5%
            'Federal Tax': (cart) => cart.totalPrice() * 0.03, // 3%
            'City Tax': (cart) => 10.0, // Fixed amount
          },
        );

        final allTaxes = taxOptions.calculateAll(cart);

        expect(allTaxes, hasLength(3));
        expect(allTaxes['State Tax'], equals(12.5)); // 250 * 0.05
        expect(allTaxes['Federal Tax'], equals(7.5)); // 250 * 0.03
        expect(allTaxes['City Tax'], equals(10.0));
      });

      test('should return empty map when no multi-tax calculators', () {
        final taxOptions = TaxOptions();
        final allTaxes = taxOptions.calculateAll(cart);

        expect(allTaxes, isEmpty);
      });
    });

    group('Tax Formatting Tests', () {
      test('should use default formatting when no custom formatter', () {
        final taxOptions = TaxOptions();
        final formatted = taxOptions.formatTax(25.50);

        expect(formatted, equals(r'$25.50'));
      });

      test('should use custom formatter when provided', () {
        final taxOptions = TaxOptions(
          taxFormatter: (amount) => '€${amount.toStringAsFixed(2)} EUR',
        );
        final formatted = taxOptions.formatTax(25.50);

        expect(formatted, equals('€25.50 EUR'));
      });

      test('should format zero tax correctly', () {
        final taxOptions = TaxOptions();
        final formatted = taxOptions.formatTax(0);

        expect(formatted, equals(r'$0.00'));
      });

      test('should format large tax amounts correctly', () {
        final taxOptions = TaxOptions();
        final formatted = taxOptions.formatTax(1234.56);

        expect(formatted, equals(r'$1234.56'));
      });
    });

    group('Tax Region Tests', () {
      test('should handle tax region for business logic', () {
        final taxOptions = TaxOptions(
          taxRegion: 'US',
          taxCalculator: (cart) {
            // Different logic based on region could be implemented here
            return cart.totalPrice() * 0.08;
          },
        );

        expect(taxOptions.taxRegion, equals('US'));
        final tax = taxOptions.calculate(cart);
        expect(tax, equals(20.0)); // 250 * 0.08
      });

      test('should handle null tax region', () {
        final taxOptions = TaxOptions();
        expect(taxOptions.taxRegion, isNull);
      });
    });

    group('Per-Item Tax Tests', () {
      test('should handle applyTaxPerItem flag', () {
        final taxOptions = TaxOptions(applyTaxPerItem: true);
        expect(taxOptions.applyTaxPerItem, true);
      });

      test('should default applyTaxPerItem to false', () {
        final taxOptions = TaxOptions();
        expect(taxOptions.applyTaxPerItem, false);
      });
    });

    group('Complex Tax Scenarios', () {
      test('should handle mixed tax calculations', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1, // Base 10% tax
          multiTaxCalculators: {
            'Luxury Tax': (cart) {
              // Apply luxury tax only if total > 200
              return cart.totalPrice() > 200 ? 15.0 : 0.0;
            },
            'Service Fee': (cart) => 5.0, // Fixed service fee
          },
        );

        // Test main tax calculation
        final mainTax = taxOptions.calculate(cart);
        expect(mainTax, equals(25.0)); // 250 * 0.1

        // Test multi-tax calculations
        final allTaxes = taxOptions.calculateAll(cart);
        expect(allTaxes['Luxury Tax'], equals(15.0)); // Cart total > 200
        expect(allTaxes['Service Fee'], equals(5.0));
      });

      test('should handle tax exemption with complex logic', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1,
          isExempt: (cart) {
            // Exempt if total quantity is less than 2
            return cart.totalQuantity() < 2;
          },
        );

        // Current cart has quantity 3 (2 + 1), so not exempt
        final tax = taxOptions.calculate(cart);
        expect(tax, equals(25.0));

        // Add a cart with low quantity
        final lowQuantityCart = FlexiCart<MockCartItem>()
          ..add(
            MockCartItem(
              id: '1',
              name: 'Single Item',
              price: 100,
              quantity: 1,
            ),
          );

        final exemptTax = taxOptions.calculate(lowQuantityCart);
        expect(exemptTax, equals(0.0)); // Should be exempt
      });

      test('should handle edge case with zero total price', () {
        final emptyCart = FlexiCart<MockCartItem>();
        final taxOptions = TaxOptions(taxRate: 0.1);

        final tax = taxOptions.calculate(emptyCart);
        expect(tax, equals(0.0));
      });

      test('should handle negative tax calculations', () {
        final taxOptions = TaxOptions(
          taxCalculator: (cart) => -10.0, // Negative tax (discount)
        );

        final tax = taxOptions.calculate(cart);
        expect(tax, equals(-10.0));
      });
    });

    group('Tax Options Integration Tests', () {
      test('should work with includeTaxInTotal flag', () {
        final taxOptions = TaxOptions(
          taxRate: 0.1,
          includeTaxInTotal: true,
        );

        expect(taxOptions.includeTaxInTotal, true);
        final tax = taxOptions.calculate(cart);
        expect(tax, equals(25.0));
      });

      test('should work with custom tax label', () {
        final taxOptions = TaxOptions(
          taxLabel: 'Sales Tax',
          taxRate: 0.08,
        );

        expect(taxOptions.taxLabel, equals('Sales Tax'));
        final tax = taxOptions.calculate(cart);
        expect(tax, equals(20.0));
      });
    });
  });
}
