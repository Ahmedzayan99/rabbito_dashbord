import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
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
  Future<Either<Failure, void>> login(String email, String password) async {
    try {
      final result = await remoteDataSource.login(email, password);

      // Save tokens and user role if login successful
      final token = result['token'];
      final refreshToken = result['refreshToken'];
      final user = result['user'];

      if (token != null) {
        await saveToken(token);
      }
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      if (user != null && user['role'] != null) {
        await saveUserRole(user['role']);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken(String refreshToken) async {
    try {
      final result = await remoteDataSource.refreshToken(refreshToken);

      // Save new tokens
      final token = result['token'];
      final newRefreshToken = result['refreshToken'];

      if (token != null) {
        await saveToken(token);
      }
      if (newRefreshToken != null) {
        await saveRefreshToken(newRefreshToken);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Token refresh failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await clearTokens();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Logout failed: ${e.toString()}'));
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
  Future<String?> getUserRole() async {
    return await localDataSource.getUserRole();
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
  Future<void> saveUserRole(String role) async {
    await localDataSource.saveUserRole(role);
  }

  @override
  Future<void> clearTokens() async {
    await localDataSource.clearTokens();
  }
}

