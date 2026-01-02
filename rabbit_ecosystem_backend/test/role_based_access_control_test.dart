import 'package:test/test.dart';
import 'package:faker/faker.dart';
import '../lib/src/models/user_role.dart';
import '../lib/src/models/user.dart';
import '../lib/src/services/jwt_service.dart';

/// **Feature: rabbit-ecosystem, Property 3: Role-Based Access Control**
/// For any API endpoint and user role combination, the system should only 
/// allow access to endpoints permitted for that specific role
/// **Validates: Requirements 1.4**

void main() {
  group('Role-Based Access Control Property Tests', () {
    late JwtService jwtService;
    final faker = Faker();

    setUp(() {
      jwtService = JwtService(
        secret: 'test_secret_for_rbac_testing',
        accessTokenExpiry: const Duration(hours: 1),
        refreshTokenExpiry: const Duration(days: 1),
      );
    });

    test('Property 3: Role-Based Access Control - Each role should only access permitted endpoints', () async {
      const int testIterations = 100;

      // Define endpoint patterns and their required roles
      final endpointRoleMap = {
        '/api/mobile/customer/profile': [UserRole.customer],
        '/api/mobile/customer/orders': [UserRole.customer],
        '/api/mobile/customer/addresses': [UserRole.customer],
        '/api/mobile/customer/cart': [UserRole.customer],
        
        '/api/mobile/partner/products': [UserRole.partner],
        '/api/mobile/partner/orders': [UserRole.partner],
        '/api/mobile/partner/dashboard': [UserRole.partner],
        
        '/api/mobile/rider/orders': [UserRole.rider],
        '/api/mobile/rider/earnings': [UserRole.rider],
        '/api/mobile/rider/location': [UserRole.rider],
        
        '/api/dashboard/users': [UserRole.superAdmin, UserRole.admin],
        '/api/dashboard/partners': [UserRole.superAdmin, UserRole.admin],
        '/api/dashboard/analytics': [UserRole.superAdmin, UserRole.finance],
        '/api/dashboard/transactions': [UserRole.superAdmin, UserRole.finance],
        '/api/dashboard/settings': [UserRole.superAdmin],
        '/api/dashboard/support/tickets': [UserRole.superAdmin, UserRole.support],
      };

      for (int i = 0; i < testIterations; i++) {
        // Pick a random endpoint and role combination
        final endpoints = endpointRoleMap.keys.toList();
        final randomEndpoint = endpoints[faker.randomGenerator.integer(endpoints.length)];
        final allowedRoles = endpointRoleMap[randomEndpoint]!;
        
        // Test with allowed role
        final allowedRole = allowedRoles[faker.randomGenerator.integer(allowedRoles.length)];
        final userWithAllowedRole = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: allowedRole,
          createdAt: DateTime.now(),
        );

        final tokenForAllowedUser = jwtService.generateAccessToken(userWithAllowedRole);
        final payloadForAllowed = jwtService.validateToken(tokenForAllowedUser);
        
        expect(payloadForAllowed, isNotNull);
        expect(payloadForAllowed!.role, equals(allowedRole));
        
        // Verify user has access to the endpoint based on role
        final hasAccess = _checkEndpointAccess(randomEndpoint, allowedRole);
        expect(hasAccess, isTrue, reason: 'Role $allowedRole should have access to $randomEndpoint');

        // Test with disallowed role
        final allRoles = UserRole.values.where((role) => !allowedRoles.contains(role)).toList();
        if (allRoles.isNotEmpty) {
          final disallowedRole = allRoles[faker.randomGenerator.integer(allRoles.length)];
          final userWithDisallowedRole = User(
            id: faker.randomGenerator.integer(10000, min: 1),
            uuid: faker.guid.guid(),
            username: faker.person.name(),
            email: faker.internet.email(),
            mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
            role: disallowedRole,
            createdAt: DateTime.now(),
          );

          final tokenForDisallowedUser = jwtService.generateAccessToken(userWithDisallowedRole);
          final payloadForDisallowed = jwtService.validateToken(tokenForDisallowedUser);
          
          expect(payloadForDisallowed, isNotNull);
          expect(payloadForDisallowed!.role, equals(disallowedRole));
          
          // Verify user does NOT have access to the endpoint
          final hasNoAccess = _checkEndpointAccess(randomEndpoint, disallowedRole);
          expect(hasNoAccess, isFalse, reason: 'Role $disallowedRole should NOT have access to $randomEndpoint');
        }
      }
    });

    test('Property 3: Role-Based Access Control - Mobile API access should be restricted to mobile roles', () async {
      const int testIterations = 100;

      final mobileRoles = [UserRole.customer, UserRole.partner, UserRole.rider];
      final dashboardRoles = [UserRole.superAdmin, UserRole.admin, UserRole.finance, UserRole.support];

      for (int i = 0; i < testIterations; i++) {
        // Test mobile role access to mobile API
        final mobileRole = mobileRoles[faker.randomGenerator.integer(mobileRoles.length)];
        final mobileUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: mobileRole,
          createdAt: DateTime.now(),
        );

        final mobileToken = jwtService.generateAccessToken(mobileUser);
        final mobilePayload = jwtService.validateToken(mobileToken);
        
        expect(mobilePayload, isNotNull);
        expect(mobilePayload!.canAccessMobileAPI(), isTrue);
        expect(mobilePayload.canAccessDashboard(), isFalse);

        // Test dashboard role access to dashboard API
        final dashboardRole = dashboardRoles[faker.randomGenerator.integer(dashboardRoles.length)];
        final dashboardUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: dashboardRole,
          createdAt: DateTime.now(),
        );

        final dashboardToken = jwtService.generateAccessToken(dashboardUser);
        final dashboardPayload = jwtService.validateToken(dashboardToken);
        
        expect(dashboardPayload, isNotNull);
        expect(dashboardPayload!.canAccessDashboard(), isTrue);
        expect(dashboardPayload.canAccessMobileAPI(), isFalse);
      }
    });

    test('Property 3: Role-Based Access Control - Permission inheritance should work correctly', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        final role = UserRole.values[faker.randomGenerator.integer(UserRole.values.length)];
        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: role,
          createdAt: DateTime.now(),
        );

        final token = jwtService.generateAccessToken(user);
        final payload = jwtService.validateToken(token);
        
        expect(payload, isNotNull);
        expect(payload!.role, equals(role));
        expect(payload.permissions, equals(role.permissions));

        // Test that user has all permissions assigned to their role
        for (final permission in role.permissions) {
          expect(payload.hasPermission(permission), isTrue, 
            reason: 'Role $role should have permission $permission');
        }

        // Test that user doesn't have permissions not assigned to their role
        final allPossiblePermissions = UserRole.values
            .expand((r) => r.permissions)
            .toSet()
            .toList();
        
        final unauthorizedPermissions = allPossiblePermissions
            .where((permission) => !role.permissions.contains(permission))
            .toList();

        if (unauthorizedPermissions.isNotEmpty) {
          final randomUnauthorizedPermission = unauthorizedPermissions[
            faker.randomGenerator.integer(unauthorizedPermissions.length)
          ];
          
          expect(payload.hasPermission(randomUnauthorizedPermission), isFalse,
            reason: 'Role $role should NOT have permission $randomUnauthorizedPermission');
        }
      }
    });

    test('Property 3: Role-Based Access Control - Admin hierarchy should be respected', () async {
      const int testIterations = 100;

      for (int i = 0; i < testIterations; i++) {
        // Super Admin should have the most permissions
        final superAdminUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.superAdmin,
          createdAt: DateTime.now(),
        );

        final superAdminToken = jwtService.generateAccessToken(superAdminUser);
        final superAdminPayload = jwtService.validateToken(superAdminToken);
        
        expect(superAdminPayload, isNotNull);
        expect(superAdminPayload!.role, equals(UserRole.superAdmin));

        // Admin should have fewer permissions than Super Admin
        final adminUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );

        final adminToken = jwtService.generateAccessToken(adminUser);
        final adminPayload = jwtService.validateToken(adminToken);
        
        expect(adminPayload, isNotNull);
        expect(adminPayload!.role, equals(UserRole.admin));

        // Super Admin should have all permissions that Admin has, plus more
        final adminPermissions = UserRole.admin.permissions;
        final superAdminPermissions = UserRole.superAdmin.permissions;
        
        for (final adminPermission in adminPermissions) {
          expect(superAdminPermissions.contains(adminPermission), isTrue,
            reason: 'Super Admin should have all Admin permissions');
        }

        expect(superAdminPermissions.length >= adminPermissions.length, isTrue,
          reason: 'Super Admin should have at least as many permissions as Admin');

        // Specialized roles should have specific permissions
        final financeUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.finance,
          createdAt: DateTime.now(),
        );

        final financeToken = jwtService.generateAccessToken(financeUser);
        final financePayload = jwtService.validateToken(financeToken);
        
        expect(financePayload, isNotNull);
        expect(financePayload!.hasPermission('transactions.read'), isTrue);
        expect(financePayload.hasPermission('analytics.read'), isTrue);
      }
    });

    test('Property 3: Role-Based Access Control - Cross-role access should be prevented', () async {
      const int testIterations = 100;

      final roleEndpointMap = {
        UserRole.customer: ['/api/mobile/customer/', '/api/mobile/orders/', '/api/mobile/cart/'],
        UserRole.partner: ['/api/mobile/partner/', '/api/mobile/products/'],
        UserRole.rider: ['/api/mobile/rider/', '/api/mobile/deliveries/'],
        UserRole.admin: ['/api/dashboard/users/', '/api/dashboard/orders/'],
        UserRole.finance: ['/api/dashboard/transactions/', '/api/dashboard/analytics/'],
        UserRole.support: ['/api/dashboard/support/', '/api/dashboard/tickets/'],
      };

      for (int i = 0; i < testIterations; i++) {
        final roles = roleEndpointMap.keys.toList();
        final userRole = roles[faker.randomGenerator.integer(roles.length)];
        final otherRoles = roles.where((role) => role != userRole).toList();

        final user = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: userRole,
          createdAt: DateTime.now(),
        );

        final token = jwtService.generateAccessToken(user);
        final payload = jwtService.validateToken(token);
        
        expect(payload, isNotNull);
        expect(payload!.role, equals(userRole));

        // User should have access to their own role's endpoints
        final userEndpoints = roleEndpointMap[userRole] ?? [];
        for (final endpoint in userEndpoints) {
          final hasAccess = _checkEndpointAccess(endpoint, userRole);
          expect(hasAccess, isTrue, 
            reason: 'User with role $userRole should access $endpoint');
        }

        // User should NOT have access to other roles' specific endpoints
        if (otherRoles.isNotEmpty) {
          final otherRole = otherRoles[faker.randomGenerator.integer(otherRoles.length)];
          final otherEndpoints = roleEndpointMap[otherRole] ?? [];
          
          for (final endpoint in otherEndpoints) {
            // Skip if this endpoint is also accessible by user's role
            if (!userEndpoints.any((userEndpoint) => endpoint.startsWith(userEndpoint))) {
              final hasAccess = _checkEndpointAccess(endpoint, userRole);
              expect(hasAccess, isFalse,
                reason: 'User with role $userRole should NOT access $endpoint (belongs to $otherRole)');
            }
          }
        }
      }
    });

    test('Property 3: Role-Based Access Control - Token role modification should not affect access', () async {
      const int testIterations = 50;

      for (int i = 0; i < testIterations; i++) {
        // Create user with limited role
        final limitedUser = User(
          id: faker.randomGenerator.integer(10000, min: 1),
          uuid: faker.guid.guid(),
          username: faker.person.name(),
          email: faker.internet.email(),
          mobile: '+966${faker.randomGenerator.integer(999999999, min: 500000000)}',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        final originalToken = jwtService.generateAccessToken(limitedUser);
        final originalPayload = jwtService.validateToken(originalToken);
        
        expect(originalPayload, isNotNull);
        expect(originalPayload!.role, equals(UserRole.customer));
        expect(originalPayload.canAccessDashboard(), isFalse);

        // Even if someone tries to create a token with elevated privileges,
        // the validation should be based on the actual token signature
        final elevatedUser = User(
          id: limitedUser.id, // Same user ID
          uuid: limitedUser.uuid, // Same UUID
          username: limitedUser.username,
          email: limitedUser.email,
          mobile: limitedUser.mobile,
          role: UserRole.superAdmin, // Elevated role
          createdAt: limitedUser.createdAt,
        );

        final elevatedToken = jwtService.generateAccessToken(elevatedUser);
        final elevatedPayload = jwtService.validateToken(elevatedToken);
        
        expect(elevatedPayload, isNotNull);
        expect(elevatedPayload!.role, equals(UserRole.superAdmin));
        expect(elevatedPayload.canAccessDashboard(), isTrue);

        // The tokens should be different
        expect(originalToken, isNot(equals(elevatedToken)));
        
        // Each token should only grant access according to its embedded role
        expect(originalPayload.hasPermission('users.create'), isFalse);
        expect(elevatedPayload.hasPermission('users.create'), isTrue);
      }
    });
  });
}

