import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/models/bono_seleccion.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class VentasProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<BonoSeleccion> bonosUsables = [];
  List<Servicio> bonosDisponibles = [];
  bool isLoading = false;
  List<Servicio> listaServicios = [];

  // Cargar la lista de bonos para el dropdown
  Future<void> loadBonos() async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/servicios/bonos',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      final List<dynamic> data = response.data;
      bonosDisponibles = data.map((e) => Servicio.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando bonos: $e');
    }
  }

  // Cargar Servicios ACTIVOS
  Future<void> loadServiciosDisponibles() async {
    try {
      final token = LocalStorage.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/servicios',
        queryParameters: {'activo': true},
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      final List<dynamic> data = response.data;
      listaServicios = data.map((e) => Servicio.fromJson(e)).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error cargando servicios: $e');
    }
  }

  // Realizar la venta
  Future<bool> venderBono(int idCliente, int idServicio, String metodoPago) async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      
      final data = {
        "idCliente": idCliente,
        "idServicio": idServicio,
        "metodoPago": metodoPago
      };

      await _dio.post(
        '$_baseUrl/pagos/venta-bono',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      return true;

    } catch (e) {
      print('Error en venta: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarBonosUsables(int idCliente) async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/bonos/disponibles/$idCliente',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      final List<dynamic> data = response.data;
      bonosUsables = data.map((e) => BonoSeleccion.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}