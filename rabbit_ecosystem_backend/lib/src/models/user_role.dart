enum UserRole {
  customer('customer'),
  partner('partner'),
  rider('rider'),
  superAdmin('super_admin'),
  admin('admin'),
  finance('finance'),
  support('support');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }

  bool get isAdmin => [superAdmin, admin].contains(this);
  bool get isStaff => [superAdmin, admin, finance, support].contains(this);
  bool get canAccessDashboard => isStaff;
  bool get canAccessMobileAPI => [customer, partner, rider].contains(this);

  List<String> get permissions {
    switch (this) {
      case UserRole.superAdmin:
        return [
          'users.create',
          'users.read',
          'users.update',
          'users.delete',
          'partners.create',
          'partners.read',
          'partners.update',
          'partners.delete',
          'orders.create',
          'orders.read',
          'orders.update',
          'orders.delete',
          'products.create',
          'products.read',
          'products.update',
          'products.delete',
          'transactions.read',
          'transactions.update',
          'settings.read',
          'settings.update',
          'analytics.read',
        ];
      case UserRole.admin:
        return [
          'users.read',
          'users.update',
          'partners.read',
          'partners.update',
          'orders.read',
          'orders.update',
          'products.read',
          'products.update',
        ];
      case UserRole.finance:
        return [
          'transactions.read',
          'transactions.update',
          'analytics.read',
        ];
      case UserRole.support:
        return [
          // Support only has access to support-specific endpoints
        ];
      case UserRole.customer:
        return [
          'profile.read',
          'profile.update',
          'orders.create',
          'orders.read',
          'addresses.create',
          'addresses.read',
          'addresses.update',
          'addresses.delete',
        ];
      case UserRole.partner:
        return [
          'profile.read',
          'profile.update',
          'products.create',
          'products.read',
          'products.update',
          'products.delete',
          'orders.read',
          'orders.update',
          'transactions.read',
        ];
      case UserRole.rider:
        return [
          'profile.read',
          'profile.update',
          'orders.read',
          'orders.update',
          'transactions.read',
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}