import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class AgendaProvider extends ChangeNotifier {
  
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<Cita> citas = [];
  bool isLoading = true;
  String? errorMessage;

  List<Usuario> quiropracticos = [];
  List<Map<String, String>> huecosDisponibles = [];
  DateTime selectedDate = DateTime.now();

  AgendaProvider() {
    updateSelectedDate(DateTime.now());
  }

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> updateSelectedDate(DateTime date) async {
    selectedDate = date;
    await getCitasDelDia(date); 
  }

  Future<void> getCitasDelDia(DateTime fecha) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      
      final response = await _dio.get(
        '$_baseUrl/citas/agenda',
        queryParameters: {'fecha': fechaStr},
        options: _authOptions
      );

      final List<dynamic> data = response.data;
      citas = data.map((json) => Cita.fromJson(json)).toList();

    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      print('Error agenda: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> crearCita(int idCliente, int idQuiropractico, DateTime inicio, DateTime fin, String notas, {int? idBonoAUtilizar}) async {
    try {
      
      final data = {
        "idCliente": idCliente,
        "idQuiropractico": idQuiropractico,
        "fechaHoraInicio": inicio.toIso8601String(),
        "fechaHoraFin": fin.toIso8601String(),
        "notasRecepcion": notas,
        "idBonoAUtilizar": idBonoAUtilizar
      };

      await _dio.post(
        '$_baseUrl/citas',
        data: data,
        options: _authOptions
      );

      await getCitasDelDia(inicio);
      return null;

    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> loadQuiropracticos() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/usuarios/quiros-activos',
        options: _authOptions
      );

      final List<dynamic> data = response.data;
      quiropracticos = data.map((json) => Usuario.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Cambiar estado de la cita
  Future<String?> cambiarEstadoCita(int idCita, String nuevoEstado) async {
    try {
      await _dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
        options: _authOptions
      );
      
      final fechaRecarga = citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);
      
      return null;
    } catch (e) {
      print('Error cambiando estado: $e');
      return ErrorHandler.extractMessage(e);
    }
  }

  // Cancelar Cita
  Future<String?> cancelarCita(int idCita) async {
    try {
      await _dio.put(
        '$_baseUrl/citas/$idCita/cancelar',
        options:_authOptions
      );
      
      final fechaRecarga = citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);
      
      return null;
    } catch (e) {
      print('Error cancelando cita: $e');
      return ErrorHandler.extractMessage(e);
    }
  }

  // Editar Cita
  Future<String?> editarCita(int idCita, int idCliente, int idQuiropractico, DateTime inicio, DateTime fin, String notas, String estado) async {
    try {
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
        options:_authOptions
      );

      await getCitasDelDia(inicio);
      return null;

    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> cargarHuecos(int idQuiro, DateTime fecha,{int? idCitaExcluir}) async {
    huecosDisponibles = [];
    notifyListeners();

    try {
      final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> params = {
        'idQuiro': idQuiro, 
        'fecha': fechaStr
      };

      if (idCitaExcluir != null) {
        params['idCitaExcluir'] = idCitaExcluir;
      }

      final response = await _dio.get(
        '$_baseUrl/citas/disponibilidad',
        queryParameters: params,
        options: _authOptions
      );
      final List<dynamic> data = response.data;
      huecosDisponibles = data.map((json) => {
        'horaInicio': json['horaInicio'].toString(),
        'horaFin': json['horaFin'].toString(),
        'texto': json['textoMostrar'].toString()
      }).toList();

      notifyListeners();

    } catch (e) {
      print('Error cargando huecos: ${ErrorHandler.extractMessage(e)}');
    }
  }
}