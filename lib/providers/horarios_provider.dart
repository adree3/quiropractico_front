import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class HorariosProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Usuario> doctores = [];
  List<Horario> horarios = [];
  Usuario? selectedDoctor;
  bool isLoading = false;

  HorariosProvider() {
    loadDoctores();
  }

  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  // Cargar lista de Quiroprácticos
  Future<void> loadDoctores() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/usuarios/quiros', 
        options: _authOptions
      );
      final List<dynamic> data = response.data;
      doctores = data.map((e) => Usuario.fromJson(e)).toList();
      
      if (doctores.isNotEmpty && selectedDoctor == null) {
        selectDoctor(doctores.first);
      } else {
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando doctores: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Seleccionar Doctor y cargar sus horarios
  void selectDoctor(Usuario doctor) {
    selectedDoctor = doctor;
    loadHorarios(doctor.idUsuario);
  }

  Future<void> loadHorarios(int idQuiro) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        '$_baseUrl/horarios/quiro/$idQuiro', 
        options: _authOptions
      );
      final List<dynamic> data = response.data;
      horarios = data.map((e) => Horario.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando horarios: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Crear Horario
  Future<String?> createHorario(int diaSemana, TimeOfDay inicio, TimeOfDay fin) async {
    if (selectedDoctor == null) return "No hay doctor seleccionado";
    try {      
      final inicioStr = "${inicio.hour.toString().padLeft(2,'0')}:${inicio.minute.toString().padLeft(2,'0')}:00";
      final finStr = "${fin.hour.toString().padLeft(2,'0')}:${fin.minute.toString().padLeft(2,'0')}:00";

      final data = {
        "idQuiropractico": selectedDoctor!.idUsuario,
        "diaSemana": diaSemana,
        "horaInicio": inicioStr,
        "horaFin": finStr
      };

      await _dio.post(
        '$_baseUrl/horarios', 
        data: data, 
        options: _authOptions
      );
      await loadHorarios(selectedDoctor!.idUsuario);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Borrar Horario
  Future<String?> deleteHorario(int idHorario) async {
    try {
      await _dio.delete(
        '$_baseUrl/horarios/$idHorario', 
        options: _authOptions
      );
      
      horarios.removeWhere((h) => h.idHorario == idHorario);
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}