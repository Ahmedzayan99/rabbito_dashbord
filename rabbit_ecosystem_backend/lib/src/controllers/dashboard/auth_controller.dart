import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';

class DashboardAuthController {
  static final AuthService _authService = AuthService(
    userRepository: null as dynamic,
    refreshTokenRepository: null as dynamic,
  );

  static Future<Response> login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _authService.login(email, password);

      if (result == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'Invalid credentials'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = result['user'] as User;

      // Check if user has dashboard access (admin roles)
      if (![
        UserRole.superAdmin,
        UserRole.admin,
        UserRole.finance,
        UserRole.support
      ].contains(user.role)) {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Dashboard access required.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'token': result['token'],
          'refreshToken': result['refreshToken'],
          'user': user.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getProfile(Request request) async {
    try {
      // User info is already extracted by AuthMiddleware
      final user = request.context['user'] as User;

      return Response.ok(
        jsonEncode({
          'user': user.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
