import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/servicio.dart'; // Asegúrate de tener este modelo
import 'package:quiropractico_front/services/local_storage.dart';

class ServicesProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Servicio> _serviciosRaw = [];
  bool isLoading = true;
  String filterType = 'todos';

  ServicesProvider() {
    loadServices();
  }

  // Obtener lista filtrada y ordenada
  List<Servicio> get servicios {
    List<Servicio> lista = _serviciosRaw.where((s) {
      if (filterType == 'todos') return true;
      if (filterType == 'sesion') return s.sesiones == null;
      if (filterType == 'bono') return s.sesiones != null;
      return true;
    }).toList();

    lista.sort((a, b) {

      bool aEsSesion = a.sesiones == null;
      bool bEsSesion = b.sesiones == null;
      if (aEsSesion && !bEsSesion) return -1;
      if (!aEsSesion && bEsSesion) return 1;

      if (a.activo && !b.activo) return -1;
      if (!a.activo && b.activo) return 1;

      return b.idServicio.compareTo(a.idServicio);
    });

    return lista;
  }

  Future<void> loadServices() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/servicios',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data;
      _serviciosRaw = data.map((e) => Servicio.fromJson(e)).toList();

    } catch (e) {
      print('Error cargando servicios: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // FILTRO
  void setFilter(String tipo) {
    filterType = tipo;
    notifyListeners();
  }

  // CREAR
  Future<bool> createService(String nombre, double precio, String tipo, int? sesiones) async {
    try {
      final token = LocalStorage.getToken();
      final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones
      };

      await _dio.post(
        '$_baseUrl/servicios',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      await loadServices();
      return true;
    } catch (e) {
      print('Error creando servicio: $e');
      return false;
    }
  }

  // EDITAR
  Future<bool> updateService(int id, String nombre, double precio, String tipo, int? sesiones) async {
    try {
      final token = LocalStorage.getToken();
      final data = {
        "nombreServicio": nombre,
        "precio": precio,
        "tipo": tipo,
        "sesionesIncluidas": sesiones
      };

      await _dio.put(
        '$_baseUrl/servicios/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      await loadServices();
      return true;
    } catch (e) {
      print('Error editando servicio: $e');
      return false;
    }
  }

  // BORRAR
  Future<bool> deleteService(int id) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.delete('$_baseUrl/servicios/$id', options: Options(headers: {'Authorization': 'Bearer $token'}));
      await loadServices();
      return true;
    } catch (e) { return false; }
  }

  // RECUPERAR
  Future<bool> recoverService(int id) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.put('$_baseUrl/servicios/$id/recuperar', options: Options(headers: {'Authorization': 'Bearer $token'}));
      await loadServices();
      return true;
    } catch (e) { return false; }
  }
}