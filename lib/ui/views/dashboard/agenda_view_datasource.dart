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
    // Solo usamos bloqueos útiles para hoy, o todos
    appointments = [];
    appointments!.addAll(citas);
    appointments!.addAll(
      bloqueos.where((b) {
        // Filtramos para no meter historial entero
        return !currentDate.isBefore(
              DateTime(
                b.fechaInicio.year,
                b.fechaInicio.month,
                b.fechaInicio.day,
              ),
            ) &&
            !currentDate.isAfter(
              DateTime(
                b.fechaFin.year,
                b.fechaFin.month,
                b.fechaFin.day,
                23,
                59,
              ),
            );
      }),
    );
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
}
