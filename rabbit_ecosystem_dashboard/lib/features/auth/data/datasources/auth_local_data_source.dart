import '../../../core/storage/local_storage.dart';
import '../../../core/config/app_config.dart';

abstract class AuthLocalDataSource {
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String refreshToken);
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
  Future<void> saveToken(String token) async {
    await localStorage.setString(AppConfig.authTokenKey, token);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await localStorage.setString(AppConfig.refreshTokenKey, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await localStorage.remove(AppConfig.authTokenKey);
    await localStorage.remove(AppConfig.refreshTokenKey);
  }
}
