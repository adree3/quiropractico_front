import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/dashboard_stats.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class StatsProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  DashboardStats? stats;
  bool isLoading = true;

  Future<void> getStats() async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.get('$_baseUrl/stats/dashboard');

      stats = DashboardStats.fromJson(response.data);
    } catch (e) {
      debugPrint('Error cargando stats: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearAllData() {
    stats = null;
    isLoading = false;
    notifyListeners();
  }
}
