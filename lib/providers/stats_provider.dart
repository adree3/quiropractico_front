import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/dashboard_stats.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class StatsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  DashboardStats? stats;
  bool isLoading = true;

  StatsProvider() {
    getStats();
  }

  Future<void> getStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/stats/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      stats = DashboardStats.fromJson(response.data);

    } catch (e) {
      print('Error cargando stats: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}