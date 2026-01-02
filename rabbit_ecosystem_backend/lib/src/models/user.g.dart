// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (json['numberOfRatings'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      emailVerified: json['emailVerified'] as bool? ?? false,
      mobileVerified: json['mobileVerified'] as bool? ?? false,
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'username': instance.username,
      'email': instance.email,
      'mobile': instance.mobile,
      'role': _$UserRoleEnumMap[instance.role]!,
      'balance': instance.balance,
      'rating': instance.rating,
      'numberOfRatings': instance.numberOfRatings,
      'isActive': instance.isActive,
      'emailVerified': instance.emailVerified,
      'mobileVerified': instance.mobileVerified,
      'lastLogin': instance.lastLogin?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.customer: 'customer',
  UserRole.partner: 'partner',
  UserRole.rider: 'rider',
  UserRole.dispatcher: 'dispatcher',
  UserRole.superAdmin: 'superAdmin',
  UserRole.admin: 'admin',
  UserRole.finance: 'finance',
  UserRole.marketing: 'marketing',
  UserRole.analytics: 'analytics',
  UserRole.support: 'support',
};

CreateUserRequest _$CreateUserRequestFromJson(Map<String, dynamic> json) =>
    CreateUserRequest(
      username: json['username'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String,
      password: json['password'] as String,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.customer,
    );

Map<String, dynamic> _$CreateUserRequestToJson(CreateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'mobile': instance.mobile,
      'password': instance.password,
      'role': _$UserRoleEnumMap[instance.role]!,
    };

UpdateUserRequest _$UpdateUserRequestFromJson(Map<String, dynamic> json) =>
    UpdateUserRequest(
      username: json['username'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      password: json['password'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']),
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateUserRequestToJson(UpdateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'mobile': instance.mobile,
      'password': instance.password,
      'role': _$UserRoleEnumMap[instance.role],
      'isActive': instance.isActive,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      mobile: json['mobile'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'mobile': instance.mobile,
      'password': instance.password,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };
