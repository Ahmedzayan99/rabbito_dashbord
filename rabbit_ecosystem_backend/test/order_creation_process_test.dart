import 'package:test/test.dart';
import '../lib/src/models/order.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';
import '../lib/src/models/partner.dart';
import '../lib/src/models/product.dart';
import '../lib/src/models/address.dart';
import '../lib/src/services/order_service.dart';
import '../lib/src/repositories/order_repository.dart';
import '../lib/src/repositories/user_repository.dart';
import '../lib/src/repositories/partner_repository.dart';
import '../lib/src/repositories/product_repository.dart';
import '../lib/src/database/database_connection.dart';

/// **Feature: rabbit-ecosystem, Property 24: Order Creation Process**
/// **Validates: Requirements 6.1**
/// 
/// Property: For any valid order request with customer, partner, address, and items,
/// the system should create an order with pending status and calculate correct totals
void main() {
  late DatabaseConnection dbConnection;
  late OrderService orderService;
  late OrderRepository orderRepository;
  late UserRepository userRepository;
  late PartnerRepository partnerRepository;
  late ProductRepository productRepository;

  setUpAll(() async {
    // Initialize database connection for testing
    dbConnection = DatabaseConnection();
    await dbConnection.connect();
    
    // Initialize repositories
    orderRepository = OrderRepository(dbConnection);
    userRepository = UserRepository(dbConnection);
    partnerRepository = PartnerRepository(dbConnection);
    productRepository = ProductRepository(dbConnection);
    
    // Initialize service
    orderService = OrderService(
      orderRepository,
      userRepository,
      partnerRepository,
      productRepository,
    );
  });

  tearDownAll(() async {
    await dbConnection.close();
  });

  group('Order Creation Process Property Tests', () {
    test('Property 24: Order creation with valid data should succeed', () async {
      // Property: For any valid order request, the system should create an order
      // with pending status and calculate correct totals
      
      for (int i = 0; i < 100; i++) {
        // Generate random valid test data
        final customer = _generateRandomCustomer();
        final partner = _generateRandomPartner();
        final address = _generateRandomAddress();
        final products = _generateRandomProducts(partner.id);
        final orderItems = _generateRandomOrderItems(products);
        
        // Create test data in database
        final createdCustomer = await userRepository.create(customer);
        final createdPartner = await partnerRepository.create(partner);
        final createdAddress = await _createAddress(address, createdCustomer.id);
        
        final createdProducts = <Product>[];
        for (final product in products) {
          final createdProduct = await productRepository.create(
            product.copyWith(partnerId: createdPartner.id)
          );
          createdProducts.add(createdProduct);
        }
        
        // Update order items with actual product IDs
        final validOrderItems = orderItems.map((item) {
          final productIndex = products.indexWhere((p) => p.id == item['product_id']);
          return {
            ...item,
            'product_id': createdProducts[productIndex].id,
          };
        }).toList();
        
        try {
          // Create order
          final order = await orderService.createOrder(
            customerId: createdCustomer.id,
            partnerId: createdPartner.id,
            addressId: createdAddress.id,
            items: validOrderItems,
            notes: _generateRandomNotes(),
          );
          
          // Verify order properties
          expect(order.customerId, equals(createdCustomer.id));
          expect(order.partnerId, equals(createdPartner.id));
          expect(order.addressId, equals(createdAddress.id));
          expect(order.status, equals(OrderStatus.pending));
          expect(order.createdAt, isNotNull);
          expect(order.id, isNotNull);
          
          // Verify order total calculation
          final expectedTotal = _calculateExpectedTotal(validOrderItems, createdProducts);
          expect(order.totalAmount, closeTo(expectedTotal, 0.01));
          
          // Verify order items are stored correctly
          final orderWithItems = await orderService.getOrderWithItems(order.id);
          expect(orderWithItems, isNotNull);
          expect(orderWithItems!['items'], hasLength(validOrderItems.length));
          
          // Verify each item
          final storedItems = orderWithItems['items'] as List<dynamic>;
          for (int j = 0; j < validOrderItems.length; j++) {
            final expectedItem = validOrderItems[j];
            final storedItem = storedItems[j] as Map<String, dynamic>;
            
            expect(storedItem['product_id'], equals(expectedItem['product_id']));
            expect(storedItem['quantity'], equals(expectedItem['quantity']));
            expect(storedItem['special_instructions'], 
                   equals(expectedItem['special_instructions']));
          }
          
        } finally {
          // Cleanup test data
          await _cleanupTestData(
            createdCustomer.id,
            createdPartner.id,
            createdAddress.id,
            createdProducts.map((p) => p.id).toList(),
          );
        }
      }
    });

    test('Property 24: Order creation with invalid data should fail gracefully', () async {
      // Property: For any invalid order request, the system should reject it
      // with appropriate error messages
      
      for (int i = 0; i < 50; i++) {
        // Generate invalid test scenarios
        final invalidScenario = _generateInvalidOrderScenario();
        
        try {
          await orderService.createOrder(
            customerId: invalidScenario['customer_id'] as int,
            partnerId: invalidScenario['partner_id'] as int,
            addressId: invalidScenario['address_id'] as int,
            items: invalidScenario['items'] as List<Map<String, dynamic>>,
            notes: invalidScenario['notes'] as String?,
          );
          
          // If we reach here, the order creation should have failed
          fail('Expected order creation to fail for invalid scenario: $invalidScenario');
          
        } catch (e) {
          // Verify that appropriate exception is thrown
          expect(e, isA<Exception>());
          expect(e.toString(), contains('not found'));
        }
      }
    });

    test('Property 24: Order creation should maintain data consistency', () async {
      // Property: For any order creation, the system should maintain referential integrity
      // and data consistency across all related entities
      
      for (int i = 0; i < 50; i++) {
        // Generate test data
        final customer = _generateRandomCustomer();
        final partner = _generateRandomPartner();
        final address = _generateRandomAddress();
        final products = _generateRandomProducts(partner.id);
        final orderItems = _generateRandomOrderItems(products);
        
        // Create test data
        final createdCustomer = await userRepository.create(customer);
        final createdPartner = await partnerRepository.create(partner);
        final createdAddress = await _createAddress(address, createdCustomer.id);
        
        final createdProducts = <Product>[];
        for (final product in products) {
          final createdProduct = await productRepository.create(
            product.copyWith(partnerId: createdPartner.id)
          );
          createdProducts.add(createdProduct);
        }
        
        final validOrderItems = orderItems.map((item) {
          final productIndex = products.indexWhere((p) => p.id == item['product_id']);
          return {
            ...item,
            'product_id': createdProducts[productIndex].id,
          };
        }).toList();
        
        try {
          // Create order
          final order = await orderService.createOrder(
            customerId: createdCustomer.id,
            partnerId: createdPartner.id,
            addressId: createdAddress.id,
            items: validOrderItems,
            notes: _generateRandomNotes(),
          );
          
          // Verify all referenced entities still exist and are consistent
          final retrievedCustomer = await userRepository.findById(createdCustomer.id);
          final retrievedPartner = await partnerRepository.findById(createdPartner.id);
          final retrievedOrder = await orderRepository.findById(order.id);
          
          expect(retrievedCustomer, isNotNull);
          expect(retrievedPartner, isNotNull);
          expect(retrievedOrder, isNotNull);
          
          // Verify order references are correct
          expect(retrievedOrder!.customerId, equals(createdCustomer.id));
          expect(retrievedOrder.partnerId, equals(createdPartner.id));
          expect(retrievedOrder.addressId, equals(createdAddress.id));
          
        } finally {
          // Cleanup
          await _cleanupTestData(
            createdCustomer.id,
            createdPartner.id,
            createdAddress.id,
            createdProducts.map((p) => p.id).toList(),
          );
        }
      }
    });
  });
}

