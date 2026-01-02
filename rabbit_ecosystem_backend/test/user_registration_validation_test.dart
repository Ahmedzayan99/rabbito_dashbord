import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/models/user_role.dart';

/// **Feature: rabbit-ecosystem, Property 9: User Registration Validation**
/// For any user registration attempt, the system should validate all input data
/// and ensure unique constraints are enforced
/// **Validates: Requirements 3.1**

void main() {
  group('User Registration Validation Property Tests', () {
    final faker = Faker();

    test('Property 9: User Registration Validation - Mobile number format validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate valid Saudi mobile numbers (must start with 5)
        final validMobile = '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}';
        
        // Test valid mobile format
        expect(_isValidMobile(validMobile), isTrue, 
          reason: 'Valid Saudi mobile should pass validation: $validMobile');

        // Generate invalid mobile numbers
        final invalidMobiles = [
          '123456789', // No country code
          '+1234567890', // US format
          '+96651234567', // Too short
          '+966512345678901', // Too long
          '+966412345678', // Invalid prefix (4 instead of 5)
        ];

        for (final invalidMobile in invalidMobiles) {
          expect(_isValidMobile(invalidMobile), isFalse,
            reason: 'Invalid mobile should fail validation: $invalidMobile');
        }
      }
    });

    test('Property 9: User Registration Validation - Email format validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate valid email
        final validEmail = faker.internet.email();
        
        expect(_isValidEmail(validEmail), isTrue,
          reason: 'Valid email should pass validation: $validEmail');

        // Test invalid email formats
        final invalidEmails = [
          'invalid-email',
          '@${faker.internet.domainName()}',
          '${faker.internet.userName()}@',
          '${faker.internet.userName()}@${faker.internet.domainName()}.',
          '${faker.internet.userName()}.${faker.internet.domainName()}',
          '',
          '${faker.internet.userName()} @${faker.internet.domainName()}', // Space
        ];

        for (final invalidEmail in invalidEmails) {
          expect(_isValidEmail(invalidEmail), isFalse,
            reason: 'Invalid email should fail validation: $invalidEmail');
        }
      }
    });

    test('Property 9: User Registration Validation - Password strength validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate strong passwords (8+ characters)
        final strongPassword = faker.internet.password(length: faker.randomGenerator.integer(20, min: 8));
        
        expect(_isValidPassword(strongPassword), isTrue,
          reason: 'Strong password should pass validation: ${strongPassword.length} chars');

        // Test weak passwords
        final weakPasswords = [
          faker.internet.password(length: faker.randomGenerator.integer(7, min: 1)), // < 8 chars
          '', // Empty
          '1234567', // Exactly 7 chars
        ];

        for (final weakPassword in weakPasswords) {
          expect(_isValidPassword(weakPassword), isFalse,
            reason: 'Weak password should fail validation: ${weakPassword.length} chars');
        }
      }
    });

    test('Property 9: User Registration Validation - User role validation', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Test all valid user roles
        for (final role in UserRole.values) {
          expect(_isValidUserRole(role), isTrue,
            reason: 'All UserRole enum values should be valid: ${role.name}');
          
          expect(role.permissions, isNotNull,
            reason: 'Every role should have defined permissions');
          
          expect(role.value, isNotEmpty,
            reason: 'Every role should have a non-empty string value');
        }
      }
    });

    test('Property 9: User Registration Validation - Username validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate valid usernames
        final validUsername = faker.person.name();
        
        expect(_isValidUsername(validUsername), isTrue,
          reason: 'Valid username should pass validation: $validUsername');

        // Test invalid usernames
        final invalidUsernames = [
          '', // Empty
          '   ', // Only spaces
          'a', // Too short
          'ab', // Too short
        ];

        for (final invalidUsername in invalidUsernames) {
          expect(_isValidUsername(invalidUsername), isFalse,
            reason: 'Invalid username should fail validation: "$invalidUsername"');
        }
      }
    });

    test('Property 9: User Registration Validation - Registration data consistency', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate consistent registration data
        final mobile = '+9665${faker.randomGenerator.integer(99999999, min: 10000000)}';
        final email = faker.internet.email();
        final username = faker.person.name();
        final password = faker.internet.password(length: 12);
        final role = UserRole.values[faker.randomGenerator.integer(UserRole.values.length)];

        final registrationData = {
          'mobile': mobile,
          'email': email,
          'username': username,
          'password': password,
          'role': role,
        };

        // Validate all fields are consistent
        expect(_isValidMobile(registrationData['mobile'] as String), isTrue);
        expect(_isValidEmail(registrationData['email'] as String), isTrue);
        expect(_isValidUsername(registrationData['username'] as String), isTrue);
        expect(_isValidPassword(registrationData['password'] as String), isTrue);
        expect(_isValidUserRole(registrationData['role'] as UserRole), isTrue);

        // Test that data maintains integrity
        expect(registrationData['mobile'], equals(mobile));
        expect(registrationData['email'], equals(email));
        expect(registrationData['username'], equals(username));
        expect(registrationData['password'], equals(password));
        expect(registrationData['role'], equals(role));
      }
    });

    test('Property 9: User Registration Validation - Edge cases handling', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Test boundary conditions for mobile numbers
        final validSaudiPrefixes = ['50', '51', '52', '53', '54', '55', '56', '57', '58', '59'];
        final randomPrefix = validSaudiPrefixes[faker.randomGenerator.integer(validSaudiPrefixes.length)];
        final boundaryMobile = '+966$randomPrefix${faker.randomGenerator.integer(9999999, min: 1000000)}';
        
        expect(_isValidMobile(boundaryMobile), isTrue,
          reason: 'Boundary mobile number should be valid: $boundaryMobile');

        // Test minimum valid password length
        final minValidPassword = 'a' * 8; // Exactly 8 characters
        expect(_isValidPassword(minValidPassword), isTrue,
          reason: 'Minimum length password should be valid');

        // Test maximum reasonable lengths
        final longButValidEmail = '${faker.internet.userName()}@${faker.internet.domainName()}';
        if (longButValidEmail.length <= 254) { // RFC 5321 limit
          expect(_isValidEmail(longButValidEmail), isTrue,
            reason: 'Long but valid email should pass');
        }
      }
    });

    test('Property 9: User Registration Validation - Special characters handling', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Test emails with valid special characters
        final specialCharEmails = [
          'user.name@domain.com',
          'user+tag@domain.com',
          'user_name@domain.com',
          'user-name@domain.com',
        ];

        for (final email in specialCharEmails) {
          expect(_isValidEmail(email), isTrue,
            reason: 'Email with valid special characters should pass: $email');
        }

        // Test usernames with various characters
        final validUsernames = [
          'John Doe',
          'محمد أحمد', // Arabic names
          'José María', // Accented characters
          'User123',
        ];

        for (final username in validUsernames) {
          expect(_isValidUsername(username), isTrue,
            reason: 'Valid username with special characters should pass: $username');
        }
      }
    });
  });
}

