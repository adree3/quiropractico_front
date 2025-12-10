import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/historial.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class HistorialProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  bool isLoading = false;

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<Historial?> getNotaPorCita(int idCita) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/historial/cita/$idCita', 
        options: _authOptions
        );
      return Historial.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<String?> guardarNota(int idCita, String s, String o, String a, String p) async {
    try {
      final data = {
        "idCita": idCita,
        "notasSubjetivo": s,
        "notasObjetivo": o,
        "ajustesRealizados": a,
        "planFuturo": p
      };
      await _dio.post(
        '$_baseUrl/historial',
        data: data, 
        options: _authOptions
        );
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}