// Helper functions for generating test data
User _generateRandomCustomer() {
  final random = DateTime.now().millisecondsSinceEpoch;
  return User(
    id: 0, // Will be assigned by database
    mobile: '05${random.toString().substring(0, 8)}',
    username: 'customer_$random',
    email: 'customer_$random@test.com',
    role: UserRole.customer,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Partner _generateRandomPartner() {
  final random = DateTime.now().millisecondsSinceEpoch;
  return Partner(
    id: 0, // Will be assigned by database
    name: 'Partner $random',
    mobile: '05${random.toString().substring(0, 8)}',
    email: 'partner_$random@test.com',
    address: 'Test Address $random',
    status: PartnerStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Address _generateRandomAddress() {
  final random = DateTime.now().millisecondsSinceEpoch;
  return Address(
    id: 0, // Will be assigned by database
    userId: 0, // Will be set later
    title: 'Address $random',
    address: 'Test Address $random, Riyadh',
    latitude: 24.7136 + (random % 100) / 10000,
    longitude: 46.6753 + (random % 100) / 10000,
    isDefault: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

List<Product> _generateRandomProducts(int partnerId) {
  final random = DateTime.now().millisecondsSinceEpoch;
  final productCount = 1 + (random % 5); // 1-5 products
  
  return List.generate(productCount, (index) {
    return Product(
      id: index + 1, // Temporary ID
      name: 'Product ${random}_$index',
      description: 'Test product description $index',
      price: 10.0 + (random % 100),
      categoryId: 1,
      partnerId: partnerId,
      isAvailable: true,
      stockQuantity: 10 + (random % 90),
      preparationTime: 15 + (random % 45),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });
}

List<Map<String, dynamic>> _generateRandomOrderItems(List<Product> products) {
  final random = DateTime.now().millisecondsSinceEpoch;
  
  return products.map((product) {
    final quantity = 1 + (random % 5); // 1-5 quantity
    return {
      'product_id': product.id,
      'variant_id': null,
      'quantity': quantity,
      'special_instructions': random % 2 == 0 ? 'Special instruction $random' : null,
    };
  }).toList();
}

String? _generateRandomNotes() {
  final random = DateTime.now().millisecondsSinceEpoch;
  return random % 3 == 0 ? 'Order notes $random' : null;
}

Map<String, dynamic> _generateInvalidOrderScenario() {
  final random = DateTime.now().millisecondsSinceEpoch;
  final scenarios = [
    {
      'customer_id': -1, // Invalid customer ID
      'partner_id': 1,
      'address_id': 1,
      'items': [{'product_id': 1, 'quantity': 1}],
      'notes': null,
    },
    {
      'customer_id': 1,
      'partner_id': -1, // Invalid partner ID
      'address_id': 1,
      'items': [{'product_id': 1, 'quantity': 1}],
      'notes': null,
    },
    {
      'customer_id': 1,
      'partner_id': 1,
      'address_id': -1, // Invalid address ID
      'items': [{'product_id': 1, 'quantity': 1}],
      'notes': null,
    },
    {
      'customer_id': 1,
      'partner_id': 1,
      'address_id': 1,
      'items': [], // Empty items
      'notes': null,
    },
    {
      'customer_id': 1,
      'partner_id': 1,
      'address_id': 1,
      'items': [{'product_id': -1, 'quantity': 1}], // Invalid product ID
      'notes': null,
    },
  ];
  
  return scenarios[random % scenarios.length];
}

double _calculateExpectedTotal(List<Map<String, dynamic>> items, List<Product> products) {
  double total = 0.0;
  
  for (final item in items) {
    final productId = item['product_id'] as int;
    final quantity = item['quantity'] as int;
    
    final product = products.firstWhere((p) => p.id == productId);
    total += product.price * quantity;
  }
  
  return total;
}

Future<Address> _createAddress(Address address, int userId) async {
  // In a real implementation, this would use AddressRepository
  // For now, return the address with updated user ID
  return address.copyWith(userId: userId, id: DateTime.now().millisecondsSinceEpoch);
}

Future<void> _cleanupTestData(
  int customerId,
  int partnerId,
  int addressId,
  List<int> productIds,
) async {
  // In a real implementation, this would clean up all test data
  // For now, this is a placeholder
  try {
    // Clean up in reverse order of creation to maintain referential integrity
    for (final productId in productIds) {
      // await productRepository.delete(productId);
    }
    // await addressRepository.delete(addressId);
    // await partnerRepository.delete(partnerId);
    // await userRepository.delete(customerId);
  } catch (e) {
    // Ignore cleanup errors in tests
  }
}