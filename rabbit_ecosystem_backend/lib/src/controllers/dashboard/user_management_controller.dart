import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';

class UserManagementController {
  static final UserService _userService = UserService();
  
  static Future<Response> getUsers(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final roleFilter = queryParams['role'];
      
      UserRole? role;
      if (roleFilter != null) {
        role = UserRole.values.firstWhere(
          (r) => r.name == roleFilter,
          orElse: () => UserRole.customer,
        );
      }
      
      final users = await _userService.getUsers(
        page: page,
        limit: limit,
        role: role,
      );
      
      return Response.ok(
        jsonEncode({
          'users': users.map((u) => u.toJson()).toList(),
          'page': page,
          'limit': limit,
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
  
  static Future<Response> createUser(Request request) async {
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
      
      final createdUser = await _userService.createUser(user, password);
      
      if (createdUser == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to create user'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(createdUser.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}