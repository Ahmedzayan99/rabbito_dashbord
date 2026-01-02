import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> login(String email, String password);
  Future<Either<Failure, void>> refreshToken(String refreshToken);
  Future<Either<Failure, void>> logout();
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserRole();
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> saveUserRole(String role);
  Future<void> clearTokens();
}

