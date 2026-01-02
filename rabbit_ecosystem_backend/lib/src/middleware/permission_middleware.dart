import 'dart:io';
import 'package:shelf/shelf.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Middleware to check user permissions for specific actions
class PermissionMiddleware {
  /// Creates a middleware that checks if the user has the required permission
  static Middleware requirePermission(String permission) {
    return (Handler innerHandler) {
      return (Request request) async {
        // Get user from request context (set by auth middleware)
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Check if user has the required permission
        if (!user.role.hasPermission(permission)) {
          return Response(
            HttpStatus.forbidden,
            body: 'Insufficient permissions. Required: $permission',
            headers: {'Content-Type': 'application/json'},
          );
        }

        // User has permission, continue to handler
        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user has any of the required permissions
  static Middleware requireAnyPermission(List<String> permissions) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Check if user has any of the required permissions
        final hasAnyPermission = permissions.any((permission) => 
            user.role.hasPermission(permission));

        if (!hasAnyPermission) {
          return Response(
            HttpStatus.forbidden,
            body: 'Insufficient permissions. Required one of: ${permissions.join(', ')}',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user has all of the required permissions
  static Middleware requireAllPermissions(List<String> permissions) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Check if user has all required permissions
        final hasAllPermissions = permissions.every((permission) => 
            user.role.hasPermission(permission));

        if (!hasAllPermissions) {
          final missingPermissions = permissions.where((permission) => 
              !user.role.hasPermission(permission)).toList();
          
          return Response(
            HttpStatus.forbidden,
            body: 'Missing permissions: ${missingPermissions.join(', ')}',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user has a specific role
  static Middleware requireRole(UserRole role) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (user.role != role) {
          return Response(
            HttpStatus.forbidden,
            body: 'Required role: ${role.value}',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user has any of the specified roles
  static Middleware requireAnyRole(List<UserRole> roles) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!roles.contains(user.role)) {
          final roleValues = roles.map((r) => r.value).join(', ');
          return Response(
            HttpStatus.forbidden,
            body: 'Required one of roles: $roleValues',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user is an admin
  static Middleware requireAdmin() {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!user.role.isAdmin) {
          return Response(
            HttpStatus.forbidden,
            body: 'Admin access required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user is staff
  static Middleware requireStaff() {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!user.role.isStaff) {
          return Response(
            HttpStatus.forbidden,
            body: 'Staff access required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user can access dashboard
  static Middleware requireDashboardAccess() {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!user.role.canAccessDashboard) {
          return Response(
            HttpStatus.forbidden,
            body: 'Dashboard access not allowed for this role',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that checks if the user can access mobile API
  static Middleware requireMobileAccess() {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!user.role.canAccessMobileAPI) {
          return Response(
            HttpStatus.forbidden,
            body: 'Mobile API access not allowed for this role',
            headers: {'Content-Type': 'application/json'},
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Creates a middleware that allows access to resource owner or users with specific permission
  static Middleware requireOwnershipOrPermission(
    String permission, {
    String userIdParam = 'userId',
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final user = request.context['user'] as User?;
        
        if (user == null) {
          return Response(
            HttpStatus.unauthorized,
            body: 'Authentication required',
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Get the user ID from request parameters
        final requestedUserId = request.url.queryParameters[userIdParam];
        
        // Allow if user is accessing their own resource
        if (requestedUserId != null && user.id.toString() == requestedUserId) {
          return await innerHandler(request);
        }

        // Allow if user has the required permission
        if (user.role.hasPermission(permission)) {
          return await innerHandler(request);
        }

        return Response(
          HttpStatus.forbidden,
          body: 'Access denied. You can only access your own resources or need permission: $permission',
          headers: {'Content-Type': 'application/json'},
        );
      };
    };
  }
}