import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';

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

  // Cargar lista de Quiroprácticos
  Future<void> loadDoctores() async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get('$_baseUrl/usuarios/quiros', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final List<dynamic> data = response.data;
      doctores = data.map((e) => Usuario.fromJson(e)).toList();
      
      if (doctores.isNotEmpty && selectedDoctor == null) {
        selectDoctor(doctores.first);
      } else {
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando doctores: $e');
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
      final token = LocalStorage.getToken();
      final response = await _dio.get('$_baseUrl/horarios/quiro/$idQuiro', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final List<dynamic> data = response.data;
      horarios = data.map((e) => Horario.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando horarios: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Crear Horario
  Future<String?> createHorario(int diaSemana, TimeOfDay inicio, TimeOfDay fin) async {
    if (selectedDoctor == null) return "No hay doctor seleccionado";
    try {
      final token = LocalStorage.getToken();
      
      final inicioStr = "${inicio.hour.toString().padLeft(2,'0')}:${inicio.minute.toString().padLeft(2,'0')}:00";
      final finStr = "${fin.hour.toString().padLeft(2,'0')}:${fin.minute.toString().padLeft(2,'0')}:00";

      final data = {
        "idQuiropractico": selectedDoctor!.idUsuario,
        "diaSemana": diaSemana,
        "horaInicio": inicioStr,
        "horaFin": finStr
      };

      await _dio.post('$_baseUrl/horarios', data: data, options: Options(headers: {'Authorization': 'Bearer $token'}));
      await loadHorarios(selectedDoctor!.idUsuario);
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return e.response!.data['message'] ?? 'Error al guardar';
      }
      return 'Error de conexión';
    }
  }

  // Borrar Horario
  Future<bool> deleteHorario(int idHorario) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.delete('$_baseUrl/horarios/$idHorario', options: Options(headers: {'Authorization': 'Bearer $token'}));
      
      horarios.removeWhere((h) => h.idHorario == idHorario);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}