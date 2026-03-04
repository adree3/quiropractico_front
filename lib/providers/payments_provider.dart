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
  bool isLoadingMorePendientes = false;
  bool hasMorePendientes = true;

  // Tabla de historial
  List<Pago> listaHistorial = [];
  int pageHistorial = 0;
  int totalHistorialCount = 0;
  bool isLoadingHistorial = false;
  bool isLoadingMoreHistorial = false;
  bool hasMoreHistorial = true;

  // Filtros
  DateTime fechaInicio = DateTime(2000);
  DateTime fechaFin = DateTime(2100);
  String currentSearchTerm = '';
  final int pageSize = 15;
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
      loadAll(fechaInicio, fechaFin);
    });
  }

  Future<void> loadAll(DateTime start, DateTime end) async {
    fechaInicio = start;
    fechaFin = end;
    pagePendientes = 0;
    pageHistorial = 0;
    hasMorePendientes = true;
    hasMoreHistorial = true;

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
    bool append = false,
  }) async {
    if (notifyLoading) {
      if (append) {
        isLoadingMorePendientes = true;
      } else {
        isLoadingPendientes = true;
      }
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
      final totalPages = data['totalPages'];

      final newItems = content.map((e) => Pago.fromJson(e)).toList();

      if (append) {
        listaPendientes.addAll(newItems);
      } else {
        listaPendientes = newItems;
      }

      totalPendientesCount = data['totalElements'];
      hasMorePendientes = (page + 1) < totalPages;
    } catch (e) {
      print("Error pendientes: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoadingPendientes = false;
      isLoadingMorePendientes = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePendientes() async {
    if (isLoadingMorePendientes || !hasMorePendientes) return;
    await getPagosPendientes(page: pagePendientes + 1, append: true);
  }

  // Obtiene los pagos historial
  Future<void> getPagosHistorial({
    required int page,
    bool notifyLoading = true,
    bool append = false,
  }) async {
    if (notifyLoading) {
      if (append) {
        isLoadingMoreHistorial = true;
      } else {
        isLoadingHistorial = true;
      }
      notifyListeners();
    }
    pageHistorial = page;

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
      final totalPages = data['totalPages'];

      final newItems = content.map((e) => Pago.fromJson(e)).toList();

      if (append) {
        listaHistorial.addAll(newItems);
      } else {
        listaHistorial = newItems;
      }

      totalHistorialCount = data['totalElements'];
      hasMoreHistorial = (page + 1) < totalPages;
    } catch (e) {
      print("Error historial: ${ErrorHandler.extractMessage(e)}");
    } finally {
      isLoadingHistorial = false;
      isLoadingMoreHistorial = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistorial() async {
    if (isLoadingMoreHistorial || !hasMoreHistorial) return;
    await getPagosHistorial(page: pageHistorial + 1, append: true);
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

        if (listaPendientes.isEmpty && pagePendientes > 0) {
          getPagosPendientes(page: pagePendientes - 1);
        } else {
          getPagosPendientes(page: pagePendientes, notifyLoading: false);
        }
      }

      getPagosHistorial(page: 0);

      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> deshacerPago(int idPago) async {
    try {
      await ApiService.dio.put('$_baseUrl/pagos/$idPago/pendiente');

      final index = listaHistorial.indexWhere((p) => p.idPago == idPago);
      if (index != -1) {
        final pago = listaHistorial[index];

        totalCobrado -= pago.monto;
        totalPendiente += pago.monto;

        listaHistorial.removeAt(index);
        totalHistorialCount--;
      }

      getPagosPendientes(page: 0);
      getPagosHistorial(page: 0);
      checkPendingCount();
      _fetchKpis();

      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
