import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';

import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:dio/dio.dart';

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

  Future<void> loadHorarios(int idQuiro, {bool notifyLoading = true}) async {
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/horarios/quiro/$idQuiro',
      );
      final List<dynamic> data = response.data;
      horarios = data.map((e) => Horario.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando horarios: ${ErrorHandler.extractMessage(e)}');
    } finally {
      if (notifyLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  // Crear Horario
  Future<Map<String, dynamic>> createHorario(
    int diaSemana,
    TimeOfDay inicio,
    TimeOfDay fin,
  ) async {
    if (selectedDoctor == null) {
      return {'success': false, 'message': "No hay doctor seleccionado"};
    }

    // 1. Optimistic Update
    final tempId = -1 * DateTime.now().millisecondsSinceEpoch;
    final nuevoHorario = Horario(
      idHorario: tempId,
      idQuiropractico: selectedDoctor!.idUsuario,
      diaSemana: diaSemana,
      horaInicio: inicio,
      horaFin: fin,
    );

    horarios.add(nuevoHorario);
    notifyListeners();

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

      final response = await ApiService.dio.post(
        '$_baseUrl/horarios',
        data: data,
      );

      // Silent Refresh
      await loadHorarios(selectedDoctor!.idUsuario, notifyLoading: false);

      // Obtener el ID real para el retorno (por si se necesita para deshacer)
      final createdData = response.data;
      return {'success': true, 'data': createdData};
    } on DioException catch (e) {
      // Revertir
      horarios.removeWhere((h) => h.idHorario == tempId);
      notifyListeners();

      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        return {
          'success': false,
          'message': data['message'] ?? 'Conflicto de horario',
          'code': data['code'],
        };
      }
      return {'success': false, 'message': ErrorHandler.extractMessage(e)};
    } catch (e) {
      // Revertir
      horarios.removeWhere((h) => h.idHorario == tempId);
      notifyListeners();
      return {'success': false, 'message': ErrorHandler.extractMessage(e)};
    }
  }

  // Borrar Horario
  Future<String?> deleteHorario(int idHorario) async {
    // Backup local & Optimistic Remove
    final index = horarios.indexWhere((h) => h.idHorario == idHorario);
    Horario? backup;
    if (index != -1) {
      backup = horarios[index];
      horarios.removeAt(index);
      notifyListeners();
    }

    try {
      await ApiService.dio.delete('$_baseUrl/horarios/$idHorario');
      // No necesitamos reload aqui si confiamos en el delete, pero por consistencia:
      // await loadHorarios(selectedDoctor!.idUsuario, notifyLoading: false);
      return null;
    } catch (e) {
      // Revertir
      if (backup != null) {
        horarios.insert(index, backup);
        notifyListeners();
      }
      return ErrorHandler.extractMessage(e);
    }
  }

  // Actualizar Horario
  Future<Map<String, dynamic>> updateHorario(
    int idHorario,
    int diaSemana,
    TimeOfDay inicio,
    TimeOfDay fin,
  ) async {
    if (selectedDoctor == null) {
      return {'success': false, 'message': "No hay doctor seleccionado"};
    }

    // Backup & Optimistic Update
    final index = horarios.indexWhere((h) => h.idHorario == idHorario);
    Horario? backup;

    if (index != -1) {
      backup = horarios[index];
      final updatedHorario = Horario(
        idHorario: idHorario,
        idQuiropractico: selectedDoctor!.idUsuario,
        diaSemana: diaSemana,
        horaInicio: inicio,
        horaFin: fin,
      );
      horarios[index] = updatedHorario;
      notifyListeners();
    }

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

      await ApiService.dio.put('$_baseUrl/horarios/$idHorario', data: data);
      await loadHorarios(selectedDoctor!.idUsuario, notifyLoading: false);
      return {'success': true};
    } on DioException catch (e) {
      // Revertir
      if (backup != null && index != -1) {
        horarios[index] = backup;
        notifyListeners();
      }

      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        return {
          'success': false,
          'message': data['message'] ?? 'Conflicto de horario',
          'code': data['code'],
        };
      }
      return {'success': false, 'message': ErrorHandler.extractMessage(e)};
    } catch (e) {
      // Revertir
      if (backup != null && index != -1) {
        horarios[index] = backup;
        notifyListeners();
      }
      return {'success': false, 'message': ErrorHandler.extractMessage(e)};
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

    if (diasUnicos.isEmpty) return [1, 2, 3, 4, 5];

    final listaDias = diasUnicos.toList();
    listaDias.sort();
    return listaDias;
  }
}
