import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  Future<Either<Failure, void>> call(String refreshToken) async {
    return await repository.refreshToken(refreshToken);
  }
}

