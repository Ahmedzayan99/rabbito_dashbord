import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await remoteDataSource.login(email, password);

      // Save tokens if login successful
      if (result['data'] != null) {
        final token = result['data']['accessToken'];
        final refreshToken = result['data']['refreshToken'];

        if (token != null) {
          await saveToken(token);
        }
        if (refreshToken != null) {
          await saveRefreshToken(refreshToken);
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final result = await remoteDataSource.refreshToken(refreshToken);

      // Save new tokens
      if (result['data'] != null) {
        final token = result['data']['accessToken'];
        final newRefreshToken = result['data']['refreshToken'];

        if (token != null) {
          await saveToken(token);
        }
        if (newRefreshToken != null) {
          await saveRefreshToken(newRefreshToken);
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await clearTokens();
    }
  }

  @override
  Future<String?> getToken() async {
    return await localDataSource.getToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    return await localDataSource.getRefreshToken();
  }

  @override
  Future<void> saveToken(String token) async {
    await localDataSource.saveToken(token);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await localDataSource.saveRefreshToken(refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await localDataSource.clearTokens();
  }
}
