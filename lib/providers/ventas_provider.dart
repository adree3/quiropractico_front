import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/models/bono_seleccion.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class VentasProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<BonoSeleccion> bonosUsables = [];
  List<Servicio> bonosDisponibles = [];
  bool isLoading = false;
  List<Servicio> listaServicios = [];

  // Cargar la lista de bonos para el dropdown
  Future<void> loadBonos() async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/servicios/bonos');

      final List<dynamic> data = response.data;
      bonosDisponibles = data.map((e) => Servicio.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando bonos: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Cargar Servicios ACTIVOS (Dropdown)
  Future<void> loadServiciosDropdown() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/servicios/list',
        queryParameters: {'activo': true},
      );

      final List<dynamic> data = response.data;
      listaServicios = data.map((e) => Servicio.fromJson(e)).toList();

      notifyListeners();
    } catch (e) {
      print(
        'Error cargando servicios dropdown: ${ErrorHandler.extractMessage(e)}',
      );
    }
  }

  // Realizar la venta
  Future<String?> venderBono(
    int idCliente,
    int idServicio,
    String metodoPago,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      final data = {
        "idCliente": idCliente,
        "idServicio": idServicio,
        "metodoPago": metodoPago,
      };

      await ApiService.dio.post('$_baseUrl/pagos/venta-bono', data: data);

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
      final response = await ApiService.dio.get(
        '$_baseUrl/bonos/disponibles/$idCliente',
      );
      final List<dynamic> data = response.data;
      bonosUsables = data.map((e) => BonoSeleccion.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando bonos usables: ${ErrorHandler.extractMessage(e)}');
    }
  }
}
