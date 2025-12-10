import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/models/bono_seleccion.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class VentasProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<BonoSeleccion> bonosUsables = [];
  List<Servicio> bonosDisponibles = [];
  bool isLoading = false;
  List<Servicio> listaServicios = [];

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  // Cargar la lista de bonos para el dropdown
  Future<void> loadBonos() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/servicios/bonos',
        options:_authOptions
      );
      
      final List<dynamic> data = response.data;
      bonosDisponibles = data.map((e) => Servicio.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando bonos: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Cargar Servicios ACTIVOS
  Future<void> loadServiciosDisponibles() async {
    try {      
      final response = await _dio.get(
        '$_baseUrl/servicios',
        queryParameters: {'activo': true},
        options: _authOptions
      );
      
      final List<dynamic> data = response.data;
      listaServicios = data.map((e) => Servicio.fromJson(e)).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error cargando servicios: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Realizar la venta
  Future<String?> venderBono(int idCliente, int idServicio, String metodoPago) async {
    isLoading = true;
    notifyListeners();

    try {      
      final data = {
        "idCliente": idCliente,
        "idServicio": idServicio,
        "metodoPago": metodoPago
      };

      await _dio.post(
        '$_baseUrl/pagos/venta-bono',
        data: data,
        options: _authOptions
      );

      return null;

    } catch (e) {
      return ErrorHandler.extractMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarBonosUsables(int idCliente) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/bonos/disponibles/$idCliente',
        options: _authOptions
      );
      final List<dynamic> data = response.data;
      bonosUsables = data.map((e) => BonoSeleccion.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando bonos usables: ${ErrorHandler.extractMessage(e)}');
    }
  }
}