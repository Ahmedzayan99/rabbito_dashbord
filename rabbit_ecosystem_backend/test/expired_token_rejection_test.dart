import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/services/jwt_service.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';

/// **Feature: rabbit-ecosystem, Property 8: Expired Token Rejection**
/// For any expired JWT token, the authentication system should reject 
/// requests and require re-authentication
/// **Validates: Requirements 2.5**

void main() {
  group('Expired Token Rejection Property Tests', () {
    final faker = Faker();

    test('Property 8: Expired Token Rejection - Basic expiry test', () async {
      final jwtService = JwtService(
        secret: 'test_secret_for_expiry_testing',
        accessTokenExpiry: const Duration(seconds: 1),
        refreshTokenExpiry: const Duration(seconds: 2),
      );

      final user = User(
        id: 1,
        uuid: 'test-uuid',
        username: 'testuser',
        email: 'test@example.com',
        mobile: '+1234567890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      // Generate token
      final token = jwtService.generateAccessToken(user);

      // Token should be valid immediately
      final initialPayload = jwtService.validateToken(token);
      expect(initialPayload, isNotNull, reason: 'Token should be valid immediately after generation');
      expect(jwtService.isTokenExpired(token), isFalse, reason: 'Token should not be expired immediately');

      // Wait for token to expire
      await Future.delayed(const Duration(seconds: 2));

      // Token should now be expired
      final expiredPayload = jwtService.validateToken(token);
      expect(expiredPayload, isNull, reason: 'Token should be null after expiry');
      expect(jwtService.isTokenExpired(token), isTrue, reason: 'Token should be expired after waiting');
    });

    test('Property 8: Expired Token Rejection - Multiple users test', () async {
      final jwtService = JwtService(
        secret: 'test_secret_multiple_users',
        accessTokenExpiry: const Duration(seconds: 1),
        refreshTokenExpiry: const Duration(seconds: 2),
      );

      const int testIterations = 10;

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

        // Token should be valid initially
        final payload = jwtService.validateToken(token);
        expect(payload, isNotNull, reason: 'Token should be valid for user ${user.id}');
        expect(jwtService.isTokenExpired(token), isFalse);

        // Wait for expiry
        await Future.delayed(const Duration(seconds: 2));

        // Token should be expired
        expect(jwtService.validateToken(token), isNull);
        expect(jwtService.isTokenExpired(token), isTrue);
      }
    });

    test('Property 8: Expired Token Rejection - Refresh token independence', () async {
      final jwtService = JwtService(
        secret: 'test_secret_refresh_independence',
        accessTokenExpiry: const Duration(seconds: 1),
        refreshTokenExpiry: const Duration(seconds: 3),
      );

      final user = User(
        id: 1,
        uuid: 'test-uuid',
        username: 'testuser',
        email: 'test@example.com',
        mobile: '+1234567890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      final tokenPair = jwtService.generateTokenPair(user);

      // Both tokens should be valid initially
      expect(jwtService.validateToken(tokenPair.accessToken), isNotNull);
      expect(jwtService.validateToken(tokenPair.refreshToken), isNotNull);

      // Wait for access token to expire
      await Future.delayed(const Duration(seconds: 2));

      // Access token should be expired, refresh token should still be valid
      expect(jwtService.validateToken(tokenPair.accessToken), isNull);
      expect(jwtService.validateToken(tokenPair.refreshToken), isNotNull);

      // Wait for refresh token to expire
      await Future.delayed(const Duration(seconds: 2));

      // Both should be expired
      expect(jwtService.validateToken(tokenPair.accessToken), isNull);
      expect(jwtService.validateToken(tokenPair.refreshToken), isNull);
    });

    test('Property 8: Expired Token Rejection - Consistent expiry behavior', () async {
      final jwtService = JwtService(
        secret: 'test_secret_consistency',
        accessTokenExpiry: const Duration(seconds: 1),
        refreshTokenExpiry: const Duration(seconds: 2),
      );

      const int testIterations = 3;

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

        // Token should be valid initially
        expect(jwtService.validateToken(token), isNotNull);
        expect(jwtService.isTokenExpired(token), isFalse);

        // Multiple validations should be consistent while token is valid
        for (int j = 0; j < 3; j++) {
          expect(jwtService.validateToken(token), isNotNull);
          expect(jwtService.isTokenExpired(token), isFalse);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for token to expire
        await Future.delayed(const Duration(seconds: 2));

        // Multiple validations should consistently reject expired token
        for (int j = 0; j < 3; j++) {
          expect(jwtService.validateToken(token), isNull);
          expect(jwtService.isTokenExpired(token), isTrue);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    });
  });
}