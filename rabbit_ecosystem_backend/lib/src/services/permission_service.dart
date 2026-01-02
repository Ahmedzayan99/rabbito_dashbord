import '../models/user.dart';
import '../models/user_role.dart';

/// Service for managing user permissions and role-based access control
class PermissionService {
  /// Check if a user has a specific permission
  static bool hasPermission(User user, String permission) {
    return user.role.hasPermission(permission);
  }

  /// Check if a user has any of the specified permissions
  static bool hasAnyPermission(User user, List<String> permissions) {
    return permissions.any((permission) => user.role.hasPermission(permission));
  }

  /// Check if a user has all of the specified permissions
  static bool hasAllPermissions(User user, List<String> permissions) {
    return permissions.every((permission) => user.role.hasPermission(permission));
  }

  /// Check if a user has a specific role
  static bool hasRole(User user, UserRole role) {
    return user.role == role;
  }

  /// Check if a user has any of the specified roles
  static bool hasAnyRole(User user, List<UserRole> roles) {
    return roles.contains(user.role);
  }

  /// Check if a user is an admin
  static bool isAdmin(User user) {
    return user.role.isAdmin;
  }

  /// Check if a user is staff
  static bool isStaff(User user) {
    return user.role.isStaff;
  }

  /// Check if a user can access dashboard
  static bool canAccessDashboard(User user) {
    return user.role.canAccessDashboard;
  }

  /// Check if a user can access mobile API
  static bool canAccessMobileAPI(User user) {
    return user.role.canAccessMobileAPI;
  }

  /// Get all permissions for a user
  static List<String> getUserPermissions(User user) {
    return user.role.permissions;
  }

  /// Check if a user can access a specific resource
  /// Either they own it or have the required permission
  static bool canAccessResource(
    User user, 
    int resourceOwnerId, 
    String requiredPermission
  ) {
    // User can access their own resource
    if (user.id == resourceOwnerId) {
      return true;
    }
    
    // User can access if they have the required permission
    return hasPermission(user, requiredPermission);
  }

  /// Check if a user can modify a specific resource
  /// Either they own it or have the required permission
  static bool canModifyResource(
    User user, 
    int resourceOwnerId, 
    String requiredPermission
  ) {
    // User can modify their own resource (with some exceptions)
    if (user.id == resourceOwnerId) {
      return true;
    }
    
    // User can modify if they have the required permission
    return hasPermission(user, requiredPermission);
  }

  /// Get role hierarchy level (higher number = more permissions)
  static int getRoleLevel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 100;
      case UserRole.admin:
        return 80;
      case UserRole.finance:
        return 60;
      case UserRole.support:
        return 40;
      case UserRole.partner:
        return 30;
      case UserRole.rider:
        return 20;
      case UserRole.customer:
        return 10;
    }
  }

  /// Check if user1 has higher or equal role level than user2
  static bool hasHigherOrEqualRole(User user1, User user2) {
    return getRoleLevel(user1.role) >= getRoleLevel(user2.role);
  }

  /// Check if user1 can manage user2 (based on role hierarchy)
  static bool canManageUser(User manager, User target) {
    // Super admin can manage everyone
    if (manager.role == UserRole.superAdmin) {
      return true;
    }
    
    // Admin can manage non-admin users
    if (manager.role == UserRole.admin) {
      return !target.role.isAdmin;
    }
    
    // Other roles cannot manage users
    return false;
  }

  /// Get available actions for a user on a specific resource type
  static List<String> getAvailableActions(User user, String resourceType) {
    final permissions = getUserPermissions(user);
    return permissions
        .where((permission) => permission.startsWith('$resourceType.'))
        .map((permission) => permission.split('.').last)
        .toList();
  }

  /// Check if a user can perform a specific action on a resource type
  static bool canPerformAction(User user, String resourceType, String action) {
    return hasPermission(user, '$resourceType.$action');
  }

  /// Validate role transition (for role updates)
  static bool canChangeRole(User currentUser, UserRole fromRole, UserRole toRole) {
    // Super admin can change any role
    if (currentUser.role == UserRole.superAdmin) {
      return true;
    }
    
    // Admin can change non-admin roles
    if (currentUser.role == UserRole.admin) {
      return !fromRole.isAdmin && !toRole.isAdmin;
    }
    
    // Other roles cannot change roles
    return false;
  }

  /// Get permission groups for better organization
  static Map<String, List<String>> getPermissionGroups() {
    return {
      'User Management': [
        'users.create',
        'users.read',
        'users.update',
        'users.delete',
      ],
      'Partner Management': [
        'partners.create',
        'partners.read',
        'partners.update',
        'partners.delete',
      ],
      'Order Management': [
        'orders.create',
        'orders.read',
        'orders.update',
        'orders.delete',
      ],
      'Product Management': [
        'products.create',
        'products.read',
        'products.update',
        'products.delete',
      ],
      'Transaction Management': [
        'transactions.read',
        'transactions.update',
      ],
      'System Settings': [
        'settings.read',
        'settings.update',
      ],
      'Analytics': [
        'analytics.read',
      ],
      'Profile Management': [
        'profile.read',
        'profile.update',
      ],
      'Address Management': [
        'addresses.create',
        'addresses.read',
        'addresses.update',
        'addresses.delete',
      ],
    };
  }

  /// Get user-friendly permission descriptions
  static Map<String, String> getPermissionDescriptions() {
    return {
      'users.create': 'Create new users',
      'users.read': 'View user information',
      'users.update': 'Update user information',
      'users.delete': 'Delete users',
      'partners.create': 'Create new partners',
      'partners.read': 'View partner information',
      'partners.update': 'Update partner information',
      'partners.delete': 'Delete partners',
      'orders.create': 'Create new orders',
      'orders.read': 'View order information',
      'orders.update': 'Update order status',
      'orders.delete': 'Cancel/delete orders',
      'products.create': 'Create new products',
      'products.read': 'View product information',
      'products.update': 'Update product information',
      'products.delete': 'Delete products',
      'transactions.read': 'View transaction history',
      'transactions.update': 'Update transaction status',
      'settings.read': 'View system settings',
      'settings.update': 'Update system settings',
      'analytics.read': 'View analytics and reports',
      'profile.read': 'View own profile',
      'profile.update': 'Update own profile',
      'addresses.create': 'Add new addresses',
      'addresses.read': 'View addresses',
      'addresses.update': 'Update addresses',
      'addresses.delete': 'Delete addresses',
    };
  }
}