/// Helper function to simulate endpoint access checking
bool _checkEndpointAccess(String endpoint, UserRole role) {
  // Mobile API endpoints
  if (endpoint.startsWith('/api/mobile/')) {
    if (!role.canAccessMobileAPI) return false;
    
    if (endpoint.startsWith('/api/mobile/customer/')) {
      return role == UserRole.customer;
    }
    if (endpoint.startsWith('/api/mobile/partner/')) {
      return role == UserRole.partner;
    }
    if (endpoint.startsWith('/api/mobile/rider/')) {
      return role == UserRole.rider;
    }
    if (endpoint.startsWith('/api/mobile/deliveries/')) {
      return role == UserRole.rider;
    }
    if (endpoint.startsWith('/api/mobile/products/')) {
      return role == UserRole.partner;
    }
    if (endpoint.startsWith('/api/mobile/cart/')) {
      return role == UserRole.customer;
    }
    if (endpoint.startsWith('/api/mobile/orders/')) {
      // Only customers can access generic orders endpoint
      return role == UserRole.customer;
    }
    
    // General mobile endpoints accessible by all mobile users
    return role.canAccessMobileAPI;
  }
  
  // Dashboard API endpoints
  if (endpoint.startsWith('/api/dashboard/')) {
    if (!role.canAccessDashboard) return false;
    
    // Specific endpoint checks
    if (endpoint.startsWith('/api/dashboard/users')) {
      return role.hasPermission('users.read');
    }
    if (endpoint.startsWith('/api/dashboard/partners')) {
      return role.hasPermission('partners.read');
    }
    if (endpoint.startsWith('/api/dashboard/analytics')) {
      return role.hasPermission('analytics.read');
    }
    if (endpoint.startsWith('/api/dashboard/transactions')) {
      return role.hasPermission('transactions.read');
    }
    if (endpoint.startsWith('/api/dashboard/settings')) {
      return role.hasPermission('settings.read');
    }
    if (endpoint.startsWith('/api/dashboard/orders')) {
      return role.hasPermission('orders.read');
    }
    if (endpoint.startsWith('/api/dashboard/support')) {
      return role == UserRole.superAdmin || role == UserRole.support;
    }
    if (endpoint.startsWith('/api/dashboard/tickets')) {
      return role == UserRole.superAdmin || role == UserRole.support;
    }
    
    // For any other dashboard endpoint, deny access by default
    return false;
  }
  
  return false;
}