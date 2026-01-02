import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  final DashboardRepository repository;

  GetDashboardStatsUseCase({required this.repository});

  Future<Map<String, dynamic>> call() async {
    return await repository.getDashboardStats();
  }
}

