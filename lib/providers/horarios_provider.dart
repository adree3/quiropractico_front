import 'package:quiropractico_front/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class HorariosProvider extends ChangeNotifier {
  
  final String _baseUrl = ApiConfig.baseUrl;

  List<Usuario> doctores = [];
  List<Horario> horarios = [];
  List<Horario> horariosGlobales = [];
  Usuario? selectedDoctor;
  bool isLoading = false;

  List<int> get diasActivosSemana {
    if (horariosGlobales.isEmpty) return [1, 2, 3, 4, 5];
    final days = horariosGlobales.map((h) => h.diaSemana).toSet().toList();
    days.sort();
    return days.isNotEmpty ? days : [1, 2, 3, 4, 5];
  }

  HorariosProvider() {
    loadDoctores();
  }


  // Cargar lista de Quiroprácticos
  Future<void> loadDoctores() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/quiros'
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

  // Obtiene todos los horarios de los quiropracticos
  Future<void> loadAllHorariosGlobales() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/horarios/global'
      );
      
      final List<dynamic> data = response.data;
      horariosGlobales = data.map((e) => Horario.fromJson(e)).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error cargando horarios globales: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Devuelve los quiropracticos activos
  Future<void> loadDoctoresActive() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/quiros-activos'
      );
      final List<dynamic> data = response.data;
      doctores = data.map((e) => Usuario.fromJson(e)).toList();
      
      if (doctores.isNotEmpty) {
        if (selectedDoctor == null || !doctores.any((d) => d.idUsuario == selectedDoctor!.idUsuario)) {
          selectDoctor(doctores.first);
        }
      } else {
        selectedDoctor = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error cargando quiroprácticos activos: ${ErrorHandler.extractMessage(e)}');
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
      final response = await ApiService.dio.get(
        '$_baseUrl/horarios/quiro/$idQuiro'
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
  Future<Map<String, dynamic>> createHorario(int diaSemana, TimeOfDay inicio, TimeOfDay fin, [int? idQuiro]) async {
    try {
      String hInicioStr = '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}:00';
      String hFinStr = '${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}:00';
      
      final targetQuiro = idQuiro ?? selectedDoctor?.idUsuario;

      final response = await ApiService.dio.post(
        '$_baseUrl/horarios',
        data: {
          "idQuiropractico": targetQuiro,
          "diaSemana": diaSemana,
          "horaInicio": hInicioStr,
          "horaFin": hFinStr
        }
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (targetQuiro != null) {
          await loadHorarios(targetQuiro);
        }
        await loadAllHorariosGlobales();
        return {"success": true, "data": response.data};
      }
      return {"success": false, "error": "Error al crear horario"};
    } on DioException catch (e) {
      return {"success": false, "error": ErrorHandler.extractMessage(e)};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // Borrar Horario
  Future<String?> deleteHorario(int idHorario) async {
    try {
      await ApiService.dio.delete(
        '$_baseUrl/horarios/$idHorario'
      );
      
      horarios.removeWhere((h) => h.idHorario == idHorario);
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<Map<String, dynamic>> updateHorario(int idHorario, int diaSemana, TimeOfDay horaInicio, TimeOfDay horaFin, [int? idQuiro]) async {
    try {
      String hInicioStr = '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}:00';
      String hFinStr = '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}:00';
      
      final targetQuiro = idQuiro ?? selectedDoctor?.idUsuario;

      final response = await ApiService.dio.put(
        '$_baseUrl/horarios/$idHorario',
        data: {
          "idQuiropractico": targetQuiro,
          "diaSemana": diaSemana,
          "horaInicio": hInicioStr,
          "horaFin": hFinStr
        }
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (targetQuiro != null) {
          await loadHorarios(targetQuiro);
        }
        await loadAllHorariosGlobales();
        return {"success": true};
      }
      return {"success": false, "error": "Error al actualizar"};
    } on DioException catch (e) {
      return {"success": false, "error": ErrorHandler.extractMessage(e)};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  void clearAllData() {
    doctores = [];
    horarios = [];
    horariosGlobales = [];
    selectedDoctor = null;
    isLoading = false;
    notifyListeners();
  }
}