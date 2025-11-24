import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class AgendaProvider extends ChangeNotifier {
  
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<Cita> citas = [];
  bool isLoading = true;
  List<Usuario> quiropracticos = [];
  
  AgendaProvider() {
    getCitasDelDia(DateTime.now());
  }

  Future<void> getCitasDelDia(DateTime fecha) async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      
      final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

      final response = await _dio.get(
        '$_baseUrl/citas/agenda',
        queryParameters: {'fecha': fechaStr},
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data;
      citas = data.map((json) => Cita.fromJson(json)).toList();

    } catch (e) {
      print('Error cargando agenda: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> crearCita(int idCliente, int idQuiropractico, DateTime inicio, DateTime fin, String notas) async {
    try {
      final token = LocalStorage.getToken();
      
      final data = {
        "idCliente": idCliente,
        "idQuiropractico": idQuiropractico,
        "fechaHoraInicio": inicio.toIso8601String(),
        "fechaHoraFin": fin.toIso8601String(),
        "notasRecepcion": notas
      };

      final response = await _dio.post(
        '$_baseUrl/citas',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 201) {
        await getCitasDelDia(inicio); 
        return null;
      }
      return 'Error desconocido';

    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data['message'] ?? 'Error al procesar la solicitud';
      }
      return 'Error de conexión con el servidor';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<void> loadQuiropracticos() async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/usuarios/quiros',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data;
      quiropracticos = data.map((json) => Usuario.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando quiros: $e');
    }
  }

  // Cambiar estado de la cita
  Future<bool> cambiarEstadoCita(int idCita, String nuevoEstado) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      final fechaRecarga = citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);
      
      return true;
    } catch (e) {
      print('Error cambiando estado: $e');
      return false;
    }
  }

  // Cancelar Cita
  Future<bool> cancelarCita(int idCita) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.put(
        '$_baseUrl/citas/$idCita/cancelar',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      final fechaRecarga = citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);
      
      return true;
    } catch (e) {
      print('Error cancelando cita: $e');
      return false;
    }
  }

  // Editar Cita
  Future<String?> editarCita(int idCita, int idCliente, int idQuiropractico, DateTime inicio, DateTime fin, String notas, String estado) async {
    try {
      final token = LocalStorage.getToken();
      final inicioStr = inicio.toIso8601String().split('.')[0];
      final finStr = fin.toIso8601String().split('.')[0];

      final data = {
        "idCliente": idCliente,
        "idQuiropractico": idQuiropractico,
        "fechaHoraInicio": inicioStr,
        "fechaHoraFin": finStr,
        "notasRecepcion": notas,
        "estado": estado,
        "idBonoAUtilizar": null
      };

      await _dio.put(
        '$_baseUrl/citas/$idCita',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      await getCitasDelDia(inicio);
      return null;

    } on DioException catch (e) {
      if (e.response?.data != null) {
        return e.response!.data['message'] ?? 'Error al editar';
      }
      return 'Error de conexión';
    }
  }
}