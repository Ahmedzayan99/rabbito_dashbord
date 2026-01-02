import 'package:test/test.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';
import '../lib/src/models/address.dart';
import '../lib/src/models/category.dart';
import '../lib/src/models/notification.dart';

void main() {
  group('User Model Tests', () {
    test('User creation and basic properties', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        username: 'john_doe',
        email: 'john@example.com',
        mobile: '+1234567890',
        role: UserRole.customer,
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(user.id, equals(1));
      expect(user.uuid, equals('test-uuid-123'));
      expect(user.username, equals('john_doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.mobile, equals('+1234567890'));
      expect(user.role, equals(UserRole.customer));
      expect(user.isActive, isTrue);
      expect(user.balance, equals(0.0));
      expect(user.rating, equals(0.0));
      expect(user.numberOfRatings, equals(0));
    });

    test('User fromMap', () {
      final map = {
        'id': 1,
        'uuid': 'test-uuid-123',
        'username': 'jane_doe',
        'email': 'jane@example.com',
        'mobile': '+0987654321',
        'role': 'partner',
        'balance': 100.50,
        'rating': 4.5,
        'no_of_ratings': 10,
        'is_active': true,
        'email_verified': true,
        'mobile_verified': false,
        'last_login': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': null,
      };

      final user = User.fromMap(map);

      expect(user.id, equals(1));
      expect(user.uuid, equals('test-uuid-123'));
      expect(user.username, equals('jane_doe'));
      expect(user.email, equals('jane@example.com'));
      expect(user.mobile, equals('+0987654321'));
      expect(user.role, equals(UserRole.partner));
      expect(user.balance, equals(100.50));
      expect(user.rating, equals(4.5));
      expect(user.numberOfRatings, equals(10));
      expect(user.isActive, isTrue);
      expect(user.emailVerified, isTrue);
      expect(user.mobileVerified, isFalse);
    });

    test('User copyWith', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        username: 'john_doe',
        email: 'john@example.com',
        mobile: '+1234567890',
        role: UserRole.customer,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(
        username: 'john_smith',
        isActive: false,
        balance: 50.0,
      );

      expect(updatedUser.id, equals(user.id));
      expect(updatedUser.uuid, equals(user.uuid));
      expect(updatedUser.username, equals('john_smith'));
      expect(updatedUser.email, equals(user.email));
      expect(updatedUser.isActive, isFalse);
      expect(updatedUser.balance, equals(50.0));
    });

    test('User equality', () {
      final user1 = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+1234567890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      final user2 = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+0987654321',
        role: UserRole.partner,
        createdAt: DateTime.now(),
      );

      expect(user1, equals(user2)); // Same id and uuid
    });
  });

  group('Address Model Tests', () {
    test('Address creation and serialization', () {
      final address = Address(
        id: 1,
        userId: 1,
        title: 'Home',
        address: '123 Main St',
        landmark: 'Near Park',
        latitude: 40.7128,
        longitude: -74.0060,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final json = address.toJson();
      final fromJson = Address.fromJson(json);

      expect(fromJson.id, equals(address.id));
      expect(fromJson.userId, equals(address.userId));
      expect(fromJson.title, equals(address.title));
      expect(fromJson.address, equals(address.address));
      expect(fromJson.landmark, equals(address.landmark));
      expect(fromJson.latitude, equals(address.latitude));
      expect(fromJson.longitude, equals(address.longitude));
      expect(fromJson.isDefault, equals(address.isDefault));
    });

    test('Address fromMap', () {
      final map = {
        'id': 1,
        'user_id': 1,
        'title': 'Work',
        'address': '456 Office Blvd',
        'landmark': null,
        'latitude': 40.7589,
        'longitude': -73.9851,
        'is_default': false,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': null,
      };

      final address = Address.fromMap(map);

      expect(address.id, equals(1));
      expect(address.userId, equals(1));
      expect(address.title, equals('Work'));
      expect(address.address, equals('456 Office Blvd'));
      expect(address.landmark, isNull);
      expect(address.latitude, equals(40.7589));
      expect(address.longitude, equals(-73.9851));
      expect(address.isDefault, isFalse);
    });

    test('Address coordinates validation', () {
      final address = Address(
        id: 1,
        userId: 1,
        title: 'Home',
        address: '123 Main St',
        latitude: 40.7128,
        longitude: -74.0060,
        createdAt: DateTime.now(),
      );

      expect(address.latitude, greaterThanOrEqualTo(-90));
      expect(address.latitude, lessThanOrEqualTo(90));
      expect(address.longitude, greaterThanOrEqualTo(-180));
      expect(address.longitude, lessThanOrEqualTo(180));
    });
  });

  group('Category Model Tests', () {
    test('Category creation and serialization', () {
      final category = Category(
        id: 1,
        name: 'Fast Food',
        description: 'Quick service restaurants',
        image: 'fastfood.jpg',
        isActive: true,
        sortOrder: 1,
        createdAt: DateTime.now(),
      );

      final json = category.toJson();
      final fromJson = Category.fromJson(json);

      expect(fromJson.id, equals(category.id));
      expect(fromJson.name, equals(category.name));
      expect(fromJson.description, equals(category.description));
      expect(fromJson.image, equals(category.image));
      expect(fromJson.isActive, equals(category.isActive));
      expect(fromJson.sortOrder, equals(category.sortOrder));
    });

    test('Category fromMap', () {
      final map = {
        'id': 2,
        'name': 'Beverages',
        'description': 'Drinks and beverages',
        'image': null,
        'is_active': true,
        'sort_order': 2,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': null,
      };

      final category = Category.fromMap(map);

      expect(category.id, equals(2));
      expect(category.name, equals('Beverages'));
      expect(category.description, equals('Drinks and beverages'));
      expect(category.image, isNull);
      expect(category.isActive, isTrue);
      expect(category.sortOrder, equals(2));
    });

    test('Category copyWith', () {
      final category = Category(
        id: 1,
        name: 'Fast Food',
        isActive: true,
        sortOrder: 1,
        createdAt: DateTime.now(),
      );

      final updatedCategory = category.copyWith(
        name: 'Quick Service',
        isActive: false,
      );

      expect(updatedCategory.id, equals(category.id));
      expect(updatedCategory.name, equals('Quick Service'));
      expect(updatedCategory.isActive, isFalse);
      expect(updatedCategory.sortOrder, equals(category.sortOrder));
    });
  });

  group('Notification Model Tests', () {
    test('Notification creation and serialization', () {
      final notification = Notification(
        id: 1,
        userId: 1,
        title: 'Order Update',
        message: 'Your order is ready',
        type: NotificationType.orderUpdate,
        status: NotificationStatus.sent,
        data: {'orderId': 123},
        createdAt: DateTime.now(),
      );

      final json = notification.toJson();
      final fromJson = Notification.fromJson(json);

      expect(fromJson.id, equals(notification.id));
      expect(fromJson.userId, equals(notification.userId));
      expect(fromJson.title, equals(notification.title));
      expect(fromJson.message, equals(notification.message));
      expect(fromJson.type, equals(notification.type));
      expect(fromJson.status, equals(notification.status));
    });

    test('Notification read status', () {
      final unreadNotification = Notification(
        id: 1,
        title: 'Test',
        message: 'Test message',
        type: NotificationType.general,
        createdAt: DateTime.now(),
      );

      expect(unreadNotification.isUnread, isTrue);
      expect(unreadNotification.isRead, isFalse);

      final readNotification = unreadNotification.copyWith(
        readAt: DateTime.now(),
      );

      expect(readNotification.isRead, isTrue);
      expect(readNotification.isUnread, isFalse);
    });

    test('Notification fromMap', () {
      final map = {
        'id': 1,
        'user_id': 1,
        'title': 'System Alert',
        'message': 'System maintenance scheduled',
        'type': 'system',
        'status': 'sent',
        'data': null,
        'read_at': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': null,
      };

      final notification = Notification.fromMap(map);

      expect(notification.id, equals(1));
      expect(notification.userId, equals(1));
      expect(notification.title, equals('System Alert'));
      expect(notification.message, equals('System maintenance scheduled'));
      expect(notification.type, equals(NotificationType.system));
      expect(notification.status, equals(NotificationStatus.sent));
      expect(notification.data, isNull);
      expect(notification.readAt, isNull);
    });
  });

  group('Model Validation Tests', () {
    test('User mobile validation', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+1234567890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      expect(user.mobile, startsWith('+'));
      expect(user.mobile.length, greaterThan(5));
    });

    test('User balance validation', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+1234567890',
        role: UserRole.customer,
        balance: 100.50,
        createdAt: DateTime.now(),
      );

      expect(user.balance, greaterThanOrEqualTo(0));
    });

    test('User rating validation', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+1234567890',
        role: UserRole.customer,
        rating: 4.2,
        numberOfRatings: 50,
        createdAt: DateTime.now(),
      );

      expect(user.rating, greaterThanOrEqualTo(0));
      expect(user.rating, lessThanOrEqualTo(5));
      expect(user.numberOfRatings, greaterThanOrEqualTo(0));
    });

    test('Address coordinates validation', () {
      final address = Address(
        id: 1,
        userId: 1,
        title: 'Home',
        address: '123 Main St',
        latitude: 40.7128,
        longitude: -74.0060,
        createdAt: DateTime.now(),
      );

      expect(address.latitude, greaterThanOrEqualTo(-90));
      expect(address.latitude, lessThanOrEqualTo(90));
      expect(address.longitude, greaterThanOrEqualTo(-180));
      expect(address.longitude, lessThanOrEqualTo(180));
    });
  });

  group('Auth Models Tests', () {
    test('CreateUserRequest validation', () {
      final request = CreateUserRequest(
        username: 'john_doe',
        email: 'john@example.com',
        mobile: '+1234567890',
        password: 'securePassword123',
        role: UserRole.customer,
      );

      expect(request.username, equals('john_doe'));
      expect(request.email, equals('john@example.com'));
      expect(request.mobile, equals('+1234567890'));
      expect(request.password, equals('securePassword123'));
      expect(request.role, equals(UserRole.customer));
    });

    test('LoginRequest validation', () {
      final request = LoginRequest(
        mobile: '+1234567890',
        password: 'securePassword123',
      );

      expect(request.mobile, equals('+1234567890'));
      expect(request.password, equals('securePassword123'));
    });

    test('AuthResponse success', () {
      final user = User(
        id: 1,
        uuid: 'test-uuid-123',
        mobile: '+1234567890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      final response = AuthResponse.success(
        accessToken: 'access-token-123',
        refreshToken: 'refresh-token-123',
        user: user,
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        message: 'Login successful',
      );

      expect(response.success, isTrue);
      expect(response.accessToken, equals('access-token-123'));
      expect(response.refreshToken, equals('refresh-token-123'));
      expect(response.user, equals(user));
      expect(response.message, equals('Login successful'));
    });

    test('AuthResponse error', () {
      final response = AuthResponse.error('Invalid credentials');

      expect(response.success, isFalse);
      expect(response.message, equals('Invalid credentials'));
      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.user, isNull);
    });
  });
}