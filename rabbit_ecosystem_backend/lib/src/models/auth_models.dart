import 'user.dart';
import 'user_role.dart';

/// Request model for user registration
class CreateUserRequest {
  final String username;
  final String? email;
  final String mobile;
  final String password;
  final UserRole role;

  CreateUserRequest({
    required this.username,
    this.email,
    required this.mobile,
    required this.password,
    this.role = UserRole.customer,
  });

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) {
    return CreateUserRequest(
      username: json['username'] as String,
      email: json['email'] as String?,
      mobile: json['mobile'] as String,
      password: json['password'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.customer,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'mobile': mobile,
      'password': password,
      'role': role.name,
    };
  }
}

/// Request model for user login
class LoginRequest {
  final String mobile;
  final String password;

  LoginRequest({
    required this.mobile,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      mobile: json['mobile'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'password': password,
    };
  }
}

/// Response model for authentication operations
class AuthResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final DateTime? expiresAt;
  final String message;
  final String? error;

  AuthResponse({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.expiresAt,
    required this.message,
    this.error,
  });

  factory AuthResponse.success({
    required String accessToken,
    required String refreshToken,
    required User user,
    required DateTime expiresAt,
    required String message,
  }) {
    return AuthResponse(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      expiresAt: expiresAt,
      message: message,
    );
  }

  factory AuthResponse.error(String error) {
    return AuthResponse(
      success: false,
      message: error,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'expiresAt': expiresAt?.toIso8601String(),
      'message': message,
      'error': error,
    };
  }
}

/// Token pair model
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

/// JWT payload model
class JwtPayload {
  final int userId;
  final String userUuid;
  final UserRole userRole;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isAccessToken;
  final bool isRefreshToken;

  JwtPayload({
    required this.userId,
    required this.userUuid,
    required this.userRole,
    required this.issuedAt,
    required this.expiresAt,
    this.isAccessToken = false,
    this.isRefreshToken = false,
  });

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    return JwtPayload(
      userId: json['userId'] as int,
      userUuid: json['userUuid'] as String,
      userRole: UserRole.values.firstWhere(
        (r) => r.name == json['userRole'],
        orElse: () => UserRole.customer,
      ),
      issuedAt: DateTime.fromMillisecondsSinceEpoch((json['iat'] as int) * 1000),
      expiresAt: DateTime.fromMillisecondsSinceEpoch((json['exp'] as int) * 1000),
      isAccessToken: json['type'] == 'access',
      isRefreshToken: json['type'] == 'refresh',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userUuid': userUuid,
      'userRole': userRole.name,
      'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'type': isAccessToken ? 'access' : 'refresh',
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;
}