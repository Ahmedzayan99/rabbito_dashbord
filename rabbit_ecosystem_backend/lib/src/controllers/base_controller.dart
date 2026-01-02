import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Base controller with common functionality for all controllers
abstract class BaseController {
  /// Get user from request context (set by auth middleware)
  static User? getUserFromRequest(Request request) {
    return request.context['user'] as User?;
  }

  /// Get ID parameter from request URL
  static int? getIdFromParams(Request request, String paramName) {
    final param = request.params[paramName];
    return param != null ? int.tryParse(param) : null;
  }

  /// Parse JSON body from request
  static Future<Map<String, dynamic>?> parseJsonBody(Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return null;
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      throw const HttpException('Invalid JSON body');
    }
  }

  /// Get query parameters from request
  static Map<String, String> getQueryParams(Request request) {
    return request.url.queryParameters;
  }

  /// Get search query parameter
  static String? getSearchQuery(Request request) {
    return request.url.queryParameters['search'];
  }

  /// Get pagination parameters from request
  static Map<String, dynamic> getPaginationParams(Request request) {
    final params = getQueryParams(request);
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    return {
      'page': page,
      'limit': limit,
      'offset': offset,
    };
  }

  /// Validate required fields in request body
  static List<String> validateRequiredFields(
    Map<String, dynamic>? body,
    List<String> requiredFields,
  ) {
    final errors = <String>[];

    if (body == null) {
      errors.add('Request body is required');
      return errors;
    }

    for (final field in requiredFields) {
      if (!body.containsKey(field) || body[field] == null || body[field] == '') {
        errors.add('$field is required');
      }
    }

    return errors;
  }

  /// Check if user has specific permission
  static bool hasPermission(User? user, String permission) {
    return user?.role.hasPermission(permission) ?? false;
  }

  /// Check if user has specific role
  static bool hasRole(User? user, UserRole role) {
    return user?.role == role;
  }

  /// Check if user can access resource (own resource or has permission)
  static bool canAccessResource(User? user, int resourceOwnerId, String permission) {
    if (user == null) return false;
    if (user.id == resourceOwnerId) return true;
    return hasPermission(user, permission);
  }

  /// Response helpers
  static Response success({
    dynamic data,
    String? message,
    int statusCode = HttpStatus.ok,
  }) {
    final response = <String, dynamic>{
      'success': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (message != null) response['message'] = message;
    if (data != null) response['data'] = data;

    return Response(
      statusCode,
      body: json.encode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response paginated({
    required dynamic data,
    required int total,
    required int page,
    required int limit,
    String? message,
    int statusCode = HttpStatus.ok,
  }) {
    final totalPages = (total / limit).ceil();
    final response = <String, dynamic>{
      'success': true,
      'data': data,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'total_pages': totalPages,
        'has_next': page < totalPages,
        'has_prev': page > 1,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (message != null) response['message'] = message;

    return Response(
      statusCode,
      body: json.encode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response error({
    String? message,
    List<String>? errors,
    int statusCode = HttpStatus.badRequest,
  }) {
    final response = <String, dynamic>{
      'success': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (message != null) response['message'] = message;
    if (errors != null && errors.isNotEmpty) response['errors'] = errors;

    return Response(
      statusCode,
      body: json.encode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response validationError(List<String> errors) {
    return error(
      message: 'Validation failed',
      errors: errors,
      statusCode: HttpStatus.badRequest,
    );
  }

  static Response unauthorized([String message = 'Authentication required']) {
    return error(
      message: message,
      statusCode: HttpStatus.unauthorized,
    );
  }

  static Response forbidden([String message = 'Access denied']) {
    return error(
      message: message,
      statusCode: HttpStatus.forbidden,
    );
  }

  static Response notFound([String message = 'Resource not found']) {
    return error(
      message: message,
      statusCode: HttpStatus.notFound,
    );
  }

  static Response serverError([String message = 'Internal server error']) {
    return error(
      message: message,
      statusCode: HttpStatus.internalServerError,
    );
  }

  /// Handle exceptions and return appropriate error response
  static Response handleException(dynamic e) {
    // Log the error (in a real app, you'd use a proper logger)
    print('Error: $e');

    if (e is HttpException) {
      return error(
        message: e.message,
        statusCode: HttpStatus.badRequest,
      );
    }

    return serverError('An unexpected error occurred');
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate mobile number format (Saudi format)
  static bool isValidMobile(String mobile) {
    // Saudi mobile number format: +966xxxxxxxxx or 05xxxxxxxx
    final saudiMobileRegex = RegExp(r'^(\+966|0)?5[0-9]{8}$');
    return saudiMobileRegex.hasMatch(mobile);
  }
}
