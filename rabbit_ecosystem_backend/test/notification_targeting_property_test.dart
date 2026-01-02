import 'package:test/test.dart';
import 'package:faker/faker.dart';
import 'package:postgres/postgres.dart';
import '../lib/src/models/notification.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/order.dart';
import '../lib/src/models/partner.dart';
import '../lib/src/repositories/notification_repository.dart';
import '../lib/src/repositories/user_repository.dart';
import '../lib/src/repositories/order_repository.dart';
import '../lib/src/services/notification_service.dart';
import '../lib/src/services/firebase_service.dart';

void main() {
  late PostgreSQLConnection connection;
  late NotificationRepository notificationRepository;
  late UserRepository userRepository;
  late OrderRepository orderRepository;
  late FirebaseService firebaseService;
  late NotificationService notificationService;
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

    notificationRepository = NotificationRepository(connection);
    userRepository = UserRepository(connection);
    orderRepository = OrderRepository(connection);
    firebaseService = FirebaseService();
    notificationService = NotificationService(
      notificationRepository,
      userRepository,
      firebaseService,
    );

    // Clear relevant tables before tests
    await connection.execute('DELETE FROM notifications');
    await connection.execute('DELETE FROM orders');
    await connection.execute('DELETE FROM partners');
    await connection.execute('DELETE FROM users');
  });

  tearDownAll(() async {
    await connection.close();
    firebaseService.dispose();
  });

  group('Property 39: Notification Targeting', () {
    test('should send order status update notification to correct customer', () async {
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

      // Create order
      final order = Order(
        id: 1,
        uuid: faker.guid.guid(),
        customerId: customer.id,
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

      // Insert order manually
      await connection.execute('''
        INSERT INTO orders (
          id, uuid, customer_id, partner_id, address_id,
          status, total_amount, delivery_fee, tax_amount, discount_amount,
          estimated_delivery_time, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        order.id,
        order.uuid,
        order.customerId,
        order.partnerId,
        order.addressId,
        order.status.name,
        order.totalAmount,
        order.deliveryFee,
        order.taxAmount,
        order.discountAmount,
        order.estimatedDeliveryTime.toIso8601String(),
        order.createdAt.toIso8601String(),
        order.updatedAt.toIso8601String(),
      ]);

      // Act: Send order status update notification
      final success = await notificationService.sendOrderStatusUpdate(
        userId: customer.id,
        orderId: order.id,
        status: 'confirmed',
        customerName: customer.username ?? 'Customer',
      );

      // Assert: Notification should be sent (even without FCM token, notification is saved)
      expect(success, isTrue);

      // Verify notification was created in database
      final notifications = await notificationRepository.findByUserId(customer.id);
      expect(notifications.length, equals(1));

      final notification = notifications.first;
      expect(notification.userId, equals(customer.id));
      expect(notification.title, equals('Order Update'));
      expect(notification.body, contains('order #${order.id}'));
      expect(notification.body, contains('confirmed'));
      expect(notification.type, equals('order_status_update'));
      expect(notification.data!['order_id'], equals(order.id.toString()));
      expect(notification.data!['status'], equals('confirmed'));
    });

    test('should send rider assignment notification to correct customer', () async {
      // Arrange: Create customer user
      final customer = User(
        id: 2,
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

      final riderName = 'Ahmed Rider';
      final estimatedTime = '30 minutes';

      // Act: Send rider assignment notification
      final success = await notificationService.sendRiderAssignment(
        userId: customer.id,
        orderId: 200,
        riderName: riderName,
        estimatedTime: estimatedTime,
      );

      // Assert: Notification should be sent
      expect(success, isTrue);

      // Verify notification was created
      final notifications = await notificationRepository.findByUserId(customer.id);
      expect(notifications.length, greaterThanOrEqualTo(1));

      final riderNotification = notifications.firstWhere(
        (n) => n.type == 'rider_assigned',
        orElse: () => throw Exception('Rider assignment notification not found'),
      );

      expect(riderNotification.userId, equals(customer.id));
      expect(riderNotification.title, equals('Rider Assigned'));
      expect(riderNotification.body, contains(riderName));
      expect(riderNotification.body, contains('order #200'));
      expect(riderNotification.body, contains(estimatedTime));
      expect(riderNotification.type, equals('rider_assigned'));
      expect(riderNotification.data!['rider_name'], equals(riderName));
      expect(riderNotification.data!['estimated_time'], equals(estimatedTime));
    });

    test('should send new order notification to correct partner', () async {
      // Arrange: Create partner user
      final partnerUser = User(
        id: 3,
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

      final customerName = 'John Customer';
      final orderAmount = 75.50;

      // Act: Send new order notification to partner
      final success = await notificationService.sendPartnerNewOrder(
        partnerId: partnerUser.id,
        orderId: 300,
        customerName: customerName,
        orderAmount: orderAmount,
      );

      // Assert: Notification should be sent
      expect(success, isTrue);

      // Verify notification was created
      final notifications = await notificationRepository.findByUserId(partnerUser.id);
      expect(notifications.length, greaterThanOrEqualTo(1));

      final orderNotification = notifications.firstWhere(
        (n) => n.type == 'new_order',
        orElse: () => throw Exception('New order notification not found'),
      );

      expect(orderNotification.userId, equals(partnerUser.id));
      expect(orderNotification.title, equals('New Order'));
      expect(orderNotification.body, contains('order #300'));
      expect(orderNotification.body, contains(customerName));
      expect(orderNotification.body, contains('SAR ${orderAmount.toStringAsFixed(2)}'));
      expect(orderNotification.type, equals('new_order'));
      expect(orderNotification.data!['order_id'], equals('300'));
      expect(orderNotification.data!['customer_name'], equals(customerName));
      expect(orderNotification.data!['amount'], equals(orderAmount.toString()));
    });

    test('should send promotional notification to targeted users', () async {
      // Arrange: Create multiple users
      final users = <User>[];
      for (var i = 4; i <= 6; i++) {
        final user = User(
          id: i,
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
        users.add(user);
      }

      final title = 'Special Offer!';
      final body = 'Get 50% off on your next order with code SAVE50';

      // Act: Send promotional notification to all customers
      final results = await notificationService.sendTargetedNotification(
        segment: UserSegment.allCustomers,
        title: title,
        body: body,
        type: 'promotion',
        data: {'promo_code': 'SAVE50', 'discount': '50'},
      );

      // Assert: Notifications should be sent to all customer users
      expect(results.length, equals(users.length));
      for (final user in users) {
        expect(results[user.id], isTrue);

        // Verify notification was created for each user
        final userNotifications = await notificationRepository.findByUserId(user.id);
        final promoNotification = userNotifications.firstWhere(
          (n) => n.type == 'promotion',
          orElse: () => throw Exception('Promotion notification not found for user ${user.id}'),
        );

        expect(promoNotification.title, equals(title));
        expect(promoNotification.body, equals(body));
        expect(promoNotification.data!['promo_code'], equals('SAVE50'));
        expect(promoNotification.data!['discount'], equals('50'));
      }
    });

    test('should send system alert to all active users', () async {
      // Arrange: Create users with different roles
      final customer = User(
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

      final partner = User(
        id: 8,
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

      await userRepository.create(customer);
      await userRepository.create(partner);

      final title = 'System Maintenance';
      final body = 'The system will be under maintenance from 2 AM to 4 AM tonight';

      // Act: Send system alert to active users
      final results = await notificationService.sendTargetedNotification(
        segment: UserSegment.activeUsers,
        title: title,
        body: body,
        type: 'system_alert',
        data: {'maintenance_start': '02:00', 'maintenance_end': '04:00'},
      );

      // Assert: Notifications should be sent to both active users
      expect(results.length, equals(2));
      expect(results[customer.id], isTrue);
      expect(results[partner.id], isTrue);

      // Verify notifications were created
      for (final user in [customer, partner]) {
        final userNotifications = await notificationRepository.findByUserId(user.id);
        final alertNotification = userNotifications.firstWhere(
          (n) => n.type == 'system_alert',
          orElse: () => throw Exception('System alert not found for user ${user.id}'),
        );

        expect(alertNotification.title, equals(title));
        expect(alertNotification.body, equals(body));
        expect(alertNotification.data!['maintenance_start'], equals('02:00'));
        expect(alertNotification.data!['maintenance_end'], equals('04:00'));
      }
    });

    test('should correctly filter notifications by user and type', () async {
      // Arrange: Create user and send multiple notifications
      final user = User(
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

      await userRepository.create(user);

      // Send different types of notifications
      await notificationService.sendNotification(
        userId: user.id,
        title: 'Order Update',
        body: 'Your order status changed',
        type: 'order_status_update',
      );

      await notificationService.sendNotification(
        userId: user.id,
        title: 'Promotion',
        body: 'Special offer for you',
        type: 'promotion',
      );

      await notificationService.sendNotification(
        userId: user.id,
        title: 'Another Promotion',
        body: 'Another special offer',
        type: 'promotion',
      );

      // Act & Assert: Get all notifications for user
      final allNotifications = await notificationService.getUserNotifications(user.id);
      expect(allNotifications.length, equals(3));

      // Filter by type
      final orderNotifications = await notificationRepository.findByType('order_status_update');
      expect(orderNotifications.length, greaterThanOrEqualTo(1));
      expect(orderNotifications.every((n) => n.type == 'order_status_update'), isTrue);

      final promoNotifications = await notificationRepository.findByType('promotion');
      expect(promoNotifications.length, greaterThanOrEqualTo(2));
      expect(promoNotifications.every((n) => n.type == 'promotion'), isTrue);
    });

    test('should correctly handle unread notification count', () async {
      // Arrange: Create user
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

      // Send notifications
      await notificationService.sendNotification(
        userId: user.id,
        title: 'Unread 1',
        body: 'This is unread',
        type: 'test',
      );

      await notificationService.sendNotification(
        userId: user.id,
        title: 'Unread 2',
        body: 'This is also unread',
        type: 'test',
      );

      // Act: Get unread count
      var unreadCount = await notificationService.getUnreadCount(user.id);
      expect(unreadCount, equals(2));

      // Mark one as read
      final notifications = await notificationService.getUserNotifications(user.id);
      await notificationService.markAsRead(notifications.first.id, user.id);

      // Assert: Unread count should decrease
      unreadCount = await notificationService.getUnreadCount(user.id);
      expect(unreadCount, equals(1));

      // Mark all as read
      await notificationService.markAllAsRead(user.id);

      // Assert: Unread count should be zero
      unreadCount = await notificationService.getUnreadCount(user.id);
      expect(unreadCount, equals(0));
    });

    test('should send bulk notifications correctly', () async {
      // Arrange: Create multiple users
      final users = <User>[];
      for (var i = 11; i <= 13; i++) {
        final user = User(
          id: i,
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
        users.add(user);
      }

      final userIds = users.map((u) => u.id).toList();

      // Act: Send bulk notification
      final results = await notificationService.sendBulkNotification(
        userIds: userIds,
        title: 'Bulk Test',
        body: 'This is a bulk notification test',
        type: 'bulk_test',
        data: {'test_id': 'bulk_001'},
      );

      // Assert: All notifications should be sent successfully
      expect(results.length, equals(userIds.length));
      for (final userId in userIds) {
        expect(results[userId], isTrue);

        // Verify notification was created
        final userNotifications = await notificationService.getUserNotifications(userId);
        final bulkNotification = userNotifications.firstWhere(
          (n) => n.type == 'bulk_test',
          orElse: () => throw Exception('Bulk notification not found'),
        );

        expect(bulkNotification.title, equals('Bulk Test'));
        expect(bulkNotification.body, equals('This is a bulk notification test'));
        expect(bulkNotification.data!['test_id'], equals('bulk_001'));
      }
    });

    test('should handle notification cleanup correctly', () async {
      // Arrange: Create old notification (simulate old date)
      final user = User(
        id: 14,
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

      // Create notification and manually set old date
      final notification = await notificationRepository.create(CreateNotificationRequest(
        userId: user.id,
        title: 'Old Notification',
        body: 'This is old',
        type: 'test',
        data: {},
      ));

      // Manually update sent_at to old date (simulate old notification)
      final oldDate = DateTime.now().subtract(Duration(days: 40));
      await connection.execute('''
        UPDATE notifications
        SET sent_at = ?, is_read = true
        WHERE id = ?
      ''', [oldDate.toIso8601String(), notification.id]);

      // Act: Cleanup old notifications
      final deletedCount = await notificationService.cleanupOldNotifications(
        Duration(days: 30),
      );

      // Assert: Old notification should be deleted
      expect(deletedCount, greaterThanOrEqualTo(1));

      // Verify notification was deleted
      final remainingNotifications = await notificationRepository.findByUserId(user.id);
      final oldNotification = remainingNotifications.where((n) => n.id == notification.id);
      expect(oldNotification.isEmpty, isTrue);
    });

    test('should generate correct notification statistics', () async {
      // Arrange: Use existing notifications from previous tests

      // Act: Get notification statistics
      final statistics = await notificationService.getNotificationStatistics();

      // Assert: Statistics should be calculated correctly
      expect(statistics, isNotNull);
      expect(statistics['total_notifications'], isNotNull);
      expect(statistics['read_notifications'], isNotNull);
      expect(statistics['unread_notifications'], isNotNull);
      expect(statistics['unique_users_notified'], isNotNull);

      // Verify that total = read + unread
      final total = statistics['total_notifications'] as int;
      final read = statistics['read_notifications'] as int;
      final unread = statistics['unread_notifications'] as int;
      expect(total, equals(read + unread));
    });

    test('should handle notification deletion correctly', () async {
      // Arrange: Create user and notification
      final user = User(
        id: 15,
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

      final notification = await notificationRepository.create(CreateNotificationRequest(
        userId: user.id,
        title: 'Test Notification',
        body: 'Test body',
        type: 'test',
        data: {},
      ));

      // Act: Delete notification
      final deleteSuccess = await notificationService.deleteNotification(
        notification.id,
        user.id,
      );

      // Assert: Deletion should be successful
      expect(deleteSuccess, isTrue);

      // Verify notification was deleted
      final remainingNotifications = await notificationRepository.findByUserId(user.id);
      final deletedNotification = remainingNotifications.where((n) => n.id == notification.id);
      expect(deletedNotification.isEmpty, isTrue);

      // Try to delete non-existent notification
      final deleteFail = await notificationService.deleteNotification(
        99999,
        user.id,
      );
      expect(deleteFail, isFalse);
    });
  });
}
