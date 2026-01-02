import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../storage/local_storage.dart';

class AppRouter {
  // Note: LocalStorage is abstract, should be injected via DI
  // For now, this will need to be initialized elsewhere
  static LocalStorage? _localStorage;
  
  static void initialize(LocalStorage localStorage) {
    _localStorage = localStorage;
  }
  
  static LocalStorage get localStorage {
    if (_localStorage == null) {
      throw StateError('LocalStorage not initialized. Call AppRouter.initialize() first.');
    }
    return _localStorage!;
  }

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return generateRoute(settings);
  }

  static Future<Widget> getInitialScreen() async {
    // Check if user is authenticated
    final token = await localStorage.getString('auth_token');
    final userRole = await localStorage.getString('user_role');

    if (token != null && token.isNotEmpty && userRole != null) {
      // Check if user has dashboard access
      if (_hasDashboardAccess(userRole)) {
        return const DashboardPage();
      }
    }

    return const LoginPage();
  }

  static bool _hasDashboardAccess(String role) {
    // Define roles that have access to dashboard
    const dashboardRoles = ['super_admin', 'admin', 'finance', 'support'];
    return dashboardRoles.contains(role);
  }

  static Future<bool> isAuthenticated() async {
    final token = await localStorage.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserRole() async {
    return await localStorage.getString('user_role');
  }

  static Future<bool> hasPermission(String requiredRole) async {
    final userRole = await getUserRole();

    if (userRole == null) return false;

    // Define role hierarchy
    const roleHierarchy = {
      'super_admin': 4,
      'admin': 3,
      'finance': 2,
      'support': 1,
      'customer': 0,
    };

    final userLevel = roleHierarchy[userRole] ?? 0;
    final requiredLevel = roleHierarchy[requiredRole] ?? 0;

    return userLevel >= requiredLevel;
  }

  static Future<void> logout(BuildContext context) async {
    await localStorage.clear();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