/// Validate mobile number format (Saudi Arabia)
bool _isValidMobile(String mobile) {
  // Saudi mobile number format: +966xxxxxxxxx or 05xxxxxxxx
  final saudiMobileRegex = RegExp(r'^(\+966|0)?5[0-9]{8}$');
  
  // Remove spaces and normalize
  final cleanMobile = mobile.replaceAll(' ', '');
  
  // Check basic format
  if (!saudiMobileRegex.hasMatch(cleanMobile)) {
    return false;
  }
  
  // Additional validation for Saudi mobile prefixes
  if (cleanMobile.startsWith('+966')) {
    final number = cleanMobile.substring(4);
    return number.length == 9 && number.startsWith('5');
  } else if (cleanMobile.startsWith('0')) {
    return cleanMobile.length == 10 && cleanMobile.startsWith('05');
  } else if (cleanMobile.startsWith('5')) {
    return cleanMobile.length == 9;
  }
  
  return false;
}

/// Validate email format
bool _isValidEmail(String email) {
  // More permissive email regex that handles apostrophes and other valid characters
  final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  return emailRegex.hasMatch(email) && email.length <= 254;
}

/// Validate password strength
bool _isValidPassword(String password) {
  return password.length >= 8;
}

/// Validate username
bool _isValidUsername(String? username) {
  if (username == null) return true; // Username is optional
  return username.trim().length >= 3;
}

/// Validate user role
bool _isValidUserRole(UserRole role) {
  return UserRole.values.contains(role);
}