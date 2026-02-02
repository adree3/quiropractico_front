import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/auditoria_log.dart';

import 'package:quiropractico_front/services/api_service.dart';

class AuditoriaProvider extends ChangeNotifier {
  final String _baseUrl = '${ApiConfig.baseUrl}/auditoria';

  List<AuditoriaLog> logs = [];
  bool isLoading = true;

  int currentPage = 0;
  int pageSize = 20;
  int totalElements = 0;

  String? filtroEntidad;
  String? filtroAccion;
  String search = '';
  DateTime? fechaInicio;
  DateTime? fechaFin;

  AuditoriaProvider() {
    getLogs();
  }

  Future<void> getLogs({int page = 0}) async {
    isLoading = true;
    currentPage = page;
    notifyListeners();

    try {
      Map<String, dynamic> query = {
        'page': currentPage,
        'size': pageSize,
        'sort': 'fechaHora,desc',
      };
      if (filtroEntidad != null && filtroEntidad != "TODAS") {
        query['entidad'] = filtroEntidad;
      }
      if (filtroAccion != null && filtroAccion != "TODAS") {
        query['accion'] = filtroAccion;
      }
      if (search.isNotEmpty) {
        query['search'] = search;
      }
      if (fechaInicio != null) {
        query['fechaDesde'] = DateFormat('yyyy-MM-dd').format(fechaInicio!);
      }
      if (fechaFin != null) {
        query['fechaHasta'] = DateFormat('yyyy-MM-dd').format(fechaFin!);
      }

      final response = await ApiService.dio.get(
        _baseUrl,
        queryParameters: query,
      );

      final data = response.data;
      final List<dynamic> content = data['content'];

      logs = content.map((json) => AuditoriaLog.fromJson(json)).toList();
      totalElements = data['totalElements'];
    } catch (e) {
      print("Error cargando auditoría: $e");
      logs = [];
      totalElements = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String text) {
    search = text;
    getLogs(page: 0);
  }

  void setRangoFechas(DateTime? inicio, DateTime? fin) {
    fechaInicio = inicio;
    fechaFin = fin;
    getLogs(page: 0);
  }

  void limpiarFiltros() {
    filtroEntidad = null;
    filtroAccion = null;
    search = '';
    fechaInicio = null;
    fechaFin = null;
    getLogs(page: 0);
  }

  void setFiltroEntidad(String? entidad) {
    filtroEntidad = entidad;
    getLogs(page: 0);
  }

  void setFiltroAccion(String? accion) {
    filtroAccion = accion;
    getLogs(page: 0);
  }
}
