import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/pago.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class PaymentsProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  bool isLoading = true;

  // KPIS
  double totalCobrado = 0;
  double totalPendiente = 0;

  // Badge global (Sidebar)
  int globalPendingCount = 0;

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

  PaymentsProvider() {
    checkPendingCount();
  }

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
      getPagosPendientes(page: 0);
      getPagosHistorial(page: 0);
    });
  }

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
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos/balance',
        queryParameters: {
          'fechaInicio': fechaInicio.toIso8601String(),
          'fechaFin': fechaFin.toIso8601String(),
        },
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
  Future<void> getPagosPendientes({
    required int page,
    bool notifyLoading = true,
  }) async {
    if (notifyLoading) {
      isLoadingPendientes = true;
      notifyListeners();
    }
    pagePendientes = page;

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos',
        queryParameters: {
          'page': page,
          'size': pageSize,
          'pagado': false,
          if (currentSearchTerm.isNotEmpty) 'search': currentSearchTerm,
        },
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
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos',
        queryParameters: {
          'page': page,
          'size': pageSize,
          'pagado': true,
          'fechaInicio': fechaInicio.toIso8601String(),
          'fechaFin': fechaFin.toIso8601String(),
          if (currentSearchTerm.isNotEmpty) 'search': currentSearchTerm,
        },
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

  // Comprobación ligera para el Sidebar
  Future<void> checkPendingCount() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos',
        queryParameters: {'page': 0, 'size': 1, 'pagado': false},
      );
      if (response.data != null && response.data['totalElements'] != null) {
        globalPendingCount = response.data['totalElements'];
        notifyListeners();
      }
    } catch (e) {
      print("Error comprobando badge pagos: $e");
    }
  }

  Future<String?> confirmarPago(int idPago) async {
    try {
      await ApiService.dio.put('$_baseUrl/pagos/$idPago/confirmar');

      final index = listaPendientes.indexWhere((p) => p.idPago == idPago);
      if (index != -1) {
        final pago = listaPendientes[index];

        totalCobrado += pago.monto;
        totalPendiente -= pago.monto;

        listaPendientes.removeAt(index);
        totalPendientesCount--;

        notifyListeners();
        checkPendingCount();

        notifyListeners();
        checkPendingCount();

        // Silent refresh to fill the gap (or handle empty page)
        if (listaPendientes.isEmpty && pagePendientes > 0) {
          // Si se vació la página, volvemos atrás (con loading normal o silent?)
          // Mejor normal para que se vea el cambio de página claro, o silent.
          getPagosPendientes(page: pagePendientes - 1);
        } else {
          // Rellenar hueco silenciosamente
          getPagosPendientes(page: pagePendientes, notifyLoading: false);
        }
      }

      getPagosHistorial(page: 0);

      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
