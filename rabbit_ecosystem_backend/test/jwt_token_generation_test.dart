import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/services/jwt_service.dart';
import '../lib/src/models/user.dart';
import '../lib/src/models/user_role.dart';

/// **Feature: rabbit-ecosystem, Property 2: JWT Token Generation and Validation**
/// For any valid user credentials, the authentication system should generate 
/// valid JWT tokens that can be successfully validated
/// **Validates: Requirements 1.3**

void main() {
  group('JWT Token Generation and Validation Property Tests', () {
    late JwtService jwtService;
    final faker = Faker();

    setUp(() {
      jwtService = JwtService(
        secret: 'test_secret_key_for_property_testing',
        accessTokenExpiry: const Duration(hours: 1),
        refreshTokenExpiry: const Duration(days: 7),
      );
    });

    test('Property 2: JWT Token Generation and Validation - Generated tokens should be valid and contain correct user data', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Generate random user data
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          balance: faker.randomGenerator.decimal(scale: 1000),
          rating: faker.randomGenerator.decimal(scale: 5, min: 0),
          numberOfRatings: faker.randomGenerator.integer(1000),
          isActive: faker.randomGenerator.boolean(),
          emailVerified: faker.randomGenerator.boolean(),
          mobileVerified: faker.randomGenerator.boolean(),
          createdAt: faker.date.dateTime(minYear: 2020, maxYear: 2024),
        );

        // Generate access token
        final accessToken = jwtService.generateAccessToken(user);
        expect(accessToken, isNotEmpty);
        expect(accessToken.split('.').length, equals(3)); // JWT has 3 parts

        // Validate the generated token
        final payload = jwtService.validateToken(accessToken);
        expect(payload, isNotNull);
        expect(payload!.isAccessToken, isTrue);

        // Verify token contains correct user data
        expect(payload.userId, equals(user.id));
        expect(payload.uuid, equals(user.uuid));
        expect(payload.mobile, equals(user.mobile));
        expect(payload.email, equals(user.email));
        expect(payload.role, equals(user.role));
        expect(payload.permissions, equals(user.role.permissions));

        // Verify token is not expired
        expect(payload.isExpired, isFalse);
        expect(payload.expiresAt.isAfter(DateTime.now()), isTrue);

        // Generate refresh token
        final refreshToken = jwtService.generateRefreshToken(user);
        expect(refreshToken, isNotEmpty);
        expect(refreshToken.split('.').length, equals(3));

        // Validate refresh token
        final refreshPayload = jwtService.validateToken(refreshToken);
        expect(refreshPayload, isNotNull);
        expect(refreshPayload!.isRefreshToken, isTrue);
        expect(refreshPayload.userId, equals(user.id));
        expect(refreshPayload.uuid, equals(user.uuid));
      }
    });

    test('Property 2: JWT Token Generation and Validation - Token pair generation should produce valid access and refresh tokens', () async {
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

        // Generate token pair
        final tokenPair = jwtService.generateTokenPair(user);

        // Validate access token
        expect(tokenPair.accessToken, isNotEmpty);
        final accessPayload = jwtService.validateToken(tokenPair.accessToken);
        expect(accessPayload, isNotNull);
        expect(accessPayload!.isAccessToken, isTrue);
        expect(accessPayload.userId, equals(user.id));

        // Validate refresh token
        expect(tokenPair.refreshToken, isNotEmpty);
        final refreshPayload = jwtService.validateToken(tokenPair.refreshToken);
        expect(refreshPayload, isNotNull);
        expect(refreshPayload!.isRefreshToken, isTrue);
        expect(refreshPayload.userId, equals(user.id));

        // Verify expiry times
        expect(tokenPair.expiresAt.isAfter(DateTime.now()), isTrue);
        expect(accessPayload.expiresAt.isBefore(refreshPayload.expiresAt), isTrue);

        // Verify tokens are different
        expect(tokenPair.accessToken, isNot(equals(tokenPair.refreshToken)));
      }
    });

    test('Property 2: JWT Token Generation and Validation - Different users should generate different tokens', () async {
      const int testIterations = 50;

      final generatedTokens = <String>{};
      final users = <User>[];

      for (int i = 0; i < testIterations; i++) {
        final user = User(
          id: i + 1, // Ensure unique IDs
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );
        users.add(user);

        final accessToken = jwtService.generateAccessToken(user);
        final refreshToken = jwtService.generateRefreshToken(user);

        // Tokens should be unique
        expect(generatedTokens.contains(accessToken), isFalse);
        expect(generatedTokens.contains(refreshToken), isFalse);

        generatedTokens.add(accessToken);
        generatedTokens.add(refreshToken);

        // Validate tokens
        final accessPayload = jwtService.validateToken(accessToken);
        final refreshPayload = jwtService.validateToken(refreshToken);

        expect(accessPayload, isNotNull);
        expect(refreshPayload, isNotNull);
        expect(accessPayload!.userId, equals(user.id));
        expect(refreshPayload!.userId, equals(user.id));
      }

      // Verify all tokens are unique
      expect(generatedTokens.length, equals(testIterations * 2));
    });

    test('Property 2: JWT Token Generation and Validation - Role permissions should be correctly embedded in tokens', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Test each role type
        final role = UserRole.values[i % UserRole.values.length];
        
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: role,
          createdAt: DateTime.now(),
        );

        final accessToken = jwtService.generateAccessToken(user);
        final payload = jwtService.validateToken(accessToken);

        expect(payload, isNotNull);
        expect(payload!.role, equals(role));
        expect(payload.permissions, equals(role.permissions));

        // Verify role-specific properties
        expect(payload.canAccessDashboard(), equals(role.canAccessDashboard));
        expect(payload.canAccessMobileAPI(), equals(role.canAccessMobileAPI));

        // Test permission checking
        for (final permission in role.permissions) {
          expect(payload.hasPermission(permission), isTrue);
        }

        // Test invalid permission
        final invalidPermission = 'invalid.permission.${faker.lorem.word()}';
        if (!role.permissions.contains(invalidPermission)) {
          expect(payload.hasPermission(invalidPermission), isFalse);
        }
      }
    });

    test('Property 2: JWT Token Generation and Validation - Token expiry should be correctly set and validated', () async {
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

        final now = DateTime.now();
        final accessToken = jwtService.generateAccessToken(user);
        final refreshToken = jwtService.generateRefreshToken(user);

        final accessPayload = jwtService.validateToken(accessToken);
        final refreshPayload = jwtService.validateToken(refreshToken);

        expect(accessPayload, isNotNull);
        expect(refreshPayload, isNotNull);

        // Verify expiry times are in the future
        expect(accessPayload!.expiresAt.isAfter(now), isTrue);
        expect(refreshPayload!.expiresAt.isAfter(now), isTrue);

        // Verify refresh token expires after access token
        expect(refreshPayload.expiresAt.isAfter(accessPayload.expiresAt), isTrue);

        // Verify issued at time is reasonable
        expect(accessPayload.issuedAt.isBefore(now.add(Duration(seconds: 1))), isTrue);
        expect(accessPayload.issuedAt.isAfter(now.subtract(Duration(seconds: 1))), isTrue);

        // Verify tokens are not expired
        expect(accessPayload.isExpired, isFalse);
        expect(refreshPayload.isExpired, isFalse);
        expect(jwtService.isTokenExpired(accessToken), isFalse);
        expect(jwtService.isTokenExpired(refreshToken), isFalse);
      }
    });

    test('Property 2: JWT Token Generation and Validation - User ID extraction should work correctly', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        final userId = faker.randomGenerator.integer(10000, min: 1);
        final user = User(
          id: userId,
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.values[faker.randomGenerator.integer(UserRole.values.length)],
          createdAt: DateTime.now(),
        );

        final accessToken = jwtService.generateAccessToken(user);
        final refreshToken = jwtService.generateRefreshToken(user);

        // Extract user ID from tokens
        final extractedFromAccess = jwtService.extractUserId(accessToken);
        final extractedFromRefresh = jwtService.extractUserId(refreshToken);

        expect(extractedFromAccess, equals(userId));
        expect(extractedFromRefresh, equals(userId));
      }
    });
  });
}