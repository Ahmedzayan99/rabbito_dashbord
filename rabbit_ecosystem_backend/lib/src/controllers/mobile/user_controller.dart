import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';

class UserController {
  // TODO: Initialize with proper repositories
  static final UserService _userService = UserService(null as dynamic, null as dynamic);
  
  static Future<Response> getProfile(Request request) async {
    try {
      final user = request.context['user'] as User;
      
      final userProfile = await _userService.getUserProfile(user.id);
      
      if (userProfile == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(userProfile.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Future<Response> updateProfile(Request request) async {
    try {
      final user = request.context['user'] as User;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final updateRequest = UpdateUserRequest.fromJson(data);
      final updatedUser = await _userService.updateUser(user.id, updateRequest);
      
      if (updatedUser == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to update profile'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(updatedUser.toJson()),
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