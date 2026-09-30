import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class PaymentsProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  // Filtros activos
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String currentSearchTerm = '';

  // Estados de carga
  bool isLoading = false;
  bool isLoadingKpis = false;
  bool isLoadingHistorial = false;
  bool isLoadingPendientes = false;
  String? errorMessage;

  // Contador global para el badge del Sidebar
  int globalPendingCount = 0;

  // Paginación: Historial (pagado = true)
  List<Pago> historial = [];
  int pageHistorial = 0;
  int sizeHistorial = 30;
  int totalElementsHistorial = 0;
  int totalPagesHistorial = 0;

  // Paginación: Pendientes (pagado = false)
  List<Pago> pendientes = [];
  int pagePendientes = 0;
  int sizePendientes = 30;
  int totalElementsPendientes = 0;
  int totalPagesPendientes = 0;

  // Métricas financieras (KPIs)
  double totalCobrado = 0.0;
  double totalPendiente = 0.0;
  double totalEfectivo = 0.0;
  int cantidadEfectivo = 0;
  double totalBonos = 0.0;
  int cantidadBonos = 0;
  double porcentajeBonos = 0.0;
  int totalVentas = 0;

  // Getters para tabs y compatibilidad
  double get totalEfectivoHoy => totalEfectivo;
  int get cantidadEfectivoHoy => cantidadEfectivo;
  int get totalHistorialCount => totalElementsHistorial;
  int get totalPendientesCount => totalElementsPendientes;
  bool get hasMoreHistorial => (pageHistorial + 1) < totalPagesHistorial;
  bool get hasMorePendientes => (pagePendientes + 1) < totalPagesPendientes;

  PaymentsProvider() {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1, 0, 0, 0);
    final fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    setDateRange(inicio, fin);
    checkPendingCount();
  }

  /// Métodos de compatibilidad hacia atrás
  void loadAll([DateTime? inicio, DateTime? fin]) {
    setDateRange(inicio, fin);
  }

  Future<void> loadData(DateTime inicio, DateTime fin) async {
    setDateRange(inicio, fin);
  }

  /// Comprueba el conteo de pendientes de un cliente o el global (usado por modal de venta y sidebar)
  Future<int> checkPendingCount([int? id]) async {
    if (id != null) {
      try {
        final response = await ApiService.dio.get('$_baseUrl/pagos/cliente/$id');
        if (response.statusCode == 200) {
          final List data = response.data is List ? response.data : (response.data['content'] ?? []);
          final count = data.where((p) => p['pagado'] == false).length;
          globalPendingCount = count;
          notifyListeners();
          return count;
        }
      } catch (e) {
        debugPrint("Error checkPendingCount cliente: $e");
      }
      return 0;
    }

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos',
        queryParameters: {'pagado': false, 'page': 0, 'size': 1},
      );
      if (response.data is Map) {
        globalPendingCount = (response.data['totalElements'] as num?)?.toInt() ?? 0;
        notifyListeners();
        return globalPendingCount;
      }
    } catch (e) {
      debugPrint("Error checkPendingCount global: $e");
    }
    return globalPendingCount;
  }

  /// Obtiene los pagos de un cliente específico (usado en document_upload_dialog)
  Future<List<Pago>> fetchPagosCliente(int idCliente) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/pagos/cliente/$idCliente',
        queryParameters: {'size': 500, 'sort': 'fechaPago,desc'},
      );
      final rawList = response.data is Map
          ? (response.data['content'] ?? [])
          : (response.data ?? []);
      return (rawList as List).map((json) => Pago.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetchPagosCliente: ${ErrorHandler.extractMessage(e)}');
      return [];
    }
  }

  /// Aplica el rango de fechas, resetea las páginas a cero y dispara las peticiones HTTP
  void setDateRange(DateTime? inicio, DateTime? fin) {
    fechaInicio = inicio;
    fechaFin = fin;
    pageHistorial = 0;
    pagePendientes = 0;

    loadKpis(inicio, fin);
    loadPagos(inicio: inicio, fin: fin, page: 0, size: sizeHistorial, pagado: true);
    loadPagos(inicio: inicio, fin: fin, page: 0, size: sizePendientes, pagado: false);
  }

  /// Actualiza el término de búsqueda con reseteo de página
  void onSearchChanged(String search) {
    currentSearchTerm = search.trim();
    pageHistorial = 0;
    pagePendientes = 0;

    loadPagos(inicio: fechaInicio, fin: fechaFin, page: 0, size: sizeHistorial, pagado: true);
    loadPagos(inicio: fechaInicio, fin: fechaFin, page: 0, size: sizePendientes, pagado: false);
  }

  /// Cambia de página en el listado de Historial
  void setHistorialPage(int newPage) {
    if (newPage < 0 || (totalPagesHistorial > 0 && newPage >= totalPagesHistorial)) return;
    loadPagos(inicio: fechaInicio, fin: fechaFin, page: newPage, size: sizeHistorial, pagado: true);
  }

  /// Cambia de página en el listado de Pendientes
  void setPendientesPage(int newPage) {
    if (newPage < 0 || (totalPagesPendientes > 0 && newPage >= totalPagesPendientes)) return;
    loadPagos(inicio: fechaInicio, fin: fechaFin, page: newPage, size: sizePendientes, pagado: false);
  }

  /// Carga y calcula las métricas financieras (KPIs) en base al rango de fechas
  Future<void> loadKpis([DateTime? inicio, DateTime? fin]) async {
    isLoadingKpis = true;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};

      if (inicio != null) {
        final startIso = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0).toIso8601String();
        params['fechaInicio'] = startIso;
        params['inicio'] = startIso;
      }
      if (fin != null) {
        final endIso = DateTime(fin.year, fin.month, fin.day, 23, 59, 59).toIso8601String();
        params['fechaFin'] = endIso;
        params['fin'] = endIso;
      }

      // Balance y métricas oficiales calculadas directamente por el backend
      final respBalance = await ApiService.dio.get(
        '$_baseUrl/pagos/balance',
        queryParameters: params,
      );

      if (respBalance.statusCode == 200 && respBalance.data != null) {
        final data = respBalance.data;
        totalCobrado = (data['totalCobrado'] as num?)?.toDouble() ?? 0.0;
        totalPendiente = (data['totalPendiente'] as num?)?.toDouble() ?? 0.0;
        totalEfectivo = (data['totalEfectivo'] as num?)?.toDouble() ?? 0.0;
        cantidadEfectivo = (data['cantidadEfectivo'] as num?)?.toInt() ?? 0;
        totalBonos = (data['totalBonos'] as num?)?.toDouble() ?? 0.0;
        cantidadBonos = (data['cantidadBonos'] as num?)?.toInt() ?? 0;
        porcentajeBonos = (data['porcentajeBonos'] as num?)?.toDouble() ?? 0.0;
        totalVentas = (data['cantidadVentas'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('Error en loadKpis: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoadingKpis = false;
      notifyListeners();
    }
  }

  /// Carga la lista paginada de pagos desde el backend Spring Boot
  /// Carga la siguiente página de Historial concatenando resultados si hay más páginas
  Future<void> loadMoreHistorial() async {
    if (isLoadingHistorial || isLoading) return;
    if (pageHistorial + 1 >= totalPagesHistorial) return;

    await loadPagos(
      inicio: fechaInicio,
      fin: fechaFin,
      page: pageHistorial + 1,
      size: sizeHistorial,
      pagado: true,
    );
  }

  /// Carga la siguiente página de Pendientes concatenando resultados si hay más páginas
  Future<void> loadMorePendientes() async {
    if (isLoadingPendientes || isLoading) return;
    if (pagePendientes + 1 >= totalPagesPendientes) return;

    await loadPagos(
      inicio: fechaInicio,
      fin: fechaFin,
      page: pagePendientes + 1,
      size: sizePendientes,
      pagado: false,
    );
  }

  /// Carga la lista paginada de pagos desde el backend Spring Boot
  Future<void> loadPagos({
    DateTime? inicio,
    DateTime? fin,
    int page = 0,
    int size = 30,
    bool? pagado,
  }) async {
    final bool cargarHistorial = pagado == null || pagado == true;
    final bool cargarPendientes = pagado == null || pagado == false;

    if (cargarHistorial) isLoadingHistorial = true;
    if (cargarPendientes) isLoadingPendientes = true;
    isLoading = isLoadingHistorial || isLoadingPendientes;
    notifyListeners();

    try {
      // 1. Cargar Historial (pagado = true)
      if (cargarHistorial) {
        final Map<String, dynamic> paramsHistorial = {
          'pagado': true,
          'page': page,
          'size': size,
        };

        if (inicio != null) {
          final startIso = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0).toIso8601String();
          paramsHistorial['fechaInicio'] = startIso;
          paramsHistorial['inicio'] = startIso;
        }
        if (fin != null) {
          final endIso = DateTime(fin.year, fin.month, fin.day, 23, 59, 59).toIso8601String();
          paramsHistorial['fechaFin'] = endIso;
          paramsHistorial['fin'] = endIso;
        }
        if (currentSearchTerm.isNotEmpty) {
          paramsHistorial['search'] = currentSearchTerm;
        }

        final respHist = await ApiService.dio.get(
          '$_baseUrl/pagos',
          queryParameters: paramsHistorial,
        );

        if (respHist.data is Map) {
          final Map<String, dynamic> pageData = respHist.data;
          final List content = pageData['content'] ?? [];
          final nuevosDatos = content.map((e) => Pago.fromJson(e)).toList();

          if (page == 0) {
            historial = nuevosDatos;
          } else {
            historial.addAll(nuevosDatos);
          }

          totalElementsHistorial = (pageData['totalElements'] as num?)?.toInt() ?? historial.length;
          totalPagesHistorial = (pageData['totalPages'] as num?)?.toInt() ?? 1;
          pageHistorial = page;
          sizeHistorial = size;
        } else if (respHist.data is List) {
          final nuevosDatos = (respHist.data as List).map((e) => Pago.fromJson(e)).toList();
          if (page == 0) {
            historial = nuevosDatos;
          } else {
            historial.addAll(nuevosDatos);
          }
          totalElementsHistorial = historial.length;
          totalPagesHistorial = 1;
          pageHistorial = 0;
        }
      }

      // 2. Cargar Pendientes (pagado = false)
      if (cargarPendientes) {
        final int targetPage = cargarHistorial ? pagePendientes : page;
        final Map<String, dynamic> paramsPendientes = {
          'pagado': false,
          'page': targetPage,
          'size': sizePendientes,
        };

        if (currentSearchTerm.isNotEmpty) {
          paramsPendientes['search'] = currentSearchTerm;
        }

        final respPend = await ApiService.dio.get(
          '$_baseUrl/pagos',
          queryParameters: paramsPendientes,
        );

        if (respPend.data is Map) {
          final Map<String, dynamic> pageData = respPend.data;
          final List content = pageData['content'] ?? [];
          final nuevosDatos = content.map((e) => Pago.fromJson(e)).toList();

          if (targetPage == 0) {
            pendientes = nuevosDatos;
          } else {
            pendientes.addAll(nuevosDatos);
          }

          totalElementsPendientes = (pageData['totalElements'] as num?)?.toInt() ?? pendientes.length;
          totalPagesPendientes = (pageData['totalPages'] as num?)?.toInt() ?? 1;
          globalPendingCount = totalElementsPendientes;
          pagePendientes = targetPage;
        } else if (respPend.data is List) {
          final nuevosDatos = (respPend.data as List).map((e) => Pago.fromJson(e)).toList();
          if (targetPage == 0) {
            pendientes = nuevosDatos;
          } else {
            pendientes.addAll(nuevosDatos);
          }
          totalElementsPendientes = pendientes.length;
          totalPagesPendientes = 1;
          globalPendingCount = totalElementsPendientes;
          pagePendientes = 0;
        }
      }
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      debugPrint('Error en loadPagos: $errorMessage');
    } finally {
      if (cargarHistorial) isLoadingHistorial = false;
      if (cargarPendientes) isLoadingPendientes = false;
      isLoading = isLoadingHistorial || isLoadingPendientes;
      notifyListeners();
    }
  }

  /// Confirma el cobro de un pago pendiente y refresca el balance y las listas
  Future<String?> confirmarPago(int idPago) async {
    try {
      await ApiService.dio.put('$_baseUrl/pagos/$idPago/confirmar');

      // Refrescar KPIs y listas tras la confirmación exitosa
      pagePendientes = 0;
      pageHistorial = 0;
      loadKpis(fechaInicio, fechaFin);
      loadPagos(inicio: fechaInicio, fin: fechaFin, page: 0, size: sizePendientes, pagado: false);
      loadPagos(inicio: fechaInicio, fin: fechaFin, page: 0, size: sizeHistorial, pagado: true);
      checkPendingCount();

      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  /// Limpia todos los datos al cerrar sesión
  void clearAllData() {
    historial = [];
    pendientes = [];
    totalElementsHistorial = 0;
    totalElementsPendientes = 0;
    totalPagesHistorial = 0;
    totalPagesPendientes = 0;
    pageHistorial = 0;
    pagePendientes = 0;
    totalCobrado = 0.0;
    totalPendiente = 0.0;
    totalEfectivo = 0.0;
    cantidadEfectivo = 0;
    totalBonos = 0.0;
    cantidadBonos = 0;
    porcentajeBonos = 0.0;
    totalVentas = 0;
    globalPendingCount = 0;
    isLoading = false;
    notifyListeners();
  }
}