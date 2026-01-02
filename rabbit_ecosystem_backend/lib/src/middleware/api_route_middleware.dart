import 'package:serverpod/serverpod.dart';
import '../models/user_role.dart';
import 'auth_middleware.dart';
import 'role_middleware.dart';

/// Middleware to enforce API route access rules
class ApiRouteMiddleware {
  final AuthMiddleware _authMiddleware;

  ApiRouteMiddleware(this._authMiddleware);

  /// Main middleware function to check API route access
  Future<bool> checkAccess(Session session) async {
    final route = session.httpRequest.uri.path;
    final method = session.httpRequest.method;

    // Extract token from headers
    final token = _authMiddleware.extractTokenFromHeaders(session.httpRequest.headers);

    // Public routes that don't require authentication
    if (_isPublicRoute(route, method)) {
      return true;
    }

    // Validate authentication
    final isAuthenticated = await _authMiddleware.validateToken(session, token);
    if (!isAuthenticated) {
      return false;
    }

    // Check route-specific access
    return _checkRouteAccess(session, route, method);
  }

  /// Check if route is public (doesn't require authentication)
  bool _isPublicRoute(String route, String method) {
    final publicRoutes = [
      // Authentication routes
      '/api/mobile/auth/login',
      '/api/mobile/auth/register',
      '/api/dashboard/auth/login',
      
      // Public information routes
      '/api/mobile/public/cities',
      '/api/mobile/public/categories',
      '/api/mobile/public/partners',
      '/api/mobile/public/products',
      
      // Health check
      '/health',
      '/api/health',
      
      // Documentation
      '/docs',
      '/api/docs',
    ];

    // Only GET requests for public info routes
    if (route.startsWith('/api/mobile/public/') && method != 'GET') {
      return false;
    }

    return publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }

  /// Check access for specific routes based on user role and permissions
  bool _checkRouteAccess(Session session, String route, String method) {
    final auth = session.auth;
    if (auth == null) return false;

    // Mobile API routes
    if (route.startsWith('/api/mobile/')) {
      return _checkMobileAPIAccess(auth, route, method);
    }

    // Dashboard API routes
    if (route.startsWith('/api/dashboard/')) {
      return _checkDashboardAPIAccess(auth, route, method);
    }

    // Default: deny access
    return false;
  }

  /// Check access for mobile API routes
  bool _checkMobileAPIAccess(SessionAuth auth, String route, String method) {
    // Must be able to access mobile API
    if (!auth.canAccessMobileAPI) return false;

    // Customer routes
    if (route.startsWith('/api/mobile/customer/')) {
      return auth.hasRole(UserRole.customer);
    }

    // Partner routes
    if (route.startsWith('/api/mobile/partner/')) {
      return auth.hasRole(UserRole.partner);
    }

    // Rider routes
    if (route.startsWith('/api/mobile/rider/')) {
      return auth.hasRole(UserRole.rider);
    }

    // User profile routes (accessible by all mobile users)
    if (route.startsWith('/api/mobile/user/')) {
      return _checkUserRouteAccess(auth, route, method);
    }

    // Order routes
    if (route.startsWith('/api/mobile/orders/')) {
      return _checkOrderRouteAccess(auth, route, method);
    }

    // Product routes (read-only for customers, full access for partners)
    if (route.startsWith('/api/mobile/products/')) {
      return _checkProductRouteAccess(auth, route, method);
    }

    // Cart routes (customers only)
    if (route.startsWith('/api/mobile/cart/')) {
      return auth.hasRole(UserRole.customer);
    }

    // Wallet routes
    if (route.startsWith('/api/mobile/wallet/')) {
      return _checkWalletRouteAccess(auth, route, method);
    }

    // Address routes (customers only)
    if (route.startsWith('/api/mobile/addresses/')) {
      return auth.hasRole(UserRole.customer);
    }

    // General mobile API access
    return true;
  }

