import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
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

  HorariosProvider() {
    loadDoctores();
  }

  // Cargar lista de Quiroprácticos
  Future<void> loadDoctores() async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/usuarios/quiros');
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
      final response = await ApiService.dio.get('$_baseUrl/horarios/global');

      final List<dynamic> data = response.data;
      horariosGlobales = data.map((e) => Horario.fromJson(e)).toList();

      notifyListeners();
    } catch (e) {
      print(
        'Error cargando horarios globales: ${ErrorHandler.extractMessage(e)}',
      );
    }
  }

  // Devuelve los quiropracticos activos
  Future<void> loadDoctoresActive() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/quiros-activos',
      );
      final List<dynamic> data = response.data;
      doctores = data.map((e) => Usuario.fromJson(e)).toList();

      if (doctores.isNotEmpty) {
        if (selectedDoctor == null ||
            !doctores.any((d) => d.idUsuario == selectedDoctor!.idUsuario)) {
          selectDoctor(doctores.first);
        }
      } else {
        selectedDoctor = null;
      }
      notifyListeners();
    } catch (e) {
      print(
        'Error cargando quiroprácticos activos: ${ErrorHandler.extractMessage(e)}',
      );
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
        '$_baseUrl/horarios/quiro/$idQuiro',
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
  Future<String?> createHorario(
    int diaSemana,
    TimeOfDay inicio,
    TimeOfDay fin,
  ) async {
    if (selectedDoctor == null) return "No hay doctor seleccionado";
    try {
      final inicioStr =
          "${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}:00";
      final finStr =
          "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}:00";

      final data = {
        "idQuiropractico": selectedDoctor!.idUsuario,
        "diaSemana": diaSemana,
        "horaInicio": inicioStr,
        "horaFin": finStr,
      };

      await ApiService.dio.post('$_baseUrl/horarios', data: data);
      await loadHorarios(selectedDoctor!.idUsuario);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Borrar Horario
  Future<String?> deleteHorario(int idHorario) async {
    try {
      await ApiService.dio.delete('$_baseUrl/horarios/$idHorario');

      horarios.removeWhere((h) => h.idHorario == idHorario);
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Getter para obtener los días de la semana activos (Lunes=1, Domingo=7)
  List<int> get diasActivosSemana {
    if (horariosGlobales.isEmpty) {
      // Si no hay horarios cargados, devolvemos L-V por defecto
      return [1, 2, 3, 4, 5];
    }

    final Set<int> diasUnicos = {};
    for (var horario in horariosGlobales) {
      diasUnicos.add(horario.diaSemana);
    }

    // Si por alguna razón no hay días (ej: lista vacía filtrada), L-V por defecto
    if (diasUnicos.isEmpty) return [1, 2, 3, 4, 5];

    final listaDias = diasUnicos.toList();
    listaDias.sort(); // Ordenar: 1, 2, 3...
    return listaDias;
  }
}
