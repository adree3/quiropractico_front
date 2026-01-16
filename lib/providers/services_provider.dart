import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/servicio.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class ServicesProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Servicio> servicios = [];
  bool isLoading = true;
  bool? filterActive = true;

  // Paginación
  int currentPage = 0;
  int pageSize = 11;
  int totalElements = 0;
  int totalPages = 0;

  ServicesProvider() {
    loadServices();
  }

  // Cargar servicios ordenados
  Future<void> loadServices({int page = 0, bool notifyLoading = true}) async {
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;

    try {
      final Map<String, dynamic> params = {
        'page': page,
        'size': pageSize,
        'sortBy': 'idServicio',
        'direction': 'desc',
      };
      if (filterActive != null) {
        params['activo'] = filterActive;
      }

      final response = await ApiService.dio.get(
        '$_baseUrl/servicios',
        queryParameters: params,
      );

      final List<dynamic> data = response.data['content'];
      totalElements = response.data['totalElements'];
      totalPages = response.data['totalPages'];

      servicios = data.map((e) => Servicio.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando servicios: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Filro de activos/inactivos/todos
  void setFilter(bool? active) {
    filterActive = active;
    loadServices();
  }

  // CREAR
  Future<String?> createService(
    String nombre,
    double precio,
    String tipo,
    int? sesiones,
  ) async {
    try {
      final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones,
      };

      await ApiService.dio.post('$_baseUrl/servicios', data: data);

      await loadServices();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // EDITAR
  Future<String?> updateService(
    int id,
    String nombre,
    double precio,
    String tipo,
    int? sesiones,
  ) async {
    try {
      final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones,
      };

      await ApiService.dio.put('$_baseUrl/servicios/$id', data: data);

      await loadServices();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // BORRAR
  Future<String?> deleteService(int id) async {
    try {
      // Optimistic Update
      final index = servicios.indexWhere((s) => s.idServicio == id);
      if (index != -1) {
        if (filterActive == true) {
          servicios.removeAt(index);
          totalElements--;
        } else {
          servicios[index] = servicios[index].copyWith(activo: false);
        }
        notifyListeners();
      }

      await ApiService.dio.delete('$_baseUrl/servicios/$id');

      // Silent Refresh
      loadServices(page: currentPage, notifyLoading: false);
      return null;
    } catch (e) {
      // Revert if needed, but for now just returning error
      return ErrorHandler.extractMessage(e);
    }
  }

  // RECUPERAR
  Future<String?> recoverService(int id) async {
    try {
      // Optimistic Update
      final index = servicios.indexWhere((s) => s.idServicio == id);
      if (index != -1) {
        if (filterActive == false) {
          servicios.removeAt(index);
          totalElements--;
        } else {
          servicios[index] = servicios[index].copyWith(activo: true);
        }
        notifyListeners();
      }

      await ApiService.dio.put('$_baseUrl/servicios/$id/recuperar');

      // Silent Refresh
      loadServices(page: currentPage, notifyLoading: false);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
