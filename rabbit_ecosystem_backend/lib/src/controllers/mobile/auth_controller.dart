import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class AuthController {
  static final AuthService _authService = AuthService();
  
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
      
      return Response.ok(
        jsonEncode({
          'token': result['token'],
          'refreshToken': result['refreshToken'],
          'user': result['user'].toJson(),
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
  
  static Future<Response> register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final user = User.fromJson(data);
      final password = data['password'] as String?;
      
      if (password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Password is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final result = await _authService.register(user, password);
      
      if (result == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Registration failed'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode({
          'token': result['token'],
          'refreshToken': result['refreshToken'],
          'user': result['user'].toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Future<Response> refresh(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final refreshToken = data['refreshToken'] as String?;
      
      if (refreshToken == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Refresh token is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final result = await _authService.refreshToken(refreshToken);
      
      if (result == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'Invalid refresh token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode({
          'token': result['token'],
          'refreshToken': result['refreshToken'],
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