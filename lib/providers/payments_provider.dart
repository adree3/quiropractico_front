import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class PaymentsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Pago> historial = [];
  List<Pago> pendientes = [];
  
  bool isLoading = true;

  double get totalCobrado => historial.where((p) => p.pagado).fold(0, (sum, p) => sum + p.monto);
  double get totalPendiente => pendientes.fold(0, (sum, p) => sum + p.monto);

  PaymentsProvider() {
    final now = DateTime.now();
    loadData(now, now); 
  }

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> loadData(DateTime inicio, DateTime fin) async {
    isLoading = true;
    notifyListeners();

    try {
      final startIso = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0).toIso8601String();
      final endIso = DateTime(fin.year, fin.month, fin.day, 23, 59, 59).toIso8601String();

      final respHist = await _dio.get(
        '$_baseUrl/pagos', 
        queryParameters: {'inicio': startIso, 'fin': endIso}, 
        options: _authOptions
      );
      
      historial = (respHist.data as List).map((e) => Pago.fromJson(e)).toList();

      final respPend = await _dio.get(
        '$_baseUrl/pagos/pendientes', 
        options: _authOptions
      );
      
      pendientes = (respPend.data as List).map((e) => Pago.fromJson(e)).toList();

    } catch (e) {
      print("Error pagos: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> confirmarPago(int idPago) async {
    try {
      await _dio.put(
        '$_baseUrl/pagos/$idPago/confirmar', 
        options: _authOptions
      );
      
      final now = DateTime.now();
      loadData(now, now); 
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}