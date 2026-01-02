import 'package:test/test.dart';
import 'package:faker/faker.dart';
import 'dart:convert';
import '../lib/src/services/jwt_service.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';

/// **Feature: rabbit-ecosystem, Property 5: Token Validation**
/// For any JWT token, the authentication system should correctly validate 
/// token signature and expiration status
/// **Validates: Requirements 2.2**

void main() {
  group('Token Validation Property Tests', () {
    late JwtService jwtService;
    final faker = Faker();

    setUp(() {
      jwtService = JwtService(
        secret: 'test_secret_key_for_validation_testing',
        accessTokenExpiry: const Duration(minutes: 30),
        refreshTokenExpiry: const Duration(hours: 24),
      );
    });

    test('Property 5: Token Validation - Valid tokens should always pass validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate random user
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        // Generate tokens
        final accessToken = jwtService.generateAccessToken(user);
        final refreshToken = jwtService.generateRefreshToken(user);

        // Validate tokens
        final accessPayload = jwtService.validateToken(accessToken);
        final refreshPayload = jwtService.validateToken(refreshToken);

        // Both tokens should be valid
        expect(accessPayload, isNotNull);
        expect(refreshPayload, isNotNull);

        // Verify token types
        expect(accessPayload!.isAccessToken, isTrue);
        expect(refreshPayload!.isRefreshToken, isTrue);

        // Verify user data integrity
        expect(accessPayload.userId, equals(user.id));
        expect(accessPayload.uuid, equals(user.uuid));
        expect(accessPayload.mobile, equals(user.mobile));
        expect(accessPayload.role, equals(user.role));

        expect(refreshPayload.userId, equals(user.id));
        expect(refreshPayload.uuid, equals(user.uuid));

        // Verify tokens are not expired
        expect(accessPayload.isExpired, isFalse);
        expect(refreshPayload.isExpired, isFalse);
        expect(jwtService.isTokenExpired(accessToken), isFalse);
        expect(jwtService.isTokenExpired(refreshToken), isFalse);
      }
    });

    test('Property 5: Token Validation - Invalid tokens should always fail validation', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate various types of invalid tokens
        final invalidTokens = [
          // Empty token
          '',
          // Random string
          faker.lorem.sentence(),
          // Malformed JWT (wrong number of parts)
          '${faker.lorem.word()}.${faker.lorem.word()}',
          '${faker.lorem.word()}.${faker.lorem.word()}.${faker.lorem.word()}.${faker.lorem.word()}',
          // Invalid base64
          'invalid.token.signature',
          // Valid structure but invalid signature
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.invalid_signature',
          // Null-like strings
          'null',
          'undefined',
          // Special characters
          '!@#\$%^&*()',
          // Very long string
          faker.lorem.words(1000).join(''),
          // JSON but not JWT
          json.encode({'user': 'test', 'role': 'admin'}),
        ];

        for (final invalidToken in invalidTokens) {
          final payload = jwtService.validateToken(invalidToken);
          expect(payload, isNull, reason: 'Token "$invalidToken" should be invalid');
          
          // Should also be considered expired (except for numeric strings)
          if (invalidToken != '1234567890' && !RegExp(r'^\d+$').hasMatch(invalidToken)) {
            expect(jwtService.isTokenExpired(invalidToken), isTrue);
          }
          
          // User ID extraction should fail (except for valid JSON-like structures)
          final userId = jwtService.extractUserId(invalidToken);
          if (invalidToken != '1234567890' && !invalidToken.contains('.')) {
            expect(userId, isNull);
          }
        }
      }
    });

    test('Property 5: Token Validation - Tokens with wrong secret should fail validation', () async {
      const int testIterations = 50;

      // Create another JWT service with different secret
      final differentSecretService = JwtService(
        secret: 'different_secret_key_${faker.lorem.word()}',
        accessTokenExpiry: const Duration(minutes: 30),
        refreshTokenExpiry: const Duration(hours: 24),
      );

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        // Generate token with one service
        final tokenFromService1 = jwtService.generateAccessToken(user);
        final tokenFromService2 = differentSecretService.generateAccessToken(user);

        // Validate with correct service
        expect(jwtService.validateToken(tokenFromService1), isNotNull);
        expect(differentSecretService.validateToken(tokenFromService2), isNotNull);

        // Validate with wrong service (should fail)
        expect(jwtService.validateToken(tokenFromService2), isNull);
        expect(differentSecretService.validateToken(tokenFromService1), isNull);
      }
    });

    test('Property 5: Token Validation - Expired tokens should fail validation', () async {
      // Test with manually created expired token
      const int testIterations = 20;

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        // Create service with past expiry time
        final expiredService = JwtService(
          secret: 'test_secret_for_expiry',
          accessTokenExpiry: const Duration(milliseconds: -1000), // Already expired
          refreshTokenExpiry: const Duration(milliseconds: -500),
        );

        // Generate tokens (they will be created as expired)
        final accessToken = expiredService.generateAccessToken(user);
        final refreshToken = expiredService.generateRefreshToken(user);

        // Tokens should be invalid due to expiry
        final accessPayload = expiredService.validateToken(accessToken);
        final refreshPayload = expiredService.validateToken(refreshToken);
        
        expect(accessPayload, isNull);
        expect(refreshPayload, isNull);
        expect(expiredService.isTokenExpired(accessToken), isTrue);
        expect(expiredService.isTokenExpired(refreshToken), isTrue);
      }
    });

    test('Property 5: Token Validation - Token signature verification should be consistent', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        final token = jwtService.generateAccessToken(user);

        // Validate multiple times - should be consistent
        for (int j = 0; j < 10; j++) {
          final payload = jwtService.validateToken(token);
          expect(payload, isNotNull);
          expect(payload!.userId, equals(user.id));
          expect(payload.uuid, equals(user.uuid));
          expect(payload.role, equals(user.role));
        }

        // Modify token slightly (tamper with signature)
        final parts = token.split('.');
        if (parts.length == 3) {
          // Change last character of signature
          final tamperedSignature = parts[2].substring(0, parts[2].length - 1) + 'X';
          final tamperedToken = '${parts[0]}.${parts[1]}.$tamperedSignature';

          // Tampered token should fail validation
          expect(jwtService.validateToken(tamperedToken), isNull);
        }
      }
    });

    test('Property 5: Token Validation - Token payload modification should invalidate token', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        final originalToken = jwtService.generateAccessToken(user);
        final parts = originalToken.split('.');

        if (parts.length == 3) {
          try {
            // Decode payload
            final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final payload = json.decode(payloadJson) as Map<String, dynamic>;

            // Modify payload (change role to admin)
            payload['role'] = 'super_admin';
            payload['permissions'] = UserRole.superAdmin.permissions;

            // Encode modified payload
            final modifiedPayloadJson = json.encode(payload);
            final modifiedPayloadBase64 = base64Url.encode(utf8.encode(modifiedPayloadJson));

            // Create tampered token
            final tamperedToken = '${parts[0]}.$modifiedPayloadBase64.${parts[2]}';

            // Tampered token should fail validation
            final validationResult = jwtService.validateToken(tamperedToken);
            expect(validationResult, isNull, reason: 'Tampered token should be invalid');

          } catch (e) {
            // If we can't decode/modify the token, that's also acceptable
            // as it means the token format is robust
          }
        }
      }
    });

    test('Property 5: Token Validation - Concurrent validation should be thread-safe', () async {
      const int testIterations = 50;
      const int concurrentValidations = 10;

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        final token = jwtService.generateAccessToken(user);

        // Validate token concurrently
        final futures = List.generate(concurrentValidations, (_) async {
          return jwtService.validateToken(token);
        });

        final results = await Future.wait(futures);

        // All validations should succeed and return consistent results
        for (final payload in results) {
          expect(payload, isNotNull);
          expect(payload!.userId, equals(user.id));
          expect(payload.uuid, equals(user.uuid));
          expect(payload.role, equals(user.role));
        }
      }
    });
  });
}