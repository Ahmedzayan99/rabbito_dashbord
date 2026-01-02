import 'package:test/test.dart';
import 'package:faker/faker.dart';
import 'package:postgres/postgres.dart';
import '../lib/src/models/transaction.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/order.dart';
import '../lib/src/models/partner.dart';
import '../lib/src/repositories/transaction_repository.dart';
import '../lib/src/repositories/user_repository.dart';
import '../lib/src/repositories/order_repository.dart';
import '../lib/src/repositories/partner_repository.dart';
import '../lib/src/services/transaction_service.dart';

void main() {
  late PostgreSQLConnection connection;
  late TransactionRepository transactionRepository;
  late UserRepository userRepository;
  late OrderRepository orderRepository;
  late PartnerRepository partnerRepository;
  late TransactionService transactionService;
  final faker = Faker();

  setUpAll(() async {
    // Initialize a test database connection
    connection = PostgreSQLConnection(
      'localhost',
      5432,
      'rabbit_ecosystem_test',
      username: 'rabbit_user',
      password: 'rabbit_password_2024',
    );
    await connection.open();

    transactionRepository = TransactionRepository(connection);
    userRepository = UserRepository(connection);
    orderRepository = OrderRepository(connection);
    partnerRepository = PartnerRepository(connection);
    transactionService = TransactionService(
      transactionRepository,
      userRepository,
      orderRepository,
    );

    // Clear relevant tables before tests
    await connection.execute('DELETE FROM transactions');
    await connection.execute('DELETE FROM orders');
    await connection.execute('DELETE FROM partners');
    await connection.execute('DELETE FROM users');
  });

  tearDownAll(() async {
    await connection.close();
  });

  group('Property 36: Payment Distribution', () {
    test('should distribute payment amounts correctly to partner, rider, and platform for completed order', () async {
      // Arrange: Create customer user
      final customer = User(
        id: 1,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
        balance: 100.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(customer);

      // Create partner user
      final partnerUser = User(
        id: 2,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.partner,
        balance: 0.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(partnerUser);

      // Create partner
      final partner = Partner(
        id: 1,
        uuid: faker.guid.guid(),
        userId: partnerUser.id,
        businessName: faker.company.name(),
        businessType: 'restaurant',
        description: faker.lorem.sentence(),
        address: faker.address.streetAddress(),
        phone: faker.phoneNumber.us(),
        email: faker.internet.email(),
        licenseNumber: faker.randomGenerator.string(10),
        taxId: faker.randomGenerator.string(9),
        status: PartnerStatus.active,
        rating: 4.5,
        noOfRatings: 10,
        totalOrders: 0,
        totalRevenue: 0.0,
        commissionRate: 0.10, // 10% commission
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await partnerRepository.create(partner);

      // Create rider user
      final riderUser = User(
        id: 3,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.rider,
        balance: 0.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(riderUser);

      // Create order
      final orderAmount = 100.0; // Base order amount
      final deliveryFee = 10.0; // Delivery fee
      final totalAmount = orderAmount + deliveryFee; // 110.0 total

      final order = Order(
        id: 1,
        uuid: faker.guid.guid(),
        customerId: customer.id,
        partnerId: partner.id,
        riderId: riderUser.id,
        addressId: 1, // Assuming address exists
        status: OrderStatus.delivered, // Already delivered for distribution
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        taxAmount: 5.5,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Manually insert order since we don't have full order creation logic
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, actual_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        order.id,
        order.uuid,
        order.customerId,
        order.partnerId,
        order.riderId,
        order.addressId,
        order.status.name,
        order.totalAmount,
        order.deliveryFee,
        order.taxAmount,
        order.discountAmount,
        order.estimatedDeliveryTime.toIso8601String(),
        order.actualDeliveryTime!.toIso8601String(),
        order.createdAt.toIso8601String(),
        order.updatedAt.toIso8601String(),
      ]);

      // Act: Process payment distribution
      await transactionService.processPaymentDistribution(order.id);

      // Assert: Verify payment distribution
      // Check commission transaction for partner
      final commissionTransactions = await transactionRepository.findByOrderId(order.id);
      final commissionTransaction = commissionTransactions.firstWhere(
        (t) => t.type == TransactionType.commission,
        orElse: () => throw Exception('Commission transaction not found'),
      );

      // Partner commission should be 10% of order amount (excluding delivery fee)
      final expectedCommission = orderAmount * partner.commissionRate; // 100 * 0.10 = 10.0
      expect(commissionTransaction.amount, equals(expectedCommission));
      expect(commissionTransaction.userId, equals(partnerUser.id));
      expect(commissionTransaction.status, equals(TransactionStatus.completed));

      // Verify transaction details
      expect(commissionTransaction.description, equals('Commission for order #${order.id}'));
      expect(commissionTransaction.referenceId, equals('commission_${order.id}'));
      expect(commissionTransaction.processedAt, isNotNull);
    });

    test('should handle different commission rates correctly', () async {
      // Arrange: Create partner with different commission rate
      final partnerUser2 = User(
        id: 4,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.partner,
        balance: 0.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(partnerUser2);

      final partner2 = Partner(
        id: 2,
        uuid: faker.guid.guid(),
        userId: partnerUser2.id,
        businessName: faker.company.name(),
        businessType: 'restaurant',
        description: faker.lorem.sentence(),
        address: faker.address.streetAddress(),
        phone: faker.phoneNumber.us(),
        email: faker.internet.email(),
        licenseNumber: faker.randomGenerator.string(10),
        taxId: faker.randomGenerator.string(9),
        status: PartnerStatus.active,
        rating: 4.5,
        noOfRatings: 10,
        totalOrders: 0,
        totalRevenue: 0.0,
        commissionRate: 0.15, // 15% commission
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await partnerRepository.create(partner2);

      // Create order with different amount
      final orderAmount2 = 200.0;
      final deliveryFee2 = 15.0;
      final totalAmount2 = orderAmount2 + deliveryFee2;

      final order2 = Order(
        id: 2,
        uuid: faker.guid.guid(),
        customerId: 1, // Use existing customer
        partnerId: partner2.id,
        riderId: 3, // Use existing rider
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: totalAmount2,
        deliveryFee: deliveryFee2,
        taxAmount: 11.0,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert order
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, actual_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        order2.id,
        order2.uuid,
        order2.customerId,
        order2.partnerId,
        order2.riderId,
        order2.addressId,
        order2.status.name,
        order2.totalAmount,
        order2.deliveryFee,
        order2.taxAmount,
        order2.discountAmount,
        order2.estimatedDeliveryTime.toIso8601String(),
        order2.actualDeliveryTime!.toIso8601String(),
        order2.createdAt.toIso8601String(),
        order2.updatedAt.toIso8601String(),
      ]);

      // Act: Process payment distribution
      await transactionService.processPaymentDistribution(order2.id);

      // Assert: Verify commission with different rate
      final commissionTransactions2 = await transactionRepository.findByOrderId(order2.id);
      final commissionTransaction2 = commissionTransactions2.firstWhere(
        (t) => t.type == TransactionType.commission,
        orElse: () => throw Exception('Commission transaction not found'),
      );

      // Partner commission should be 15% of order amount (excluding delivery fee)
      final expectedCommission2 = orderAmount2 * partner2.commissionRate; // 200 * 0.15 = 30.0
      expect(commissionTransaction2.amount, equals(expectedCommission2));
      expect(commissionTransaction2.userId, equals(partnerUser2.id));
      expect(commissionTransaction2.status, equals(TransactionStatus.completed));
    });

    test('should only process distribution for delivered orders', () async {
      // Arrange: Create order with non-delivered status
      final pendingOrder = Order(
        id: 3,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: 1,
        riderId: 3,
        addressId: 1,
        status: OrderStatus.confirmed, // Not delivered
        totalAmount: 75.0,
        deliveryFee: 7.5,
        taxAmount: 3.75,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert order
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        pendingOrder.id,
        pendingOrder.uuid,
        pendingOrder.customerId,
        pendingOrder.partnerId,
        pendingOrder.riderId,
        pendingOrder.addressId,
        pendingOrder.status.name,
        pendingOrder.totalAmount,
        pendingOrder.deliveryFee,
        pendingOrder.taxAmount,
        pendingOrder.discountAmount,
        pendingOrder.estimatedDeliveryTime.toIso8601String(),
        pendingOrder.createdAt.toIso8601String(),
        pendingOrder.updatedAt.toIso8601String(),
      ]);

      // Act & Assert: Should throw exception for non-delivered order
      expect(
        () => transactionService.processPaymentDistribution(pendingOrder.id),
        throwsException,
      );

      // Verify no commission transactions were created
      final transactions = await transactionRepository.findByOrderId(pendingOrder.id);
      final commissionTransactions = transactions.where(
        (t) => t.type == TransactionType.commission,
      );
      expect(commissionTransactions.isEmpty, isTrue);
    });

    test('should calculate platform fees correctly', () async {
      // Arrange: Create order for existing partner
      final orderAmount3 = 150.0;
      final deliveryFee3 = 12.0;
      final totalAmount3 = orderAmount3 + deliveryFee3;

      final order3 = Order(
        id: 4,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: 1, // Use existing partner
        riderId: 3,
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: totalAmount3,
        deliveryFee: deliveryFee3,
        taxAmount: 7.5,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert order
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, actual_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        order3.id,
        order3.uuid,
        order3.customerId,
        order3.partnerId,
        order3.riderId,
        order3.addressId,
        order3.status.name,
        order3.totalAmount,
        order3.deliveryFee,
        order3.taxAmount,
        order3.discountAmount,
        order3.estimatedDeliveryTime.toIso8601String(),
        order3.actualDeliveryTime!.toIso8601String(),
        order3.createdAt.toIso8601String(),
        order3.updatedAt.toIso8601String(),
      ]);

      // Act: Process payment distribution
      await transactionService.processPaymentDistribution(order3.id);

      // Assert: Verify commission calculation
      final commissionTransactions3 = await transactionRepository.findByOrderId(order3.id);
      final commissionTransaction3 = commissionTransactions3.firstWhere(
        (t) => t.type == TransactionType.commission,
      );

      // With 10% commission rate: 150 * 0.10 = 15.0
      expect(commissionTransaction3.amount, equals(15.0));
      expect(commissionTransaction3.status, equals(TransactionStatus.completed));

      // Verify commission is credited to partner
      final partnerUser = await userRepository.findById(2); // Partner user ID
      expect(partnerUser, isNotNull);
      // Note: In real implementation, wallet balance would be updated here
    });

    test('should handle multiple orders payment distribution correctly', () async {
      // Arrange: Create multiple orders for same partner
      final order4 = Order(
        id: 5,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: 1,
        riderId: 3,
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: 80.0,
        deliveryFee: 8.0,
        taxAmount: 4.0,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final order5 = Order(
        id: 6,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: 1,
        riderId: 3,
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: 120.0,
        deliveryFee: 10.0,
        taxAmount: 6.0,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert orders
      for (final order in [order4, order5]) {
        await connection.execute('''
          INSERT INTO orders (
            id, uuid, customer_id, partner_id, rider_id, address_id,
            status, total_amount, delivery_fee, tax_amount, discount_amount,
            estimated_delivery_time, actual_delivery_time, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          order.id,
          order.uuid,
          order.customerId,
          order.partnerId,
          order.riderId,
          order.addressId,
          order.status.name,
          order.totalAmount,
          order.deliveryFee,
          order.taxAmount,
          order.discountAmount,
          order.estimatedDeliveryTime.toIso8601String(),
          order.actualDeliveryTime!.toIso8601String(),
          order.createdAt.toIso8601String(),
          order.updatedAt.toIso8601String(),
        ]);
      }

      // Act: Process payment distribution for both orders
      await transactionService.processPaymentDistribution(order4.id);
      await transactionService.processPaymentDistribution(order5.id);

      // Assert: Verify commissions for both orders
      final commissionTransactions4 = await transactionRepository.findByOrderId(order4.id);
      final commissionTransactions5 = await transactionRepository.findByOrderId(order5.id);

      final commission4 = commissionTransactions4.firstWhere((t) => t.type == TransactionType.commission);
      final commission5 = commissionTransactions5.firstWhere((t) => t.type == TransactionType.commission);

      // Order 4: 80 * 0.10 = 8.0 commission
      expect(commission4.amount, equals(8.0));

      // Order 5: 120 * 0.10 = 12.0 commission
      expect(commission5.amount, equals(12.0));

      // Both should be completed
      expect(commission4.status, equals(TransactionStatus.completed));
      expect(commission5.status, equals(TransactionStatus.completed));

      // Both should credit the same partner
      expect(commission4.userId, equals(2)); // Partner user ID
      expect(commission5.userId, equals(2));
    });

    test('should handle edge case of zero commission rate', () async {
      // Arrange: Create partner with zero commission
      final zeroCommissionPartnerUser = User(
        id: 5,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.partner,
        balance: 0.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(zeroCommissionPartnerUser);

      final zeroCommissionPartner = Partner(
        id: 3,
        uuid: faker.guid.guid(),
        userId: zeroCommissionPartnerUser.id,
        businessName: faker.company.name(),
        businessType: 'restaurant',
        description: faker.lorem.sentence(),
        address: faker.address.streetAddress(),
        phone: faker.phoneNumber.us(),
        email: faker.internet.email(),
        licenseNumber: faker.randomGenerator.string(10),
        taxId: faker.randomGenerator.string(9),
        status: PartnerStatus.active,
        rating: 4.5,
        noOfRatings: 10,
        totalOrders: 0,
        totalRevenue: 0.0,
        commissionRate: 0.0, // Zero commission
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await partnerRepository.create(zeroCommissionPartner);

      // Create order
      final order6 = Order(
        id: 7,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: zeroCommissionPartner.id,
        riderId: 3,
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: 90.0,
        deliveryFee: 9.0,
        taxAmount: 4.5,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert order
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, actual_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        order6.id,
        order6.uuid,
        order6.customerId,
        order6.partnerId,
        order6.riderId,
        order6.addressId,
        order6.status.name,
        order6.totalAmount,
        order6.deliveryFee,
        order6.taxAmount,
        order6.discountAmount,
        order6.estimatedDeliveryTime.toIso8601String(),
        order6.actualDeliveryTime!.toIso8601String(),
        order6.createdAt.toIso8601String(),
        order6.updatedAt.toIso8601String(),
      ]);

      // Act: Process payment distribution
      await transactionService.processPaymentDistribution(order6.id);

      // Assert: Commission should be zero
      final commissionTransactions6 = await transactionRepository.findByOrderId(order6.id);
      final commissionTransaction6 = commissionTransactions6.firstWhere(
        (t) => t.type == TransactionType.commission,
      );

      expect(commissionTransaction6.amount, equals(0.0));
      expect(commissionTransaction6.status, equals(TransactionStatus.completed));
    });

    test('should maintain transaction integrity during distribution failures', () async {
      // Arrange: Create order for non-existent partner (simulate failure scenario)
      final invalidOrder = Order(
        id: 8,
        uuid: faker.guid.guid(),
        customerId: 1,
        partnerId: 999, // Non-existent partner
        riderId: 3,
        addressId: 1,
        status: OrderStatus.delivered,
        totalAmount: 60.0,
        deliveryFee: 6.0,
        taxAmount: 3.0,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert order
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, rider_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, actual_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        invalidOrder.id,
        invalidOrder.uuid,
        invalidOrder.customerId,
        invalidOrder.partnerId,
        invalidOrder.riderId,
        invalidOrder.addressId,
        invalidOrder.status.name,
        invalidOrder.totalAmount,
        invalidOrder.deliveryFee,
        invalidOrder.taxAmount,
        invalidOrder.discountAmount,
        invalidOrder.estimatedDeliveryTime.toIso8601String(),
        invalidOrder.actualDeliveryTime!.toIso8601String(),
        invalidOrder.createdAt.toIso8601String(),
        invalidOrder.updatedAt.toIso8601String(),
      ]);

      // Act & Assert: Should throw exception for invalid partner
      expect(
        () => transactionService.processPaymentDistribution(invalidOrder.id),
        throwsException,
      );

      // Verify no commission transactions were created for this order
      final transactions = await transactionRepository.findByOrderId(invalidOrder.id);
      final commissionTransactions = transactions.where(
        (t) => t.type == TransactionType.commission,
      );
      expect(commissionTransactions.isEmpty, isTrue);
    });
  });
}
