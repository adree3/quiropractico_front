import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/dashboard_stats.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class StatsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  DashboardStats? stats;
  bool isLoading = true;

  StatsProvider() {
    getStats();
  }

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> getStats() async {
    isLoading = true;
    notifyListeners();
  
    try {
      final response = await _dio.get(
        '$_baseUrl/stats/dashboard',
        options: _authOptions
      );

      stats = DashboardStats.fromJson(response.data);

    } catch (e) {
      print('Error cargando stats: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}