import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiService _api;
  DashboardRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  // GET /dashboard/stats — WebSocket + pull-to-refresh
  Future<DashboardStats> getStats() async {
    final response = await _api.get(ApiConstants.dashboardStats);
    return DashboardStats.fromJson(response.data);
  }
}
