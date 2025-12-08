import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/historial.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class HistorialProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  bool isLoading = false;

  Future<Historial?> getNotaPorCita(int idCita) async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get('$_baseUrl/historial/cita/$idCita', options: Options(headers: {'Authorization': 'Bearer $token'}));
      return Historial.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> guardarNota(int idCita, String s, String o, String a, String p) async {
    try {
      final token = LocalStorage.getToken();
      final data = {
        "idCita": idCita,
        "notasSubjetivo": s,
        "notasObjetivo": o,
        "ajustesRealizados": a,
        "planFuturo": p
      };
      await _dio.post('$_baseUrl/historial', data: data, options: Options(headers: {'Authorization': 'Bearer $token'}));
      return true;
    } catch (e) {
      return false;
    }
  }
}