import 'package:test/test.dart';
import 'package:faker/faker.dart';
import 'package:postgres/postgres.dart';
import '../lib/src/models/transaction.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/order.dart';
import '../lib/src/models/payment.dart';
import '../lib/src/repositories/transaction_repository.dart';
import '../lib/src/repositories/user_repository.dart';
import '../lib/src/repositories/order_repository.dart';
import '../lib/src/services/transaction_service.dart';
import '../lib/src/database/database_manager.dart';

void main() {
  late PostgreSQLConnection connection;
  late TransactionRepository transactionRepository;
  late UserRepository userRepository;
  late OrderRepository orderRepository;
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
    transactionService = TransactionService(
      transactionRepository,
      userRepository,
      orderRepository,
    );

    // Clear relevant tables before tests
    await connection.execute('DELETE FROM transactions');
    await connection.execute('DELETE FROM orders');
    await connection.execute('DELETE FROM users');
  });

  tearDownAll(() async {
    await connection.close();
  });

  group('Property 34: Transaction Processing', () {
    test('should record complete transaction details and update wallet balances for order payment', () async {
      // Arrange: Create test user and order
      final user = User(
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

      await userRepository.create(user);

      final order = Order(
        id: 1,
        uuid: faker.guid.guid(),
        customerId: user.id,
        partnerId: 2, // Assuming partner exists
        riderId: null,
        addressId: 1, // Assuming address exists
        status: OrderStatus.confirmed,
        totalAmount: 50.0,
        deliveryFee: 5.0,
        taxAmount: 2.5,
        discountAmount: 0.0,
        notes: null,
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
        actualDeliveryTime: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act: Process order payment transaction
      final transaction = await transactionService.processOrderPayment(
        orderId: order.id,
        userId: user.id,
        amount: order.totalAmount,
        paymentMethod: PaymentMethod.card,
        description: 'Payment for order #${order.id}',
      );

      // Assert: Verify transaction details are recorded correctly
      expect(transaction.id, isNotNull);
      expect(transaction.uuid, isNotNull);
      expect(transaction.userId, equals(user.id));
      expect(transaction.orderId, equals(order.id));
      expect(transaction.type, equals(TransactionType.orderPayment));
      expect(transaction.amount, equals(order.totalAmount));
      expect(transaction.status, equals(TransactionStatus.completed));
      expect(transaction.paymentMethod, equals(PaymentMethod.card));
      expect(transaction.description, equals('Payment for order #${order.id}'));
      expect(transaction.referenceId, equals('order_payment_${order.id}'));
      expect(transaction.processedAt, isNotNull);
      expect(transaction.createdAt, isNotNull);

      // Verify transaction was created in database
      final retrievedTransaction = await transactionRepository.findById(transaction.id);
      expect(retrievedTransaction, isNotNull);
      expect(retrievedTransaction!.uuid, equals(transaction.uuid));
      expect(retrievedTransaction.status, equals(TransactionStatus.completed));
    });

    test('should record complete transaction details and update wallet balances for wallet topup', () async {
      // Arrange: Create test user
      final user = User(
        id: 2,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
        balance: 50.0,
        rating: 0.0,
        noOfRatings: 0,
        isActive: true,
        emailVerified: true,
        mobileVerified: true,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.create(user);

      final topupAmount = 25.0;

      // Act: Process wallet topup transaction
      final transaction = await transactionService.processWalletTopup(
        userId: user.id,
        amount: topupAmount,
        paymentMethod: PaymentMethod.online,
        description: 'Wallet topup via online payment',
      );

      // Assert: Verify transaction details are recorded correctly
      expect(transaction.id, isNotNull);
      expect(transaction.uuid, isNotNull);
      expect(transaction.userId, equals(user.id));
      expect(transaction.orderId, isNull);
      expect(transaction.type, equals(TransactionType.walletTopup));
      expect(transaction.amount, equals(topupAmount));
      expect(transaction.status, equals(TransactionStatus.completed));
      expect(transaction.paymentMethod, equals(PaymentMethod.online));
      expect(transaction.description, equals('Wallet topup via online payment'));
      expect(transaction.referenceId, startsWith('wallet_topup_'));
      expect(transaction.processedAt, isNotNull);
      expect(transaction.createdAt, isNotNull);

      // Verify transaction was created in database
      final retrievedTransaction = await transactionRepository.findById(transaction.id);
      expect(retrievedTransaction, isNotNull);
      expect(retrievedTransaction!.type, equals(TransactionType.walletTopup));
      expect(retrievedTransaction.status, equals(TransactionStatus.completed));
    });

    test('should record complete transaction details and update wallet balances for withdrawal', () async {
      // Arrange: Create test user with sufficient balance
      final user = User(
        id: 3,
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

      await userRepository.create(user);

      final withdrawalAmount = 30.0;

      // Act: Process withdrawal transaction
      final transaction = await transactionService.processWithdrawal(
        userId: user.id,
        amount: withdrawalAmount,
        paymentMethod: PaymentMethod.card,
        description: 'Withdrawal to card',
      );

      // Assert: Verify transaction details are recorded correctly
      expect(transaction.id, isNotNull);
      expect(transaction.uuid, isNotNull);
      expect(transaction.userId, equals(user.id));
      expect(transaction.orderId, isNull);
      expect(transaction.type, equals(TransactionType.withdrawal));
      expect(transaction.amount, equals(withdrawalAmount));
      expect(transaction.status, equals(TransactionStatus.completed));
      expect(transaction.paymentMethod, equals(PaymentMethod.card));
      expect(transaction.description, equals('Withdrawal to card'));
      expect(transaction.referenceId, startsWith('withdrawal_'));
      expect(transaction.processedAt, isNotNull);
      expect(transaction.createdAt, isNotNull);

      // Verify transaction was created in database
      final retrievedTransaction = await transactionRepository.findById(transaction.id);
      expect(retrievedTransaction, isNotNull);
      expect(retrievedTransaction!.type, equals(TransactionType.withdrawal));
      expect(retrievedTransaction.status, equals(TransactionStatus.completed));
    });

    test('should create commission transaction for partner', () async {
      // Arrange: Create partner user
      final partnerUser = User(
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

      await userRepository.create(partnerUser);

      final orderId = 100;
      final commissionAmount = 10.0;
      final platformFee = 2.5;

      // Act: Create commission transaction
      final transaction = await transactionRepository.createCommissionTransaction(
        orderId: orderId,
        partnerId: partnerUser.id,
        commissionAmount: commissionAmount,
        platformFee: platformFee,
      );

      // Assert: Verify commission transaction details
      expect(transaction.id, isNotNull);
      expect(transaction.uuid, isNotNull);
      expect(transaction.userId, equals(partnerUser.id));
      expect(transaction.orderId, equals(orderId));
      expect(transaction.type, equals(TransactionType.commission));
      expect(transaction.amount, equals(commissionAmount));
      expect(transaction.status, equals(TransactionStatus.completed));
      expect(transaction.description, equals('Commission for order #$orderId'));
      expect(transaction.referenceId, equals('commission_$orderId'));
      expect(transaction.processedAt, isNotNull);
      expect(transaction.createdAt, isNotNull);

      // Verify transaction was created in database
      final retrievedTransaction = await transactionRepository.findById(transaction.id);
      expect(retrievedTransaction, isNotNull);
      expect(retrievedTransaction!.type, equals(TransactionType.commission));
      expect(retrievedTransaction.status, equals(TransactionStatus.completed));
    });

    test('should create refund transaction', () async {
      // Arrange: Create test user
      final user = User(
        id: 5,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      await userRepository.create(user);

      final orderId = 101;
      final refundAmount = 25.0;
      final reason = 'Order cancelled by customer';

      // Act: Create refund transaction
      final transaction = await transactionRepository.createRefundTransaction(
        orderId: orderId,
        userId: user.id,
        refundAmount: refundAmount,
        reason: reason,
      );

      // Assert: Verify refund transaction details
      expect(transaction.id, isNotNull);
      expect(transaction.uuid, isNotNull);
      expect(transaction.userId, equals(user.id));
      expect(transaction.orderId, equals(orderId));
      expect(transaction.type, equals(TransactionType.refund));
      expect(transaction.amount, equals(refundAmount));
      expect(transaction.status, equals(TransactionStatus.completed));
      expect(transaction.description, equals('Refund for order #$orderId: $reason'));
      expect(transaction.referenceId, equals('refund_$orderId'));
      expect(transaction.processedAt, isNotNull);
      expect(transaction.createdAt, isNotNull);

      // Verify transaction was created in database
      final retrievedTransaction = await transactionRepository.findById(transaction.id);
      expect(retrievedTransaction, isNotNull);
      expect(retrievedTransaction!.type, equals(TransactionType.refund));
      expect(retrievedTransaction.status, equals(TransactionStatus.completed));
    });

    test('should validate status transitions correctly', () async {
      // Arrange: Create a pending transaction
      final user = User(
        id: 6,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      await userRepository.create(user);

      final request = CreateTransactionRequest(
        userId: user.id,
        type: TransactionType.walletTopup,
        amount: 10.0,
        paymentMethod: PaymentMethod.card,
      );

      final transaction = await transactionService.createTransaction(request);

      // Act & Assert: Valid transitions from pending
      var updated = await transactionService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.processing,
      );
      expect(updated!.status, equals(TransactionStatus.processing));

      updated = await transactionService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.completed,
      );
      expect(updated!.status, equals(TransactionStatus.completed));

      // Assert: Invalid transition from completed (should remain completed)
      updated = await transactionService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.processing,
      );
      expect(updated, isNull); // Should return null for invalid transition
    });

    test('should handle transaction failure correctly', () async {
      // Arrange: Create a processing transaction
      final user = User(
        id: 7,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      await userRepository.create(user);

      final request = CreateTransactionRequest(
        userId: user.id,
        type: TransactionType.walletTopup,
        amount: 15.0,
        paymentMethod: PaymentMethod.card,
      );

      final transaction = await transactionService.createTransaction(request);
      await transactionService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.processing,
      );

      // Act: Mark transaction as failed
      final updated = await transactionService.updateTransactionStatus(
        transaction.id,
        TransactionStatus.failed,
      );

      // Assert: Transaction should be marked as failed
      expect(updated!.status, equals(TransactionStatus.failed));
      expect(updated.processedAt, isNotNull);

      // Verify in database
      final retrieved = await transactionRepository.findById(transaction.id);
      expect(retrieved!.status, equals(TransactionStatus.failed));
    });

    test('should retrieve transactions by various filters', () async {
      // Arrange: Create multiple transactions for different users
      final user1 = User(
        id: 8,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      final user2 = User(
        id: 9,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      await userRepository.create(user1);
      await userRepository.create(user2);

      // Create transactions
      await transactionService.processOrderPayment(
        orderId: 200,
        userId: user1.id,
        amount: 20.0,
        paymentMethod: PaymentMethod.card,
      );

      await transactionService.processWalletTopup(
        userId: user2.id,
        amount: 30.0,
        paymentMethod: PaymentMethod.online,
      );

      // Act & Assert: Filter by user
      final user1Transactions = await transactionService.getUserTransactions(user1.id);
      expect(user1Transactions.length, equals(1));
      expect(user1Transactions.first.userId, equals(user1.id));
      expect(user1Transactions.first.type, equals(TransactionType.orderPayment));

      final user2Transactions = await transactionService.getUserTransactions(user2.id);
      expect(user2Transactions.length, equals(1));
      expect(user2Transactions.first.userId, equals(user2.id));
      expect(user2Transactions.first.type, equals(TransactionType.walletTopup));

      // Filter by type
      final filter = TransactionFilter(type: TransactionType.orderPayment);
      final orderPayments = await transactionService.getAllTransactions(filter: filter);
      expect(orderPayments.length, greaterThanOrEqualTo(1));
      expect(orderPayments.every((t) => t.type == TransactionType.orderPayment), isTrue);

      // Filter by status
      final completedFilter = TransactionFilter(status: TransactionStatus.completed);
      final completedTransactions = await transactionService.getAllTransactions(filter: completedFilter);
      expect(completedTransactions.length, greaterThanOrEqualTo(2));
      expect(completedTransactions.every((t) => t.status == TransactionStatus.completed), isTrue);
    });

    test('should calculate transaction statistics correctly', () async {
      // Arrange: Use existing transactions from previous tests

      // Act: Get transaction statistics
      final statistics = await transactionService.getTransactionStatistics();

      // Assert: Verify statistics are calculated correctly
      expect(statistics, isNotNull);
      expect(statistics['total_transactions'], isNotNull);
      expect(statistics['completed_transactions'], isNotNull);
      expect(statistics['failed_transactions'], isNotNull);
      expect(statistics['total_amount'], isNotNull);
      expect(statistics['average_amount'], isNotNull);
      expect(statistics['min_amount'], isNotNull);
      expect(statistics['max_amount'], isNotNull);

      // Verify that completed transactions contribute to total amount
      expect(statistics['total_amount'], greaterThan(0));
    });

    test('should generate unique UUIDs for transactions', () async {
      // Arrange: Create multiple transactions
      final user = User(
        id: 10,
        uuid: faker.guid.guid(),
        username: faker.internet.userName(),
        email: faker.internet.email(),
        mobile: faker.phoneNumber.us(),
        passwordHash: faker.randomGenerator.string(64),
        role: UserRole.customer,
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

      await userRepository.create(user);

      // Act: Create multiple transactions
      final transaction1 = await transactionService.processWalletTopup(
        userId: user.id,
        amount: 5.0,
        paymentMethod: PaymentMethod.card,
      );

      final transaction2 = await transactionService.processWalletTopup(
        userId: user.id,
        amount: 7.0,
        paymentMethod: PaymentMethod.card,
      );

      // Assert: UUIDs should be unique
      expect(transaction1.uuid, isNot(equals(transaction2.uuid)));
      expect(transaction1.id, isNot(equals(transaction2.id)));

      // Verify both transactions exist in database
      final retrieved1 = await transactionRepository.findByUuid(transaction1.uuid);
      final retrieved2 = await transactionRepository.findByUuid(transaction2.uuid);

      expect(retrieved1, isNotNull);
      expect(retrieved2, isNotNull);
      expect(retrieved1!.uuid, equals(transaction1.uuid));
      expect(retrieved2!.uuid, equals(transaction2.uuid));
    });
  });
}
