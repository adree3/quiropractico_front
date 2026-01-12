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
  int pageSize = 10;
  int totalElements = 0;

  String? filtroEntidad;
  String search = '';
  DateTime? fechaSeleccionada;

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
      if (search.isNotEmpty) {
        query['search'] = search;
      }
      if (fechaSeleccionada != null) {
        query['fecha'] = DateFormat('yyyy-MM-dd').format(fechaSeleccionada!);
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

  void setFecha(DateTime? fecha) {
    fechaSeleccionada = fecha;
    getLogs(page: 0);
  }

  void limpiarFiltros() {
    filtroEntidad = null;
    search = '';
    fechaSeleccionada = null;
    getLogs(page: 0);
  }

  void setFiltroEntidad(String? entidad) {
    filtroEntidad = entidad;
    getLogs(page: 0);
  }
}
