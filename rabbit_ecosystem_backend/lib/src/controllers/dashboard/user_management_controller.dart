import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';

class UserManagementController {
  static final UserService _userService = UserService(null as dynamic, null as dynamic);
  
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
      
      final offset = (page - 1) * limit;
      final users = role != null
          ? await _userService.getUsersByRole(role)
          : await _userService.getUsers(
              limit: limit,
              offset: offset,
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

  static Future<Response> getUser(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.getUserProfile(id);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateUser(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final existingUser = await _userService.getUserProfile(id);
      if (existingUser == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create UpdateUserRequest
      final updateRequest = UpdateUserRequest(
        username: data['username'] as String?,
        email: data['email'] as String?,
        mobile: data['mobile'] as String?,
        role: data['role'] != null
            ? UserRole.values.firstWhere(
                (r) => r.name == data['role'],
                orElse: () => existingUser.role,
              )
            : null,
        isActive: data['isActive'] as bool?,
      );

      final result = await _userService.updateUser(id, updateRequest);
      if (result == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to update user'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteUser(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _userService.deleteUser(id);
      if (!success) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to delete user'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'User deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> toggleUserStatus(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.getUserProfile(id);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final updateRequest = UpdateUserRequest(
        isActive: !user.isActive,
      );

      final result = await _userService.updateUser(id, updateRequest);
      if (result == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to update user status'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getUserStatistics(Request request) async {
    try {
      final stats = await _userService.getUserStatistics();
      return Response.ok(
        jsonEncode(stats),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> activateUser(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.activateUser(id);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deactivateUser(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.deactivateUser(id);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateUserRole(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final userId = params?['userId'];
      final id = int.tryParse(userId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final roleString = data['role'] as String?;

      if (roleString == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Role is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final role = UserRole.values.firstWhere(
        (r) => r.name == roleString,
        orElse: () => UserRole.customer,
      );

      final user = await _userService.updateUserRole(id, role);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(user.toJson()),
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