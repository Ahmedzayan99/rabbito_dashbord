import 'package:rabbit_ecosystem_dashboard/core/config/app_config.dart';
import 'package:rabbit_ecosystem_dashboard/core/storage/local_storage.dart';

abstract class AuthLocalDataSource {
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserRole();
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> saveUserRole(String role);
  Future<void> clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorage localStorage;

  AuthLocalDataSourceImpl({required this.localStorage});

  @override
  Future<String?> getToken() async {
    return await localStorage.getString(AppConfig.authTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await localStorage.getString(AppConfig.refreshTokenKey);
  }

  @override
  Future<String?> getUserRole() async {
    return await localStorage.getString(AppConfig.userDataKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await localStorage.setString(AppConfig.authTokenKey, token);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await localStorage.setString(AppConfig.refreshTokenKey, refreshToken);
  }

  @override
  Future<void> saveUserRole(String role) async {
    await localStorage.setString(AppConfig.userDataKey, role);
  }

  @override
  Future<void> clearTokens() async {
    await localStorage.remove(AppConfig.authTokenKey);
    await localStorage.remove(AppConfig.refreshTokenKey);
    await localStorage.remove(AppConfig.userDataKey);
  }
}

