import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaDataSource extends CalendarDataSource {
  AgendaDataSource(
    List<Cita> citas,
    List<BloqueoAgenda> bloqueos,
    DateTime currentDate,
  ) {
    updateAppointments(citas, bloqueos, currentDate, notify: false);
  }

  /// Actualización reactiva sin reinstanciar el DataSource para mantener vivas las vistas internas
  void updateAppointments(
    List<Cita> citas,
    List<BloqueoAgenda> bloqueos,
    DateTime currentDate, {
    bool notify = true,
  }) {
    final windowStart = currentDate.subtract(const Duration(days: 45));
    final windowEnd = currentDate.add(const Duration(days: 45));
    appointments = <Object>[
      ...citas,
      ...bloqueos.where((b) => !b.fechaFin.isBefore(windowStart) && !b.fechaInicio.isAfter(windowEnd)),
    ];
    if (notify) {
      notifyListeners(CalendarDataSourceAction.reset, appointments!);
    }
  }

  @override
  DateTime getStartTime(int index) {
    final item = appointments![index];
    if (item is Cita) return item.fechaHoraInicio;
    if (item is BloqueoAgenda) return item.fechaInicio;
    return DateTime.now();
  }

  @override
  DateTime getEndTime(int index) {
    final item = appointments![index];
    if (item is Cita) return item.fechaHoraFin;
    if (item is BloqueoAgenda) return item.fechaFin;
    return DateTime.now();
  }

  @override
  String getSubject(int index) {
    final item = appointments![index];
    if (item is Cita) {
      return "${item.nombreClienteCompleto} (${item.estado})";
    }
    if (item is BloqueoAgenda) {
      return "BLOQUEO: ${item.motivo}";
    }
    return "";
  }

  @override
  Color getColor(int index) {
    final item = appointments![index];
    if (item is Cita) {
      switch (item.estado) {
        case 'completada':
          return Colors.green;
        case 'cancelada':
          return Colors.redAccent;
        case 'ausente':
          return Colors.grey;
        default:
          return const Color(0xFF00AEEF);
      }
    }
    if (item is BloqueoAgenda) {
      return Colors.grey.shade300;
    }
    return Colors.blue;
  }

  @override
  bool isAllDay(int index) => false;

  @override
  Object? getId(int index) {
    final item = appointments![index];
    if (item is Cita) return item.idCita;
    if (item is BloqueoAgenda) return item.idBloqueo;
    return null;
  }

  /// Requerido por SfCalendar cuando se usan objetos de negocio personalizados con Drag & Drop y Resize.
  /// Mapea el Appointment temporal que genera el motor interno de nuevo a la entidad Cita / BloqueoAgenda.
  @override
  Object? convertAppointmentToObject(Object? customData, Appointment appointment) {
    if (customData is Cita) {
      return customData.copyWith(
        fechaHoraInicio: appointment.startTime,
        fechaHoraFin: appointment.endTime,
      );
    }
    if (customData is BloqueoAgenda) {
      return BloqueoAgenda(
        idBloqueo: customData.idBloqueo,
        idQuiropractico: customData.idQuiropractico,
        nombreQuiropractico: customData.nombreQuiropractico,
        fechaInicio: appointment.startTime,
        fechaFin: appointment.endTime,
        motivo: customData.motivo,
      );
    }
    return customData ?? appointment;
  }
}
