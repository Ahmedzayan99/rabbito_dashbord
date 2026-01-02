import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../models/user_role.dart';
import '../models/user.dart';

class RoleMiddleware {
  /// Create middleware that requires specific roles
  static Middleware requireRoles(List<UserRole> allowedRoles) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response.unauthorized(
            jsonEncode({'error': 'Authentication required'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!allowedRoles.contains(user.role)) {
          return Response.forbidden(
            jsonEncode({'error': 'Insufficient permissions'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Create middleware that requires admin role
  static Middleware requireAdmin() {
    return requireRoles([UserRole.superAdmin, UserRole.admin]);
  }

  /// Create middleware that requires staff roles (can access dashboard)
  static Middleware requireStaff() {
    return requireRoles([
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.finance,
      UserRole.support,
    ]);
  }

  /// Create middleware that requires customer role
  static Middleware requireCustomer() {
    return requireRoles([UserRole.customer]);
  }

  /// Create middleware that requires partner role
  static Middleware requirePartner() {
    return requireRoles([UserRole.partner]);
  }

  /// Create middleware that requires rider role
  static Middleware requireRider() {
    return requireRoles([UserRole.rider]);
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
    return user.role == UserRole.superAdmin || user.role == UserRole.admin;
  }

  /// Check if user is staff (can access dashboard)
  static bool isStaff(User user) {
    return [
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.finance,
      UserRole.support,
    ].contains(user.role);
  }

  /// Check if user can access mobile API
  static bool canAccessMobileAPI(User user) {
    return [
      UserRole.customer,
      UserRole.partner,
      UserRole.rider,
    ].contains(user.role);
  }

  /// Check if user can access dashboard API
  static bool canAccessDashboard(User user) {
    return [
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.finance,
      UserRole.support,
    ].contains(user.role);
  }
}