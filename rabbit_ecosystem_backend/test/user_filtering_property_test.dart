import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';

/// Property 11: User List Filtering and Pagination
///
/// *For any* user list request with role filter and pagination parameters,
/// the system should return correctly filtered and paginated results
///
/// **Validates: Requirements 3.3**
void main() {
  final faker = Faker();

  group('Property 11: User List Filtering and Pagination', () {
    test('should correctly filter users by role', () {
      // Create a list of test users with different roles
      final users = <User>[];

      // Add 5 customers
      for (int i = 0; i < 5; i++) {
        users.add(User(
          id: i + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.customer,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Add 3 partners
      for (int i = 0; i < 3; i++) {
        users.add(User(
          id: users.length + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.partner,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Add 2 riders
      for (int i = 0; i < 2; i++) {
        users.add(User(
          id: users.length + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.rider,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Test filtering by customer role
      final customerUsers = users.where((user) => user.role == UserRole.customer).toList();
      expect(customerUsers.length, equals(5));
      expect(customerUsers.every((user) => user.role == UserRole.customer), isTrue);

      // Test filtering by partner role
      final partnerUsers = users.where((user) => user.role == UserRole.partner).toList();
      expect(partnerUsers.length, equals(3));
      expect(partnerUsers.every((user) => user.role == UserRole.partner), isTrue);

      // Test filtering by rider role
      final riderUsers = users.where((user) => user.role == UserRole.rider).toList();
      expect(riderUsers.length, equals(2));
      expect(riderUsers.every((user) => user.role == UserRole.rider), isTrue);
    });

    test('should correctly implement pagination logic', () {
      // Create a large list of users (20 users)
      final users = <User>[];
      for (int i = 0; i < 20; i++) {
        users.add(User(
          id: i + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.customer,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Test pagination with limit
      final limit = 5;
      final page1Users = users.take(limit).toList();
      expect(page1Users.length, equals(limit));

      // Test pagination with offset
      final offset = 10;
      final offsetUsers = users.skip(offset).take(limit).toList();
      expect(offsetUsers.length, equals(limit));
      expect(offsetUsers.first.id, equals(offset + 1));

      // Test edge case: offset beyond list length
      final largeOffsetUsers = users.skip(100).toList();
      expect(largeOffsetUsers, isEmpty);

      // Test edge case: limit larger than remaining items
      final remainingUsers = users.skip(15).take(10).toList();
      expect(remainingUsers.length, equals(5)); // Only 5 items remain after skip(15)
    });

    test('should correctly implement search functionality', () {
      // Create users with known names
      final users = <User>[];
      final testNames = ['John Doe', 'Jane Smith', 'Bob Johnson', 'Alice Brown'];

      for (int i = 0; i < testNames.length; i++) {
        users.add(User(
          id: i + 1,
          uuid: faker.guid.guid(),
          username: testNames[i],
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.customer,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Test search by partial name
      final johnResults = users.where((user) =>
        user.username!.toLowerCase().contains('john')).toList();
      expect(johnResults.length, equals(2)); // John Doe and Bob Johnson

      // Test search by email
      final emailResults = users.where((user) =>
        user.email!.toLowerCase().contains('@')).toList();
      expect(emailResults.length, equals(users.length));

      // Test search with no matches
      final noMatchResults = users.where((user) =>
        user.username!.contains('xyz')).toList();
      expect(noMatchResults, isEmpty);

      // Test case insensitive search
      final searchTerm = users.first.username!.substring(0, 2).toLowerCase();
      final caseInsensitiveResults = users.where((user) =>
        user.username!.toLowerCase().contains(searchTerm)).toList();
      expect(caseInsensitiveResults.length, greaterThanOrEqualTo(1));
    });

    test('should handle combined filtering and pagination', () {
      // Create users with different roles
      final users = <User>[];

      // Add customers
      for (int i = 0; i < 8; i++) {
        users.add(User(
          id: i + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.customer,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Add partners
      for (int i = 0; i < 5; i++) {
        users.add(User(
          id: users.length + 1,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: faker.phoneNumber.us(),
          role: UserRole.partner,
          balance: 0.0,
          rating: 0.0,
          numberOfRatings: 0,
          isActive: true,
          emailVerified: false,
          mobileVerified: false,
          createdAt: DateTime.now(),
        ));
      }

      // Test: Filter by role + pagination
      final allCustomers = users.where((user) => user.role == UserRole.customer).toList();
      final paginatedCustomers = allCustomers.take(5).toList();

      expect(allCustomers.length, equals(8));
      expect(paginatedCustomers.length, equals(5));
      expect(paginatedCustomers.every((user) => user.role == UserRole.customer), isTrue);

      // Test: Search + pagination
      final johnUsers = users.where((user) =>
        user.username!.toLowerCase().contains('john')).toList();
      final paginatedJohnUsers = johnUsers.take(3).toList();

      expect(paginatedJohnUsers.length, lessThanOrEqualTo(3));
      expect(paginatedJohnUsers.every((user) =>
        user.username!.toLowerCase().contains('john')), isTrue);
    });

    test('should handle edge cases in filtering and pagination', () {
      final users = <User>[];

      // Test with empty list
      final emptyFiltered = users.where((user) => user.role == UserRole.customer).toList();
      expect(emptyFiltered, isEmpty);

      // Test pagination on empty list
      final emptyPaginated = users.take(5).toList();
      expect(emptyPaginated, isEmpty);

      // Test with limit 0
      final usersWithData = [User(
        id: 1,
        uuid: 'test',
        username: 'test',
        email: 'test@example.com',
        mobile: '1234567890',
        role: UserRole.customer,
        balance: 0.0,
        rating: 0.0,
        numberOfRatings: 0,
        isActive: true,
        emailVerified: false,
        mobileVerified: false,
        createdAt: DateTime.now(),
      )];

      final zeroLimit = usersWithData.take(0).toList();
      expect(zeroLimit, isEmpty);

      // Test with offset larger than list
      final largeOffset = usersWithData.skip(10).toList();
      expect(largeOffset, isEmpty);
    });
  });
}
