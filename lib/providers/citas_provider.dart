import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/citas_kpi.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class CitasProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Cita> citas = [];
  CitasKpi? kpis;

  bool isLoading = true;
  String? errorMessage;

  String currentSearchTerm = '';
  String?
  filterEstado; // null, 'programada', 'completada', 'cancelada', 'ausente'
  DateTime? filterFechaInicio;
  DateTime? filterFechaFin;

  int currentPage = 0;
  int pageSize = 10;
  int totalPages = 0;
  int totalElements = 0;

  CitasProvider() {
    loadCitas(page: 0);
  }

  Future<void> loadCitas({
    int page = 0,
    bool resetPage = false,
    bool notifyLoading = true,
  }) async {
    if (resetPage) currentPage = 0;
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;
    errorMessage = null;

    try {
      final Map<String, dynamic> params = {
        'page': page,
        'size': pageSize,
        'sort': 'fechaHoraInicio,desc',
      };

      if (currentSearchTerm.isNotEmpty) params['search'] = currentSearchTerm;
      if (filterEstado != null) params['estado'] = filterEstado;
      if (filterFechaInicio != null)
        params['fechaInicio'] =
            filterFechaInicio!.toIso8601String().split('T')[0];
      if (filterFechaFin != null)
        params['fechaFin'] = filterFechaFin!.toIso8601String().split('T')[0];

      final response = await ApiService.dio.get(
        '$_baseUrl/citas',
        queryParameters: params,
      );

      final List<dynamic> data = response.data['content'];
      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];

      citas = data.map((json) => Cita.fromJson(json)).toList();

      // Load KPIs silently
      loadKpis();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadKpis() async {
    try {
      final Map<String, dynamic> params = {};
      if (currentSearchTerm.isNotEmpty) params['search'] = currentSearchTerm;
      if (filterEstado != null) params['estado'] = filterEstado;
      if (filterFechaInicio != null)
        params['fechaInicio'] =
            filterFechaInicio!.toIso8601String().split('T')[0];
      if (filterFechaFin != null)
        params['fechaFin'] = filterFechaFin!.toIso8601String().split('T')[0];

      final response = await ApiService.dio.get(
        '$_baseUrl/citas/kpis',
        queryParameters: params,
      );

      kpis = CitasKpi.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      print('Error cargando KPIs de Citas: $e');
    }
  }

  void setSearchTerm(String term) {
    currentSearchTerm = term;
    loadCitas(page: 0, resetPage: true);
  }

  void setFilterEstado(String? estado) {
    filterEstado = estado;
    loadCitas(page: 0, resetPage: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    filterFechaInicio = start;
    filterFechaFin = end;
    loadCitas(page: 0, resetPage: true);
  }

  void setPage(int newPage) {
    if (newPage >= 0 && newPage < totalPages) {
      loadCitas(page: newPage);
    }
  }

  Future<bool> changeCitaState(int idCita, String nuevoEstado) async {
    try {
      await ApiService.dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
      );
      await loadCitas(page: currentPage, notifyLoading: false);
      return true;
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      notifyListeners();
      return false;
    }
  }
}
