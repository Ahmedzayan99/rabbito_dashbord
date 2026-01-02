import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'base_controller.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Controller for user-related API endpoints
class UserController {
  static UserService? _userService;

  static void initialize(UserService userService) {
    _userService = userService;
  }

  /// POST /api/mobile/auth/register
  static Future<Response> register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final mobile = data['mobile'] as String?;
      final password = data['password'] as String?;
      final username = data['username'] as String?;
      final email = data['email'] as String?;
      final roleString = data['role'] as String? ?? 'customer';

      if (mobile == null || password == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Mobile and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final role = UserRole.fromString(roleString);
      
      final result = await _userService!.registerUser(
        mobile: mobile,
        password: password,
        username: username,
        email: email,
        role: role,
      );

      final statusCode = result.success ? HttpStatus.created : HttpStatus.badRequest;
      
      return Response(
        statusCode,
        body: json.encode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Registration failed: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/mobile/auth/login
  static Future<Response> login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final identifier = data['identifier'] as String?; // mobile or email
      final password = data['password'] as String?;

      if (identifier == null || password == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Identifier and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _userService!.loginUser(
        identifier: identifier,
        password: password,
      );

      final statusCode = result.success ? HttpStatus.ok : HttpStatus.unauthorized;
      
      return Response(
        statusCode,
        body: json.encode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Login failed: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/mobile/auth/refresh
  static Future<Response> refreshToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final refreshToken = data['refresh_token'] as String?;

      if (refreshToken == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Refresh token is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _userService!.refreshToken(refreshToken);

      final statusCode = result.success ? HttpStatus.ok : HttpStatus.unauthorized;
      
      return Response(
        statusCode,
        body: json.encode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Token refresh failed: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/mobile/auth/logout
  static Future<Response> logout(Request request) async {
    try {
      // In a real implementation, you would invalidate the refresh token
      // For now, just return success
      return Response(
        HttpStatus.ok,
        body: json.encode({'success': true, 'message': 'Logged out successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Logout failed: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/mobile/auth/me
  static Future<Response> getCurrentUser(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'user': user.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to get user: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/mobile/user/profile
  static Future<Response> getProfile(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final profile = await _userService!.getUserProfile(user.id);
      
      if (profile == null) {
        return Response(
          HttpStatus.notFound,
          body: json.encode({'success': false, 'message': 'Profile not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'profile': profile.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to get profile: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// PUT /api/mobile/user/profile
  static Future<Response> updateProfile(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final username = data['username'] as String?;
      final email = data['email'] as String?;

      final updatedProfile = await _userService!.updateUserProfile(
        user.id,
        username: username,
        email: email,
      );

      if (updatedProfile == null) {
        return Response(
          HttpStatus.notFound,
          body: json.encode({'success': false, 'message': 'Profile not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'message': 'Profile updated successfully',
          'profile': updatedProfile.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: json.encode({'success': false, 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/mobile/user/addresses
  static Future<Response> getAddresses(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // This would use AddressRepository in a real implementation
      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'addresses': [], // Placeholder
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to get addresses: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/mobile/user/addresses
  static Future<Response> createAddress(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Validate required fields
      final title = data['title'] as String?;
      final address = data['address'] as String?;
      final latitude = data['latitude'] as double?;
      final longitude = data['longitude'] as double?;

      if (title == null || address == null || latitude == null || longitude == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Title, address, latitude, and longitude are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // This would use AddressRepository in a real implementation
      return Response(
        HttpStatus.created,
        body: json.encode({
          'success': true,
          'message': 'Address created successfully',
          'address': {
            'id': DateTime.now().millisecondsSinceEpoch, // Placeholder ID
            'user_id': user.id,
            'title': title,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'created_at': DateTime.now().toIso8601String(),
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to create address: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// PUT /api/mobile/user/addresses/<addressId>
  static Future<Response> updateAddress(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final addressId = request.params['addressId'];
      if (addressId == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Address ID is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // This would use AddressRepository in a real implementation
      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'message': 'Address updated successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to update address: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// DELETE /api/mobile/user/addresses/<addressId>
  static Future<Response> deleteAddress(Request request) async {
    try {
      final user = request.context['user'] as User?;
      
      if (user == null) {
        return Response(
          HttpStatus.unauthorized,
          body: json.encode({'success': false, 'message': 'Authentication required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final addressId = request.params['addressId'];
      if (addressId == null) {
        return Response(
          HttpStatus.badRequest,
          body: json.encode({'success': false, 'message': 'Address ID is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // This would use AddressRepository in a real implementation
      return Response(
        HttpStatus.ok,
        body: json.encode({
          'success': true,
          'message': 'Address deleted successfully',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: json.encode({'success': false, 'message': 'Failed to delete address: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Dashboard endpoints (admin only)

  /// GET /api/dashboard/users
  static Future<Response> getUsers(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(user, 'users.read')) {
        return BaseController.forbidden();
      }

      // Parse query parameters
      final pagination = BaseController.getPaginationParams(request);
      final search = request.url.queryParameters['search'];
      final roleFilter = request.url.queryParameters['role'];

      UserRole? role;
      if (roleFilter != null) {
        role = UserRole.fromString(roleFilter);
      }

      List<User> users;
      if (search != null && search.isNotEmpty) {
        users = await _userService!.searchUsers(search,
          limit: pagination['limit'],
          offset: pagination['offset']
        );
      } else if (role != null) {
        users = await _userService!.getUsersByRole(role);
      } else {
        users = await _userService!.getUsers(
          limit: pagination['limit'],
          offset: pagination['offset']
        );
      }

      final totalCount = await _userService!.getTotalUserCount();

      return BaseController.paginated(
        data: users.map((u) => u.toJson()).toList(),
        total: totalCount,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Users retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/users
  static Future<Response> createUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.create')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);

      // Validate required fields
      final errors = BaseController.validateRequiredFields(body, ['mobile', 'password']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final mobile = body!['mobile'] as String;
      final password = body['password'] as String;
      final username = body['username'] as String?;
      final email = body['email'] as String?;
      final roleString = body['role'] as String? ?? 'customer';

      final role = UserRole.fromString(roleString);

      final result = await _userService!.registerUser(
        mobile: mobile,
        password: password,
        username: username,
        email: email,
        role: role,
      );

      if (!result.success) {
        return BaseController.error(
          message: result.message,
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: result.user?.toJson(),
        message: 'User created successfully',
        statusCode: HttpStatus.created,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/users/<userId>
  static Future<Response> getUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.read')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final targetUser = await _userService!.getUserProfile(userId);

      if (targetUser == null) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        data: targetUser.toJson(),
        message: 'User retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/users/<userId>
  static Future<Response> updateUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.update')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      if (body == null) {
        return BaseController.error(
          message: 'Request body is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final username = body['username'] as String?;
      final email = body['email'] as String?;
      final roleString = body['role'] as String?;
      final isActive = body['is_active'] as bool?;

      UserRole? role;
      if (roleString != null) {
        role = UserRole.fromString(roleString);
      }

      final updateRequest = UpdateUserRequest(
        username: username,
        email: email,
        role: role,
        isActive: isActive,
      );

      final updatedUser = await _userService!.updateUser(userId, updateRequest);

      if (updatedUser == null) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        data: updatedUser.toJson(),
        message: 'User updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /api/dashboard/users/<userId>
  static Future<Response> deleteUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.delete')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final success = await _userService!.deleteUser(userId);

      if (!success) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        message: 'User deleted successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/users/statistics
  static Future<Response> getUserStatistics(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final statistics = await _userService!.getUserStatistics();

      return BaseController.success(
        data: statistics,
        message: 'User statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/users/<userId>/activate
  static Future<Response> activateUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.update')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final updatedUser = await _userService!.activateUser(userId);

      if (updatedUser == null) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        data: updatedUser.toJson(),
        message: 'User activated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/users/<userId>/deactivate
  static Future<Response> deactivateUser(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.update')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final updatedUser = await _userService!.deactivateUser(userId);

      if (updatedUser == null) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        data: updatedUser.toJson(),
        message: 'User deactivated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/users/<userId>/role
  static Future<Response> updateUserRole(Request request) async {
    try {
      final currentUser = BaseController.getUserFromRequest(request);

      if (!BaseController.hasPermission(currentUser, 'users.update')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['role']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final roleString = body!['role'] as String;
      final newRole = UserRole.fromString(roleString);

      final updatedUser = await _userService!.updateUserRole(userId, newRole);

      if (updatedUser == null) {
        return BaseController.notFound('User not found');
      }

      return BaseController.success(
        data: updatedUser.toJson(),
        message: 'User role updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}