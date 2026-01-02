import 'package:rabbit_ecosystem_dashboard/features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../../../core/network/api_client.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient apiClient;

  DashboardRepositoryImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await apiClient.get('/dashboard/analytics/overview');
    return response.data as Map<String, dynamic>;
  }
}
