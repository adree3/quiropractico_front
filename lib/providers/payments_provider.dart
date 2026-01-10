import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class PaymentsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  bool isLoading = true;

  // KPIS
  double totalCobrado = 0;
  double totalPendiente = 0;

  // Tabla de pendientes
  List<Pago> listaPendientes = [];
  int pagePendientes = 0;
  int totalPendientesCount = 0;
  bool isLoadingPendientes = false;

  // Tabla de historial
  List<Pago> listaHistorial = [];
  int pageHistorial = 0;
  int totalHistorialCount = 0;
  bool isLoadingHistorial = false;

  // Filtros
  DateTime fechaInicio = DateTime(2000);
  DateTime fechaFin = DateTime(2100);
  String currentSearchTerm = '';
  final int pageSize = 8;
  Timer? _debounce;

  PaymentsProvider();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Buscador global
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      currentSearchTerm = query;
      loadAll(fechaInicio, fechaFin);
    });
  }

  // Helper para headers
  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${LocalStorage.getToken()}'});

  Future<void> loadAll(DateTime start, DateTime end) async {
    fechaInicio = start;
    fechaFin = end;
    pagePendientes = 0;
    pageHistorial = 0;

    isLoading = true;
    notifyListeners();

    // Cargamos todo en paralelo
    try {
      await Future.wait([
        _fetchKpis(),
        getPagosPendientes(page: 0),
        getPagosHistorial(page: 0),
      ]);
    } catch (e) {
      print("Error cargando dashboard pagos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Carga las tarjetas KPIs
  Future<void> _fetchKpis() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/pagos/balance',
        queryParameters: {
          'fechaInicio': fechaInicio.toIso8601String(),
          'fechaFin': fechaFin.toIso8601String(),
        },
        options: _authOptions,
      );

      if (response.data != null) {
        totalCobrado = (response.data['totalCobrado'] ?? 0).toDouble();
        totalPendiente = (response.data['totalPendiente'] ?? 0).toDouble();
      }
    } catch (e) {
      print("Error cargando KPIs: $e");
      totalCobrado = 0;
      totalPendiente = 0;
    }
    notifyListeners();
  }

  // Obtiene los pagos pendientes
  Future<void> getPagosPendientes({required int page}) async {
    isLoadingPendientes = true;
    pagePendientes = page;
    notifyListeners();

    try {
      final response = await _dio.get(
        '$_baseUrl/pagos',
        queryParameters: {
          'page': page,
          'size': pageSize,
          'pagado': false,
          if (currentSearchTerm.isNotEmpty) 'search': currentSearchTerm,
        },
        options: _authOptions,
      );

      final data = response.data;
      final List<dynamic> content = data['content'];

      listaPendientes = content.map((e) => Pago.fromJson(e)).toList();
      totalPendientesCount = data['totalElements'];
    } catch (e) {
      print("Error pendientes: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoadingPendientes = false;
      notifyListeners();
    }
  }

  // Obtiene los pagos historial
  Future<void> getPagosHistorial({required int page}) async {
    isLoadingHistorial = true;
    pageHistorial = page;
    notifyListeners();

    try {
      final response = await _dio.get(
        '$_baseUrl/pagos',
        queryParameters: {
          'page': page,
          'size': pageSize,
          'pagado': true,
          'fechaInicio': fechaInicio.toIso8601String(),
          'fechaFin': fechaFin.toIso8601String(),
          if (currentSearchTerm.isNotEmpty) 'search': currentSearchTerm,
        },
        options: _authOptions,
      );

      final data = response.data;
      final List<dynamic> content = data['content'];

      listaHistorial = content.map((e) => Pago.fromJson(e)).toList();
      totalHistorialCount = data['totalElements'];
    } catch (e) {
      print("Error historial: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoadingHistorial = false;
      notifyListeners();
    }
  }

  Future<String?> confirmarPago(int idPago) async {
    try {
      // 1. Llamada API
      await _dio.put(
        '$_baseUrl/pagos/$idPago/confirmar',
        options: _authOptions,
      );

      // 2. Actualización Optimista (Local)
      final index = listaPendientes.indexWhere((p) => p.idPago == idPago);
      if (index != -1) {
        final pago = listaPendientes[index];

        // Actualizar KPIs
        totalCobrado += pago.monto;
        totalPendiente -= pago.monto;

        // Remover de la lista
        listaPendientes.removeAt(index);
        totalPendientesCount--;

        notifyListeners(); // Actualiza UI inmediatamente sin spinner global
      }

      // 3. Actualizar Historial en segundo plano (silencioso)
      getPagosHistorial(page: 0);

      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
