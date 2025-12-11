import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class AgendaBloqueoProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<BloqueoAgenda> bloqueos = [];
  bool isLoading = true;

  AgendaBloqueoProvider() {
    loadBloqueos();
  }

  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> loadBloqueos() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        '$_baseUrl/agenda/bloqueos', 
        options: _authOptions
      );
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
  Future<String?> crearBloqueo(DateTime inicio, DateTime fin, String motivo, int? idQuiro) async {
    try {
      final data = {
        "fechaInicio": inicio.toIso8601String(),
        "fechaFin": fin.toIso8601String(),
        "motivo": motivo,
        "idQuiropractico": idQuiro
      };

      await _dio.post(
        '$_baseUrl/agenda/bloqueos', 
        data: data, 
        options: _authOptions
      );
      await loadBloqueos();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // BORRAR
  Future<String?> borrarBloqueo(int id) async {
    try {
      await _dio.delete(
        '$_baseUrl/agenda/bloqueos/$id', 
        options: _authOptions
      );
      await loadBloqueos();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}