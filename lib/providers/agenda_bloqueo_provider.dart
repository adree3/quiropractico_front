import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class AgendaBloqueoProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<BloqueoAgenda> bloqueos = [];
  bool isLoading = true;

  AgendaBloqueoProvider() {
    loadBloqueos();
  }

  Future<void> loadBloqueos() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.dio.get('$_baseUrl/agenda/bloqueos');
      final List<dynamic> data = response.data;
      bloqueos = data.map((e) => BloqueoAgenda.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando bloqueos: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // CREAR
  Future<String?> crearBloqueo(
    DateTime inicio,
    DateTime fin,
    String motivo,
    int? idQuiro,
  ) async {
    try {
      final data = {
        "fechaInicio": inicio.toIso8601String(),
        "fechaFin": fin.toIso8601String(),
        "motivo": motivo,
        "idQuiropractico": idQuiro,
      };

      await ApiService.dio.post('$_baseUrl/agenda/bloqueos', data: data);
      await loadBloqueos();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // BORRAR
  Future<String?> borrarBloqueo(int id) async {
    try {
      await ApiService.dio.delete('$_baseUrl/agenda/bloqueos/$id');
      await loadBloqueos();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> editarBloqueo(
    int idBloqueo,
    DateTime inicio,
    DateTime fin,
    String motivo,
    int? idUsuario,
  ) async {
    try {
      final data = {
        "fechaInicio": inicio.toIso8601String(),
        "fechaFin": fin.toIso8601String(),
        "motivo": motivo,
        "idQuiropractico": idUsuario,
      };

      await ApiService.dio.put(
        '$_baseUrl/agenda/bloqueos/$idBloqueo',
        data: data,
      );

      await loadBloqueos();
      return null;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data['message'] ?? "Error al editar bloqueo";
      }
      return "Error de conexión";
    }
  }
}
