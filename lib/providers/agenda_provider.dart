import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class AgendaProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Cita> citas = [];
  bool isLoading = true;
  bool isLoadingHuecos = false;
  String? errorMessage;

  List<Usuario> quiropracticos = [];
  List<Map<String, String>> huecosDisponibles = [];
  DateTime selectedDate = DateTime.now();

  // Gestión de Vistas y Filtros
  CalendarView currentView = CalendarView.day;
  int? filterDoctorId;

  // Seguimiento de rango visible para recargas (filtros, etc)
  DateTime? _rangeStartDate;
  DateTime? _rangeEndDate;

  AgendaProvider() {
    selectedDate = DateTime.now();
    try {
      final v = LocalStorage.getDefaultAgendaView();
      if (v == 'week') currentView = CalendarView.week;
      else if (v == 'month') currentView = CalendarView.month;
    } catch (_) {}
  }

  void setCurrentView(CalendarView view) {
    currentView = view;
    notifyListeners();
    // Al cambiar la vista, solemos querer recargar datos para el rango visible
    // Pero esto se manejará desde el widget al detectar el cambio de vista si es necesario,
    // o podemos forzar una recarga aquí si tenemos el rango.
  }

  void setFilterDoctorId(int? id) {
    filterDoctorId = id;
    notifyListeners();
    // Recargar con el filtro aplicado
    refreshCurrentView();
  }

  Future<void> refreshCurrentView() async {
    if (currentView == CalendarView.day) {
      await getCitasDelDia(selectedDate);
    } else {
      // Si tenemos rango guardado, lo usamos para recargar todo el tramo visible
      if (_rangeStartDate != null && _rangeEndDate != null) {
        await getCitasPorRango(_rangeStartDate!, _rangeEndDate!);
      } else {
        await getCitasDelDia(selectedDate);
      }
    }
  }

  Future<void> updateSelectedDate(DateTime date) async {
    selectedDate = date;
    if (currentView == CalendarView.day) {
      await getCitasDelDia(date);
    } else {
      // Para otras vistas, la carga se suele disparar por el onViewChanged de Syncfusion
      // No obstante, notificamos para sincronizar UI
      notifyListeners();
    }
  }

  Future<void> getCitasDelDia(DateTime fecha) async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fechaStr =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> params = {'fecha': fechaStr};
      if (filterDoctorId != null) {
        params['idQuiropractico'] = filterDoctorId;
      }

      final response = await ApiService.dio.get(
        '$_baseUrl/citas/agenda',
        queryParameters: params,
      );

      final List<dynamic> data = response.data;
      citas = data.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      debugPrint('Error agenda: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCitasPorRango(DateTime desde, DateTime hasta) async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    _rangeStartDate = desde;
    _rangeEndDate = hasta;
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final desdeStr =
          "${desde.year}-${desde.month.toString().padLeft(2, '0')}-${desde.day.toString().padLeft(2, '0')}";
      final hastaStr =
          "${hasta.year}-${hasta.month.toString().padLeft(2, '0')}-${hasta.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> params = {
        'desde': desdeStr,
        'hasta': hastaStr,
      };
      if (filterDoctorId != null) {
        params['idQuiropractico'] = filterDoctorId;
      }

      // IMPORTANTE: Este endpoint requiere ser implementado en el Backend
      final response = await ApiService.dio.get(
        '$_baseUrl/citas/rango',
        queryParameters: params,
      );

      final List<dynamic> data = response.data;
      citas = data.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      debugPrint('Error rango citas: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> crearCita(
    int idCliente,
    int idQuiropractico,
    DateTime inicio,
    DateTime fin,
    String notas, {
    int? idBonoAUtilizar,
  }) async {
    try {
      final data = {
        "idCliente": idCliente,
        "idQuiropractico": idQuiropractico,
        "fechaHoraInicio": inicio.toIso8601String(),
        "fechaHoraFin": fin.toIso8601String(),
        "notasRecepcion": notas,
        "idBonoAUtilizar": idBonoAUtilizar,
      };

      await ApiService.dio.post('$_baseUrl/citas', data: data);

      await getCitasDelDia(inicio);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> loadQuiropracticos() async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/quiros-activos',
      );

      final List<dynamic> data = response.data;
      quiropracticos = data.map((json) => Usuario.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: ${ErrorHandler.extractMessage(e)}');
    }
  }

  // Cambiar estado de la cita
  Future<String?> cambiarEstadoCita(int idCita, String nuevoEstado) async {
    try {
      await ApiService.dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
      );

      final fechaRecarga =
          citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);

      return null;
    } catch (e) {
      debugPrint('Error cambiando estado: $e');
      return ErrorHandler.extractMessage(e);
    }
  }

  // Cancelar Cita
  Future<String?> cancelarCita(int idCita) async {
    try {
      await ApiService.dio.put('$_baseUrl/citas/$idCita/cancelar');

      final fechaRecarga =
          citas.isNotEmpty ? citas[0].fechaHoraInicio : DateTime.now();
      await getCitasDelDia(fechaRecarga);

      return null;
    } catch (e) {
      debugPrint('Error cancelando cita: $e');
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<bool> solicitarFirma(int idCita) async {
    try {
      await ApiService.dio.post('$_baseUrl/citas/$idCita/solicitar-firma');
      return true;
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Editar Cita
  Future<String?> editarCita(
    int idCita,
    int idCliente,
    int idQuiropractico,
    DateTime inicio,
    DateTime fin,
    String notas,
    String estado,
  ) async {
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
        "idBonoAUtilizar": null,
      };

      await ApiService.dio.put('$_baseUrl/citas/$idCita', data: data);

      await getCitasDelDia(inicio);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> cargarHuecos(
    int idQuiro,
    DateTime fecha, {
    int? idCitaExcluir,
  }) async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    huecosDisponibles = [];
    isLoadingHuecos = true;
    notifyListeners();

    try {
      final fechaStr =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> params = {
        'idQuiro': idQuiro,
        'fecha': fechaStr,
      };

      if (idCitaExcluir != null) {
        params['idCitaExcluir'] = idCitaExcluir;
      }

      final response = await ApiService.dio.get(
        '$_baseUrl/citas/disponibilidad',
        queryParameters: params,
      );
      final List<dynamic> data = response.data;
      huecosDisponibles =
          data
              .map(
                (json) => {
                  'horaInicio': json['horaInicio'].toString(),
                  'horaFin': json['horaFin'].toString(),
                  'texto': json['textoMostrar'].toString(),
                },
              )
              .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando huecos: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoadingHuecos = false;
      notifyListeners();
    }
  }
}
