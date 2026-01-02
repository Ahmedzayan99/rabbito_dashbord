import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../models/user_role.dart';

class JwtService {
  static const String _defaultSecret = 'rabbit_ecosystem_super_secret_jwt_key_2024_production_ready';
  static const Duration _defaultAccessTokenExpiry = Duration(hours: 24);
  static const Duration _defaultRefreshTokenExpiry = Duration(days: 30);

  final String _secret;
  final Duration _accessTokenExpiry;
  final Duration _refreshTokenExpiry;

  JwtService({
    String? secret,
    Duration? accessTokenExpiry,
    Duration? refreshTokenExpiry,
  })  : _secret = secret ?? Platform.environment['JWT_SECRET'] ?? _defaultSecret,
        _accessTokenExpiry = accessTokenExpiry ?? _defaultAccessTokenExpiry,
        _refreshTokenExpiry = refreshTokenExpiry ?? _defaultRefreshTokenExpiry;

  /// Generate access token for user
  String generateAccessToken(User user) {
    final now = DateTime.now();
    final expiresAt = now.add(_accessTokenExpiry);

    final jwt = JWT({
      'sub': user.id.toString(),
      'uuid': user.uuid,
      'mobile': user.mobile,
      'email': user.email,
      'role': user.role.value,
      'permissions': user.role.permissions,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'type': 'access',
    });

    return jwt.sign(SecretKey(_secret), algorithm: JWTAlgorithm.HS256);
  }

  /// Generate refresh token for user
  String generateRefreshToken(User user) {
    final now = DateTime.now();
    final expiresAt = now.add(_refreshTokenExpiry);

    final jwt = JWT({
      'sub': user.id.toString(),
      'uuid': user.uuid,
      'mobile': user.mobile,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'type': 'refresh',
    });

    return jwt.sign(SecretKey(_secret), algorithm: JWTAlgorithm.HS256);
  }

  /// Validate and decode JWT token
  JwtPayload? validateToken(String token) {
    try {
      // First check if token is expired without verification
      if (isTokenExpired(token)) {
        return null; // Token expired
      }
      
      final jwt = JWT.verify(token, SecretKey(_secret));
      final payload = jwt.payload as Map<String, dynamic>;

      return JwtPayload.fromMap(payload);
    } on JWTExpiredException {
      return null; // Token expired
    } on JWTException {
      return null; // Invalid token
    } catch (e) {
      return null; // Invalid token
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  /// Extract user ID from token without validation
  int? extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final sub = payload['sub'] as String?;
      return sub != null ? int.tryParse(sub) : null;
    } catch (e) {
      return null;
    }
  }

  /// Generate token pair (access + refresh)
  TokenPair generateTokenPair(User user) {
    return TokenPair(
      accessToken: generateAccessToken(user),
      refreshToken: generateRefreshToken(user),
      expiresAt: DateTime.now().add(_accessTokenExpiry),
    );
  }

  /// Create secure hash for refresh token storage
  String hashRefreshToken(String token) {
    final bytes = utf8.encode(token + _secret);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class JwtPayload {
  final int userId;
  final String uuid;
  final String mobile;
  final String? email;
  final UserRole role;
  final List<String> permissions;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String type;

  JwtPayload({
    required this.userId,
    required this.uuid,
    required this.mobile,
    this.email,
    required this.role,
    required this.permissions,
    required this.issuedAt,
    required this.expiresAt,
    required this.type,
  });

  factory JwtPayload.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'access';
    return JwtPayload(
      userId: int.parse(map['sub'] as String),
      uuid: map['uuid'] as String,
      mobile: map['mobile'] as String? ?? '',
      email: map['email'] as String?,
      role: type == 'refresh' ? UserRole.customer : UserRole.fromString(map['role'] as String? ?? 'customer'),
      permissions: type == 'refresh' ? [] : List<String>.from(map['permissions'] as List? ?? []),
      issuedAt: DateTime.fromMillisecondsSinceEpoch((map['iat'] as int) * 1000),
      expiresAt: DateTime.fromMillisecondsSinceEpoch((map['exp'] as int) * 1000),
      type: type,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAccessToken => type == 'access';
  bool get isRefreshToken => type == 'refresh';

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool canAccessDashboard() {
    return role.canAccessDashboard;
  }

  bool canAccessMobileAPI() {
    return role.canAccessMobileAPI;
  }
}

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
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'token_type': 'Bearer',
    };
  }
}