import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String uuid;
  final String? username;
  final String? email;
  final String mobile;
  final UserRole role;
  final double balance;
  final double rating;
  final int numberOfRatings;
  final bool isActive;
  final bool emailVerified;
  final bool mobileVerified;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.uuid,
    this.username,
    this.email,
    required this.mobile,
    required this.role,
    this.balance = 0.0,
    this.rating = 0.0,
    this.numberOfRatings = 0,
    this.isActive = true,
    this.emailVerified = false,
    this.mobileVerified = false,
    this.lastLogin,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      username: map['username'] as String?,
      email: map['email'] as String?,
      mobile: map['mobile'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: map['no_of_ratings'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      emailVerified: map['email_verified'] as bool? ?? false,
      mobileVerified: map['mobile_verified'] as bool? ?? false,
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  User copyWith({
    int? id,
    String? uuid,
    String? username,
    String? email,
    String? mobile,
    UserRole? role,
    double? balance,
    double? rating,
    int? numberOfRatings,
    bool? isActive,
    bool? emailVerified,
    bool? mobileVerified,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      rating: rating ?? this.rating,
      numberOfRatings: numberOfRatings ?? this.numberOfRatings,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      mobileVerified: mobileVerified ?? this.mobileVerified,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.uuid == uuid;
  }

  @override
  int get hashCode => Object.hash(id, uuid);

  @override
  String toString() {
    return 'User(id: $id, uuid: $uuid, username: $username, email: $email, mobile: $mobile, role: $role)';
  }
}

@JsonSerializable()
class CreateUserRequest {
  final String? username;
  final String? email;
  final String mobile;
  final String password;
  final UserRole role;

  const CreateUserRequest({
    this.username,
    this.email,
    required this.mobile,
    required this.password,
    this.role = UserRole.customer,
  });

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) => _$CreateUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateUserRequestToJson(this);
}

@JsonSerializable()
class UpdateUserRequest {
  final String? username;
  final String? email;
  final String? mobile;
  final String? password;
  final UserRole? role;
  final bool? isActive;

  const UpdateUserRequest({
    this.username,
    this.email,
    this.mobile,
    this.password,
    this.role,
    this.isActive,
  });

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) => _$UpdateUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserRequestToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String mobile;
  final String password;

  const LoginRequest({
    required this.mobile,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final DateTime? expiresAt;

  const AuthResponse({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  factory AuthResponse.success({
    required String accessToken,
    required String refreshToken,
    required User user,
    required DateTime expiresAt,
    String? message,
  }) {
    return AuthResponse(
      success: true,
      message: message ?? 'Login successful',
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      expiresAt: expiresAt,
    );
  }

  factory AuthResponse.error(String message) {
    return AuthResponse(
      success: false,
      message: message,
    );
  }
}