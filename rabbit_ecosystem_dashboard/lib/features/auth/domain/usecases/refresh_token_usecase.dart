import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  Future<Map<String, dynamic>> call(String refreshToken) async {
    return await repository.refreshToken(refreshToken);
  }
}
