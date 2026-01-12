import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/historial.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class HistorialProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  bool isLoading = false;

  Future<Historial?> getNotaPorCita(int idCita) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/historial/cita/$idCita',
      );
      return Historial.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<String?> guardarNota(
    int idCita,
    String s,
    String o,
    String a,
    String p,
  ) async {
    try {
      final data = {
        "idCita": idCita,
        "notasSubjetivo": s,
        "notasObjetivo": o,
        "ajustesRealizados": a,
        "planFuturo": p,
      };
      await ApiService.dio.post('$_baseUrl/historial', data: data);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
