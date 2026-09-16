import 'package:quiropractico_front/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class PaymentsProvider extends ChangeNotifier {
  
  final String _baseUrl = ApiConfig.baseUrl;

  List<Pago> historial = [];
  List<Pago> pendientes = [];
  
  bool isLoading = false;

  double get totalCobrado => historial.where((p) => p.pagado).fold(0, (sum, p) => sum + p.monto);
  double get totalPendiente => pendientes.fold(0, (sum, p) => sum + p.monto);
  double ingresosTotales = 0.0;
  String? errorMessage;
  int globalPendingCount = 0;

  Future<int> checkPendingCount([int? id]) async {
    if (id == null) return 0;
    try {
      final response = await ApiService.dio.get('$_baseUrl/pagos/cliente/$id');
      if (response.statusCode == 200) {
        List data = response.data;
        int count = data.where((p) => p['pagado'] == false).length;
        globalPendingCount = count;
        notifyListeners();
        return count;
      }
    } catch (e) {
      print("Error checkPendingCount: $e");
    }
    return 0;
  }

  int totalHistorialCount = 0;
  int totalPendientesCount = 0;
  String currentSearchTerm = '';
  
  bool isLoadingPendientes = false;
  bool isLoadingMorePendientes = false;
  bool hasMorePendientes = false;
  List<dynamic> listaPendientes = [];
  
  bool isLoadingHistorial = false;
  bool isLoadingMoreHistorial = false;
  bool hasMoreHistorial = false;
  List<dynamic> listaHistorial = [];

  void onSearchChanged(String search) {
    currentSearchTerm = search;
    notifyListeners();
  }

  void loadAll([DateTime? inicio, DateTime? fin]) {
    final now = DateTime.now();
    loadData(inicio ?? now, fin ?? now);
  }
  
  Future<void> loadMorePendientes() async {
    isLoadingMorePendientes = false;
    notifyListeners();
  }
  
  Future<void> loadMoreHistorial() async {
    isLoadingMoreHistorial = false;
    notifyListeners();
  }

  PaymentsProvider() {
    final now = DateTime.now();
    loadData(now, now); 
  }



  Future<void> loadData(DateTime inicio, DateTime fin) async {
    isLoading = true;
    notifyListeners();

    try {
      final startIso = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0).toIso8601String();
      final endIso = DateTime(fin.year, fin.month, fin.day, 23, 59, 59).toIso8601String();

      final respHist = await ApiService.dio.get(
        '$_baseUrl/pagos', 
        queryParameters: {'inicio': startIso, 'fin': endIso}
      );
      
      dynamic dataHist = respHist.data;
      if (dataHist is Map) {
        dataHist = dataHist['content'] ?? dataHist['data'] ?? dataHist['pagos'] ?? [];
      }
      historial = (dataHist as List).map((e) => Pago.fromJson(e)).toList();
      listaHistorial = historial;
      totalHistorialCount = historial.length;

      final respPend = await ApiService.dio.get(
        '$_baseUrl/pagos',
        queryParameters: {'pagado': false, 'size': 500}
      );
      
      dynamic dataPend = respPend.data;
      if (dataPend is Map) {
        dataPend = dataPend['content'] ?? dataPend['data'] ?? dataPend['pagos'] ?? [];
      }
      pendientes = (dataPend as List).map((e) => Pago.fromJson(e)).toList();
      listaPendientes = pendientes;
      totalPendientesCount = pendientes.length;

    } catch (e) {
      print("Error pagos: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> confirmarPago(int idPago) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/pagos/$idPago/confirmar'
      );
      
      final now = DateTime.now();
      loadData(now, now); 
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<List<Pago>> fetchPagosCliente(int idCliente) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos/cliente/$idCliente',
        queryParameters: {'size': 500, 'sort': 'fechaPago,desc'},
      );
      final rawList = response.data is Map ? (response.data['content'] ?? []) : (response.data ?? []);
      return (rawList as List).map((json) => Pago.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetchPagosCliente: ${ErrorHandler.extractMessage(e)}');
      return [];
    }
  }

  void clearAllData() {
    historial = [];
    pendientes = [];
    listaHistorial = [];
    listaPendientes = [];
    totalHistorialCount = 0;
    totalPendientesCount = 0;
    isLoading = false;
    globalPendingCount = 0;
    notifyListeners();
  }
}