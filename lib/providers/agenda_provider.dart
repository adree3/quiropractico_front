import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/services/stomp_service.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaProvider extends ChangeNotifier {
  
  
  final String _baseUrl = ApiConfig.baseUrl;
  List<Cita> citas = [];
  bool isLoading = false;
  String? errorMessage;

  List<Usuario> quiropracticos = [];
  List<Map<String, String>> huecosDisponibles = [];
  bool isLoadingHuecos = false;
  DateTime selectedDate = DateTime.now();

  int? filterDoctorId;
  CalendarView currentView = CalendarView.day; 
  DateTime? _lastRangeStart;
  DateTime? _lastRangeEnd;

  DateTime? get lastRangeStart => _lastRangeStart;
  set lastRangeStart(DateTime? val) => _lastRangeStart = val;

  DateTime? get lastRangeEnd => _lastRangeEnd;
  set lastRangeEnd(DateTime? val) => _lastRangeEnd = val;

  bool isBackgroundFetching = false;
  final Map<String, List<Cita>> _cacheCitas = {};
  int _fetchRequestId = 0;

  /// Contador que solo se incrementa cuando la fecha o vista cambia por acción externa
  /// (botones de cabecera, selector de fecha, clic en número de día), NUNCA durante un swipe.
  int externalNavigationTick = 0;

  void clearCache() {
    _cacheCitas.clear();
  }

  /// Repinta el DataSource local sin borrar caché ni realizar peticiones HTTP (ej. al cancelar un Drag & Drop)
  void restoreLocalView() {
    notifyListeners();
  }

  /// Inserta o actualiza atómicamente una cita en memoria y en la caché interna sin recargar la red
  void upsertCitaLocal(Cita nuevaCita) {
    final index = citas.indexWhere((c) => c.idCita == nuevaCita.idCita);

    if (index != -1) {
      citas[index] = nuevaCita;
    } else {
      bool entraEnRango = false;
      if (_lastRangeStart != null && _lastRangeEnd != null) {
        final start = DateTime(
          _lastRangeStart!.year,
          _lastRangeStart!.month,
          _lastRangeStart!.day,
        );
        final end = DateTime(
          _lastRangeEnd!.year,
          _lastRangeEnd!.month,
          _lastRangeEnd!.day,
          23,
          59,
          59,
        );
        entraEnRango = !nuevaCita.fechaHoraInicio.isBefore(start) &&
            !nuevaCita.fechaHoraInicio.isAfter(end);
      } else {
        entraEnRango = DateUtils.isSameDay(nuevaCita.fechaHoraInicio, selectedDate);
      }

      if (entraEnRango) {
        citas.add(nuevaCita);
      }
    }

    _updateCacheWithCita(nuevaCita);
    notifyListeners();
  }

  /// Elimina atómicamente una cita de la lista en memoria y de la caché interna
  void deleteCitaLocal(int idCita) {
    citas.removeWhere((c) => c.idCita == idCita);
    for (final lista in _cacheCitas.values) {
      lista.removeWhere((c) => c.idCita == idCita);
    }
    notifyListeners();
  }

  void _updateCacheWithCita(Cita nuevaCita) {
    final citaFechaStr =
        "${nuevaCita.fechaHoraInicio.year}-${nuevaCita.fechaHoraInicio.month.toString().padLeft(2, '0')}-${nuevaCita.fechaHoraInicio.day.toString().padLeft(2, '0')}";
    final citaDateOnly = DateTime(
      nuevaCita.fechaHoraInicio.year,
      nuevaCita.fechaHoraInicio.month,
      nuevaCita.fechaHoraInicio.day,
    );

    _cacheCitas.forEach((key, lista) {
      final parts = key.split('_');
      final docPart = parts.last;
      final matchesDoc =
          docPart == 'ALL' || docPart == nuevaCita.idQuiropractico.toString();

      final existingIdx = lista.indexWhere((c) => c.idCita == nuevaCita.idCita);

      if (key.startsWith('DAY_')) {
        final dayStr = parts[1];
        final matchesDay = dayStr == citaFechaStr;
        if (existingIdx != -1) {
          if (matchesDay && matchesDoc) {
            lista[existingIdx] = nuevaCita;
          } else {
            lista.removeAt(existingIdx);
          }
        } else if (matchesDay && matchesDoc) {
          lista.add(nuevaCita);
        }
      } else if (parts.length >= 3) {
        final start = DateTime.tryParse(parts[0]);
        final end = DateTime.tryParse(parts[1]);
        final matchesRange = start != null &&
            end != null &&
            !citaDateOnly.isBefore(start) &&
            !citaDateOnly.isAfter(end);

        if (existingIdx != -1) {
          if (matchesRange && matchesDoc) {
            lista[existingIdx] = nuevaCita;
          } else {
            lista.removeAt(existingIdx);
          }
        } else if (matchesRange && matchesDoc) {
          lista.add(nuevaCita);
        }
      }
    });
  }

  void setFilterDoctorId(int? id) {
    if (filterDoctorId == id) return;
    filterDoctorId = id;
    _cacheCitas.clear();
    notifyListeners();
    refreshCurrentView();
  }

  void setCurrentView(CalendarView view) {
    if (currentView == view) return;
    currentView = view;
    // Invalidar rango previo para forzar recuperación inmediata de mes/semana al cambiar de vista
    _lastRangeStart = null;
    _lastRangeEnd = null;
    externalNavigationTick++;
    notifyListeners();
    if (view == CalendarView.day) {
      getCitasDelDia(selectedDate);
    } else {
      // Cargar inmediatamente el rango inicial de la nueva vista (evita ver mes o semana vacíos)
      final inicio = view == CalendarView.month
          ? DateTime(selectedDate.year, selectedDate.month, 1).subtract(const Duration(days: 7))
          : selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final fin = view == CalendarView.month
          ? DateTime(selectedDate.year, selectedDate.month + 1, 0).add(const Duration(days: 7))
          : inicio.add(const Duration(days: 6));
      getCitasPorRango(inicio, fin);
    }
  }

  void refreshCurrentView() {
    _cacheCitas.clear();
    if (currentView == CalendarView.day) {
      getCitasDelDia(selectedDate);
    } else if (_lastRangeStart != null && _lastRangeEnd != null) {
      getCitasPorRango(_lastRangeStart!, _lastRangeEnd!);
    } else {
      final inicio = currentView == CalendarView.month
          ? DateTime(selectedDate.year, selectedDate.month, 1).subtract(const Duration(days: 7))
          : selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final fin = currentView == CalendarView.month
          ? DateTime(selectedDate.year, selectedDate.month + 1, 0).add(const Duration(days: 7))
          : inicio.add(const Duration(days: 6));
      getCitasPorRango(inicio, fin);
    }
  }

  /// Sincronización unificada invocada desde onViewChanged del SfCalendar (Swipe / Cambio de página)
  void onCalendarViewChanged({
    required DateTime fechaRepresentativa,
    required DateTime rangoInicio,
    required DateTime rangoFin,
  }) {
    bool changedDate = false;
    if (!DateUtils.isSameDay(fechaRepresentativa, selectedDate)) {
      selectedDate = fechaRepresentativa;
      changedDate = true;
    }

    if (currentView == CalendarView.day) {
      if (changedDate) {
        getCitasDelDia(selectedDate);
      }
      return;
    }

    final bool mismoRango;
    if (currentView == CalendarView.month) {
      mismoRango = _lastRangeStart != null &&
          _lastRangeEnd != null &&
          fechaRepresentativa.isAfter(_lastRangeStart!) &&
          fechaRepresentativa.isBefore(_lastRangeEnd!);
    } else {
      mismoRango = _lastRangeStart != null &&
          _lastRangeEnd != null &&
          DateUtils.isSameDay(_lastRangeStart, rangoInicio) &&
          DateUtils.isSameDay(_lastRangeEnd, rangoFin);
    }

    if (mismoRango && citas.isNotEmpty) {
      if (changedDate) notifyListeners();
      return;
    }

    getCitasPorRango(rangoInicio, rangoFin, forceNotify: changedDate);
  }

  Future<void> getCitasPorRango(DateTime start, DateTime end, {bool forceNotify = false}) async {
    _lastRangeStart = start;
    _lastRangeEnd = end;
    errorMessage = null;

    final int requestId = ++_fetchRequestId;
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";
    final cacheKey = "${startStr}_${endStr}_${filterDoctorId ?? 'ALL'}";

    isBackgroundFetching = true;

    // Stale-While-Revalidate: Si está en caché, asignar inmediatamente en un único notifyListeners
    if (_cacheCitas.containsKey(cacheKey)) {
      citas = _cacheCitas[cacheKey]!;
      notifyListeners();
    } else if (forceNotify) {
      notifyListeners();
    }

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/citas/rango',
        queryParameters: {
          'desde': startStr,
          'hasta': endStr,
          if (filterDoctorId != null) 'idQuiropractico': filterDoctorId
        }
      );

      final List<dynamic> data = response.data;
      final nuevasCitas = data.map((json) => Cita.fromJson(json)).toList();

      // Guardar siempre en caché el rango descargado
      _cacheCitas[cacheKey] = nuevasCitas;

      // Solo actualizar la lista activa si no ha habido otra petición posterior (evita Race Conditions)
      if (requestId == _fetchRequestId) {
        citas = nuevasCitas;
      }
    } catch (e) {
      if (requestId == _fetchRequestId) {
        errorMessage = ErrorHandler.extractMessage(e);
        print('Error agenda rango: $errorMessage');
      }
    } finally {
      if (requestId == _fetchRequestId) {
        isBackgroundFetching = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateSelectedDate(DateTime date, {bool fromExternalUI = true}) async {
    selectedDate = date;
    if (fromExternalUI) {
      externalNavigationTick++;
    }
    if (currentView == CalendarView.day) {
      await getCitasDelDia(date); 
    } else {
      notifyListeners();
    }
  }

  Future<void> getCitasDelDia(DateTime fecha) async {
    // Al cargar un día aislado, invalidamos el rango mensual/semanal para forzar restauración al volver
    _lastRangeStart = null;
    _lastRangeEnd = null;
    errorMessage = null;

    final int requestId = ++_fetchRequestId;
    final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    final cacheKey = "DAY_${fechaStr}_${filterDoctorId ?? 'ALL'}";

    isBackgroundFetching = true;
    if (_cacheCitas.containsKey(cacheKey)) {
      citas = _cacheCitas[cacheKey]!;
    }
    notifyListeners();

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/citas/agenda',
        queryParameters: {'fecha': fechaStr}
      );

      final List<dynamic> data = response.data;
      final nuevasCitas = data.map((json) => Cita.fromJson(json)).toList();
      _cacheCitas[cacheKey] = nuevasCitas;

      if (requestId == _fetchRequestId) {
        citas = nuevasCitas;
      }
    } catch (e) {
      if (requestId == _fetchRequestId) {
        errorMessage = ErrorHandler.extractMessage(e);
        print('Error agenda: $errorMessage');
      }
    } finally {
      if (requestId == _fetchRequestId) {
        isLoading = false;
        isBackgroundFetching = false;
        notifyListeners();
      }
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

      final response = await ApiService.dio.post(
        '$_baseUrl/citas',
        data: data
      );

      if (response.data is Map<String, dynamic>) {
        upsertCitaLocal(Cita.fromJson(response.data));
      } else if (!StompService.instance.isConnected) {
        refreshCurrentView();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> loadQuiropracticos() async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/quiros-activos'
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
      final response = await ApiService.dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado}
      );

      if (response.data is Map<String, dynamic>) {
        upsertCitaLocal(Cita.fromJson(response.data));
      } else if (!StompService.instance.isConnected) {
        refreshCurrentView();
      }

      return null;
    } catch (e) {
      print('Error cambiando estado: $e');
      return ErrorHandler.extractMessage(e);
    }
  }

  // Cancelar Cita
  Future<String?> cancelarCita(int idCita) async {
    try {
      final response = await ApiService.dio.put(
        '$_baseUrl/citas/$idCita/cancelar'
      );

      if (response.data is Map<String, dynamic>) {
        upsertCitaLocal(Cita.fromJson(response.data));
      } else if (!StompService.instance.isConnected) {
        refreshCurrentView();
      }

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

      final response = await ApiService.dio.put(
        '$_baseUrl/citas/$idCita',
        data: data
      );

      if (response.data is Map<String, dynamic>) {
        upsertCitaLocal(Cita.fromJson(response.data));
      } else if (!StompService.instance.isConnected) {
        refreshCurrentView();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  /// Reprograma una cita de forma optimista con rollback en caso de fallo (Drag & Drop / Resize)
  Future<bool> reprogramarCitaOptimista(
    Cita citaOriginal,
    DateTime nuevoInicio,
    DateTime nuevoFin, {
    int? nuevoIdQuiro,
  }) async {
    final index = citas.indexWhere((c) => c.idCita == citaOriginal.idCita);
    if (index == -1) return false;

    // 1. Guardar estado previo para rollback
    final citaPrevia = citas[index];

    // 2. Aplicar cambio optimista en memoria
    final doctorNuevo = nuevoIdQuiro != null && nuevoIdQuiro != citaOriginal.idQuiropractico
        ? quiropracticos.firstWhere(
            (q) => q.idUsuario == nuevoIdQuiro,
            orElse: () => Usuario(
              idUsuario: nuevoIdQuiro,
              nombreCompleto: citaOriginal.nombreQuiropractico,
              username: '',
              rol: '',
              activo: true,
              cuentaBloqueada: false,
            ),
          )
        : null;

    final citaOptimista = citaOriginal.copyWith(
      fechaHoraInicio: nuevoInicio,
      fechaHoraFin: nuevoFin,
      idQuiropractico: nuevoIdQuiro ?? citaOriginal.idQuiropractico,
      nombreQuiropractico: doctorNuevo != null
          ? doctorNuevo.nombreCompleto
          : citaOriginal.nombreQuiropractico,
    );

    citas[index] = citaOptimista;
    notifyListeners();

    try {
      // 3. Llamada al endpoint PATCH /citas/{id}/reprogramar
      final citaConfirmada = await ApiService.reprogramarCita(
        citaOriginal.idCita,
        nuevoInicio,
        nuevoFin,
        idQuiropractico: nuevoIdQuiro,
      );

      // 4. Actualizar atómicamente con los datos confirmados del servidor
      upsertCitaLocal(citaConfirmada);
      return true;
    } catch (e) {
      // 5. Rollback en caso de error
      final rollbackIndex = citas.indexWhere((c) => c.idCita == citaOriginal.idCita);
      if (rollbackIndex != -1) {
        citas[rollbackIndex] = citaPrevia;
        notifyListeners();
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage = msg;
      rethrow;
    }
  }

  /// Carga los huecos disponibles considerando la duración de la cita y profesional
  Future<void> cargarHuecos(
    int idQuiro,
    DateTime fecha, {
    int? idCitaExcluir,
    int? duracionMinutos,
  }) async {
    isLoadingHuecos = true;
    huecosDisponibles = [];
    notifyListeners();

    try {
      final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

      final response = await ApiService.obtenerHuecosDisponibles(
        idQuiro: idQuiro,
        fecha: fechaStr,
        duracionMinutos: duracionMinutos,
        idCitaExcluir: idCitaExcluir,
      );
      final List<dynamic> data = response.data;
      huecosDisponibles = data.map((json) => {
        'horaInicio': json['horaInicio'].toString(),
        'horaFin': json['horaFin'].toString(),
        'texto': json['textoMostrar'].toString()
      }).toList();
    } catch (e) {
      print('Error cargando huecos: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoadingHuecos = false;
      notifyListeners();
    }
  }

  void clearAllData() {
    citas = [];
    _cacheCitas.clear();
    quiropracticos = [];
    huecosDisponibles = [];
    isLoading = false;
    isLoadingHuecos = false;
    errorMessage = null;
    _lastRangeStart = null;
    _lastRangeEnd = null;
    filterDoctorId = null;
    // Purgado silencioso: no se notifica para evitar refetches en cascada
  }
}
