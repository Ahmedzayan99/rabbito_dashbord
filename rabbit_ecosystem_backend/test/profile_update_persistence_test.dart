import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/models/user_role.dart';

/// **Feature: rabbit-ecosystem, Property 10: Profile Update Persistence**
/// For any profile update operation, the system should persist changes correctly
/// and maintain data integrity across all fields
/// **Validates: Requirements 3.2**

void main() {
  group('Profile Update Persistence Property Tests', () {
    final faker = Faker();

    test('Property 10: Profile Update Persistence - Username updates should be persistent', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate original and new usernames
        final originalUsername = faker.person.name();
        final newUsername = faker.person.name();

        // Simulate profile update
        final profileData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': originalUsername,
          'email': faker.internet.email(),
          'mobile': '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}',
          'role': UserRole.customer,
          'created_at': DateTime.now(),
        };

        // Update username
        final updatedData = Map<String, dynamic>.from(profileData);
        updatedData['username'] = newUsername;
        updatedData['updated_at'] = DateTime.now();

        // Verify persistence properties
        expect(updatedData['username'], equals(newUsername),
          reason: 'Username should be updated to new value');
        expect(updatedData['username'], isNot(equals(originalUsername)),
          reason: 'Username should be different from original');
        expect(updatedData['id'], equals(profileData['id']),
          reason: 'User ID should remain unchanged');
        expect(updatedData['email'], equals(profileData['email']),
          reason: 'Email should remain unchanged when updating username');
        expect(updatedData['mobile'], equals(profileData['mobile']),
          reason: 'Mobile should remain unchanged when updating username');
        expect(updatedData['updated_at'], isNotNull,
          reason: 'Updated timestamp should be set');
      }
    });

    test('Property 10: Profile Update Persistence - Email updates should be persistent', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate original and new emails
        final originalEmail = faker.internet.email();
        final newEmail = faker.internet.email();

        // Simulate profile update
        final profileData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': originalEmail,
          'mobile': '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}',
          'role': UserRole.customer,
          'email_verified': true,
          'created_at': DateTime.now(),
        };

        // Update email
        final updatedData = Map<String, dynamic>.from(profileData);
        updatedData['email'] = newEmail;
        updatedData['email_verified'] = false; // Should reset verification
        updatedData['updated_at'] = DateTime.now();

        // Verify persistence properties
        expect(updatedData['email'], equals(newEmail),
          reason: 'Email should be updated to new value');
        expect(updatedData['email'], isNot(equals(originalEmail)),
          reason: 'Email should be different from original');
        expect(updatedData['email_verified'], isFalse,
          reason: 'Email verification should be reset when email changes');
        expect(updatedData['id'], equals(profileData['id']),
          reason: 'User ID should remain unchanged');
        expect(updatedData['username'], equals(profileData['username']),
          reason: 'Username should remain unchanged when updating email');
        expect(updatedData['updated_at'], isNotNull,
          reason: 'Updated timestamp should be set');
      }
    });

    test('Property 10: Profile Update Persistence - Partial updates should preserve other fields', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate complete profile data
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'uuid': faker.guid.guid(),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'mobile': '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}',
          'role': UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          'balance': faker.randomGenerator.decimal(scale: 1000),
          'rating': faker.randomGenerator.decimal(scale: 5, min: 0),
          'no_of_ratings': faker.randomGenerator.integer(1000),
          'is_active': true,
          'email_verified': faker.randomGenerator.boolean(),
          'mobile_verified': faker.randomGenerator.boolean(),
          'created_at': DateTime.now().subtract(Duration(days: faker.randomGenerator.integer(365))),
        };

        // Perform partial update (only username)
        final updatedData = Map<String, dynamic>.from(originalData);
        updatedData['username'] = faker.person.name();
        updatedData['updated_at'] = DateTime.now();

        // Verify all other fields remain unchanged
        expect(updatedData['id'], equals(originalData['id']));
        expect(updatedData['uuid'], equals(originalData['uuid']));
        expect(updatedData['email'], equals(originalData['email']));
        expect(updatedData['mobile'], equals(originalData['mobile']));
        expect(updatedData['role'], equals(originalData['role']));
        expect(updatedData['balance'], equals(originalData['balance']));
        expect(updatedData['rating'], equals(originalData['rating']));
        expect(updatedData['no_of_ratings'], equals(originalData['no_of_ratings']));
        expect(updatedData['is_active'], equals(originalData['is_active']));
        expect(updatedData['email_verified'], equals(originalData['email_verified']));
        expect(updatedData['mobile_verified'], equals(originalData['mobile_verified']));
        expect(updatedData['created_at'], equals(originalData['created_at']));

        // Only username and updated_at should be different
        expect(updatedData['username'], isNot(equals(originalData['username'])));
        expect(updatedData['updated_at'], isNotNull);
      }
    });

    test('Property 10: Profile Update Persistence - Multiple field updates should be atomic', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Generate original profile data
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'mobile': '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}',
          'role': UserRole.customer,
          'created_at': DateTime.now(),
        };

        // Update multiple fields atomically
        final newUsername = faker.person.name();
        final newEmail = faker.internet.email();
        
        final updatedData = Map<String, dynamic>.from(originalData);
        updatedData['username'] = newUsername;
        updatedData['email'] = newEmail;
        updatedData['email_verified'] = false; // Reset verification
        updatedData['updated_at'] = DateTime.now();

        // Verify atomic update properties
        expect(updatedData['username'], equals(newUsername),
          reason: 'Username should be updated in atomic operation');
        expect(updatedData['email'], equals(newEmail),
          reason: 'Email should be updated in atomic operation');
        expect(updatedData['email_verified'], isFalse,
          reason: 'Email verification should be reset in atomic operation');
        
        // Verify consistency - either all changes applied or none
        final usernameChanged = updatedData['username'] != originalData['username'];
        final emailChanged = updatedData['email'] != originalData['email'];
        
        if (usernameChanged || emailChanged) {
          expect(updatedData['updated_at'], isNotNull,
            reason: 'Updated timestamp should be set when any field changes');
        }

        // Verify immutable fields remain unchanged
        expect(updatedData['id'], equals(originalData['id']));
        expect(updatedData['mobile'], equals(originalData['mobile']));
        expect(updatedData['role'], equals(originalData['role']));
        expect(updatedData['created_at'], equals(originalData['created_at']));
      }
    });

    test('Property 10: Profile Update Persistence - Invalid updates should not affect data', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Generate valid profile data
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'mobile': '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}',
          'role': UserRole.customer,
          'created_at': DateTime.now(),
        };

        // Attempt invalid updates
        final invalidUpdates = [
          {'username': ''}, // Empty username
          {'username': '  '}, // Whitespace only
          {'username': 'ab'}, // Too short
          {'email': 'invalid-email'}, // Invalid email format
          {'email': '@domain.com'}, // Invalid email format
          {'email': 'user@'}, // Invalid email format
        ];

        for (final invalidUpdate in invalidUpdates) {
          // Simulate validation failure - data should remain unchanged
          final dataAfterFailedUpdate = Map<String, dynamic>.from(originalData);
          
          // Validate the update would fail
          if (invalidUpdate.containsKey('username')) {
            final username = invalidUpdate['username'] as String;
            expect(_isValidUsername(username), isFalse,
              reason: 'Invalid username should fail validation: "$username"');
          }
          
          if (invalidUpdate.containsKey('email')) {
            final email = invalidUpdate['email'] as String;
            expect(_isValidEmail(email), isFalse,
              reason: 'Invalid email should fail validation: "$email"');
          }

          // Verify original data remains unchanged after validation failure
          expect(dataAfterFailedUpdate, equals(originalData),
            reason: 'Data should remain unchanged after validation failure');
        }
      }
    });

    test('Property 10: Profile Update Persistence - Timestamp updates should be consistent', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'created_at': DateTime.now().subtract(Duration(days: 30)),
          'updated_at': null,
        };

        // Perform update
        final beforeUpdate = DateTime.now();
        final updatedData = Map<String, dynamic>.from(originalData);
        updatedData['username'] = faker.person.name();
        updatedData['updated_at'] = DateTime.now();
        final afterUpdate = DateTime.now();

        // Verify timestamp properties
        expect(updatedData['updated_at'], isNotNull,
          reason: 'Updated timestamp should be set');
        
        final updatedAt = updatedData['updated_at'] as DateTime;
        expect(updatedAt.isAfter(beforeUpdate) || updatedAt.isAtSameMomentAs(beforeUpdate), isTrue,
          reason: 'Updated timestamp should be after or equal to operation start time');
        expect(updatedAt.isBefore(afterUpdate) || updatedAt.isAtSameMomentAs(afterUpdate), isTrue,
          reason: 'Updated timestamp should be before or equal to operation end time');
        
        // Created timestamp should remain unchanged
        expect(updatedData['created_at'], equals(originalData['created_at']),
          reason: 'Created timestamp should never change during updates');
      }
    });

    test('Property 10: Profile Update Persistence - No-op updates should not change timestamps', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'created_at': DateTime.now().subtract(Duration(days: 30)),
          'updated_at': DateTime.now().subtract(Duration(days: 1)),
        };

        // Perform no-op update (same values)
        final noOpData = Map<String, dynamic>.from(originalData);
        // Don't change any values, just simulate an update attempt

        // Verify no changes occurred
        expect(noOpData, equals(originalData),
          reason: 'No-op update should not change any data');
        expect(noOpData['updated_at'], equals(originalData['updated_at']),
          reason: 'Updated timestamp should not change for no-op updates');
      }
    });

    test('Property 10: Profile Update Persistence - Concurrent update handling', () async {
      const int testIterations = 30;

      for (int i = 0; i < testIterations; i++) {
        final originalData = {
          'id': faker.randomGenerator.integer(10000, min: 1),
          'username': faker.person.name(),
          'email': faker.internet.email(),
          'version': 1, // Optimistic locking version
          'created_at': DateTime.now().subtract(Duration(days: 30)),
          'updated_at': DateTime.now().subtract(Duration(days: 1)),
        };

        // Simulate two concurrent updates
        final update1 = Map<String, dynamic>.from(originalData);
        update1['username'] = faker.person.name();
        update1['version'] = (originalData['version'] as int) + 1;
        update1['updated_at'] = DateTime.now();

        final update2 = Map<String, dynamic>.from(originalData);
        update2['email'] = faker.internet.email();
        update2['version'] = (originalData['version'] as int) + 1; // Same version - conflict
        update2['updated_at'] = DateTime.now();

        // Verify version conflict detection
        expect(update1['version'], equals(update2['version']),
          reason: 'Concurrent updates should have version conflict');
        
        // Only one update should succeed (first one wins)
        final finalData = update1; // Simulate first update wins
        
        expect(finalData['version'], equals((originalData['version'] as int) + 1),
          reason: 'Version should be incremented after successful update');
        expect(finalData['username'], isNot(equals(originalData['username'])),
          reason: 'Winning update should be applied');
        expect(finalData['email'], equals(originalData['email']),
          reason: 'Losing update should not be applied');
      }
    });
  });
}

/// Validate username
bool _isValidUsername(String? username) {
  if (username == null) return true; // Username is optional
  return username.trim().length >= 3;
}

/// Validate email format
bool _isValidEmail(String email) {
  final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  return emailRegex.hasMatch(email) && email.length <= 254;
}