  /// Check access for dashboard API routes
  bool _checkDashboardAPIAccess(SessionAuth auth, String route, String method) {
    // Must be staff to access dashboard
    if (!auth.isStaff) return false;

    // Super admin routes
    if (route.startsWith('/api/dashboard/super-admin/')) {
      return auth.hasRole(UserRole.superAdmin);
    }

    // Admin routes
    if (route.startsWith('/api/dashboard/admin/')) {
      return auth.hasAnyRole([UserRole.superAdmin, UserRole.admin]);
    }

    // Finance routes
    if (route.startsWith('/api/dashboard/finance/')) {
      return auth.hasAnyRole([UserRole.superAdmin, UserRole.finance]);
    }

    // Support routes
    if (route.startsWith('/api/dashboard/support/')) {
      return auth.hasAnyRole([UserRole.superAdmin, UserRole.support]);
    }

    // User management routes
    if (route.startsWith('/api/dashboard/users/')) {
      return _checkDashboardUserRouteAccess(auth, route, method);
    }

    // Partner management routes
    if (route.startsWith('/api/dashboard/partners/')) {
      return _checkDashboardPartnerRouteAccess(auth, route, method);
    }

    // Order management routes
    if (route.startsWith('/api/dashboard/orders/')) {
      return _checkDashboardOrderRouteAccess(auth, route, method);
    }

    // Analytics routes
    if (route.startsWith('/api/dashboard/analytics/')) {
      return auth.hasPermission('analytics.read');
    }

    // Transaction routes
    if (route.startsWith('/api/dashboard/transactions/')) {
      return _checkDashboardTransactionRouteAccess(auth, route, method);
    }

    // Settings routes
    if (route.startsWith('/api/dashboard/settings/')) {
      return _checkDashboardSettingsRouteAccess(auth, route, method);
    }

    // General dashboard access for staff
    return true;
  }

  /// Check user route access
  bool _checkUserRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('profile.read');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('profile.update');
      default:
        return false;
    }
  }

  /// Check order route access for mobile API
  bool _checkOrderRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('orders.read');
      case 'POST':
        return auth.hasPermission('orders.create');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('orders.update');
      case 'DELETE':
        return auth.hasPermission('orders.delete');
      default:
        return false;
    }
  }

  /// Check product route access for mobile API
  bool _checkProductRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('products.read');
      case 'POST':
        return auth.hasPermission('products.create');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('products.update');
      case 'DELETE':
        return auth.hasPermission('products.delete');
      default:
        return false;
    }
  }

  /// Check wallet route access
  bool _checkWalletRouteAccess(SessionAuth auth, String route, String method) {
    // All mobile users can read their wallet
    if (method == 'GET') return true;
    
    // Only specific operations allowed
    if (route.endsWith('/withdrawal') && method == 'POST') {
      return true; // All users can request withdrawal
    }
    
    return false;
  }

  /// Check dashboard user route access
  bool _checkDashboardUserRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('users.read');
      case 'POST':
        return auth.hasPermission('users.create');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('users.update');
      case 'DELETE':
        return auth.hasPermission('users.delete');
      default:
        return false;
    }
  }

  /// Check dashboard partner route access
  bool _checkDashboardPartnerRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('partners.read');
      case 'POST':
        return auth.hasPermission('partners.create');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('partners.update');
      case 'DELETE':
        return auth.hasPermission('partners.delete');
      default:
        return false;
    }
  }

  /// Check dashboard order route access
  bool _checkDashboardOrderRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('orders.read');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('orders.update');
      case 'DELETE':
        return auth.hasPermission('orders.delete');
      default:
        return false;
    }
  }

  /// Check dashboard transaction route access
  bool _checkDashboardTransactionRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('transactions.read');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('transactions.update');
      default:
        return false;
    }
  }

  /// Check dashboard settings route access
  bool _checkDashboardSettingsRouteAccess(SessionAuth auth, String route, String method) {
    switch (method) {
      case 'GET':
        return auth.hasPermission('settings.read');
      case 'PUT':
      case 'PATCH':
        return auth.hasPermission('settings.update');
      default:
        return false;
    }
  }

  /// Create middleware function for Serverpod
  Future<bool> Function(Session) createMiddleware() {
    return (Session session) async {
      return checkAccess(session);
    };
  }
}

/// HTTP response helpers for access control
class AccessControlResponse {
  static Map<String, dynamic> unauthorized(String message) {
    return {
      'error': true,
      'message': message,
      'code': 'UNAUTHORIZED',
      'status': 401,
    };
  }

  static Map<String, dynamic> forbidden(String message) {
    return {
      'error': true,
      'message': message,
      'code': 'FORBIDDEN',
      'status': 403,
    };
  }

  static Map<String, dynamic> invalidRoute(String route) {
    return {
      'error': true,
      'message': 'Invalid route or method not allowed',
      'route': route,
      'code': 'INVALID_ROUTE',
      'status': 404,
    };
  }

  static Map<String, dynamic> insufficientPermissions(List<String> requiredPermissions) {
    return {
      'error': true,
      'message': 'Insufficient permissions',
      'required_permissions': requiredPermissions,
      'code': 'INSUFFICIENT_PERMISSIONS',
      'status': 403,
    };
  }
}