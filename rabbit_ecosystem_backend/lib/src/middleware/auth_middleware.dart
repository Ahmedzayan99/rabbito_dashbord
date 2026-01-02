import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/jwt_service.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/refresh_token_repository.dart';

class AuthMiddleware {
  static final JwtService _jwtService = JwtService();
  // AuthService will be initialized when database connection is available
  static AuthService? _authService;

  /// Middleware to validate JWT token and add user to request context
  static Middleware get middleware => authenticate;

  /// Authenticate middleware (alias for middleware)
  static Middleware get authenticate {
    return (Handler innerHandler) {
      return (Request request) async {
        final token = _extractTokenFromRequest(request);
        
        if (token == null) {
          return Response.unauthorized(
            jsonEncode({'error': 'Authentication token required'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final user = await _authService?.validateAccessToken(token);
        if (user == null) {
          return Response.unauthorized(
            jsonEncode({'error': 'Invalid or expired token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Add user to request context
        final updatedRequest = request.change(context: {
          ...request.context,
          'user': user,
          'token': token,
        });

        return await innerHandler(updatedRequest);
      };
    };
  }

  /// Extract token from request headers
  static String? _extractTokenFromRequest(Request request) {
    // Check Authorization header
    final authHeader = request.headers['authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    // Check X-Auth-Token header
    final tokenHeader = request.headers['x-auth-token'];
    if (tokenHeader != null && tokenHeader.isNotEmpty) {
      return tokenHeader;
    }

    return null;
  }

  /// Validate token without middleware (for manual validation)
  static Future<User?> validateToken(String token) async {
    return await _authService?.validateAccessToken(token);
  }

  /// Check if user can access mobile API
  static bool canAccessMobileAPI(User user) {
    return user.role.canAccessMobileAPI;
  }

  /// Check if user can access dashboard API
  static bool canAccessDashboard(User user) {
    return user.role.canAccessDashboard;
  }

  /// Check if user has specific role
  static bool hasRole(User user, UserRole role) {
    return user.role == role;
  }

  /// Check if user has any of the specified roles
  static bool hasAnyRole(User user, List<UserRole> roles) {
    return roles.contains(user.role);
  }

  /// Check if user is admin
  static bool isAdmin(User user) {
    return user.role.isAdmin;
  }

  /// Check if user is staff (can access dashboard)
  static bool isStaff(User user) {
    return user.role.isStaff;
  }
}