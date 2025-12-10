import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/servicio.dart'; // Asegúrate de tener este modelo
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class ServicesProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Servicio> servicios = [];
  bool isLoading = true;
  bool? filterActive = true;

  ServicesProvider() {
    loadServices();
  }

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  // Cargar servicios ordenados
  Future<void> loadServices() async {
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (filterActive != null) {
        params['activo'] = filterActive;
      }

      final response = await _dio.get(
        '$_baseUrl/servicios', 
        queryParameters: params,
        options: _authOptions
      );

      final List<dynamic> data = response.data;
      List<Servicio> tempList = data.map((e) => Servicio.fromJson(e)).toList();
      tempList.sort((a, b) {
        bool aEsSesion = a.sesiones == null;
        bool bEsSesion = b.sesiones == null;
        
        if (aEsSesion && !bEsSesion) return -1;
        if (!aEsSesion && bEsSesion) return 1;

        return b.idServicio.compareTo(a.idServicio);
      });
      servicios = tempList;
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
  Future<String?> createService(String nombre, double precio, String tipo, int? sesiones) async {
    try {
      final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones
      };

      await _dio.post(
        '$_baseUrl/servicios',
        data: data,
        options: _authOptions
      );
      
      await loadServices();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // EDITAR
  Future<String?> updateService(int id, String nombre, double precio, String tipo, int? sesiones) async {
    try {
       final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones
      };

      await _dio.put(
        '$_baseUrl/servicios/$id',
        data: data,
        options: _authOptions
      );
      
      await loadServices();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // BORRAR
  Future<String?> deleteService(int id) async {
    try {
      await _dio.delete(
        '$_baseUrl/servicios/$id', 
        options: _authOptions
      );
      await loadServices();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }

  // RECUPERAR
  Future<String?> recoverService(int id) async {
    try {
      await _dio.put(
        '$_baseUrl/servicios/$id/recuperar', 
        options: _authOptions
        );
      await loadServices();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }
}