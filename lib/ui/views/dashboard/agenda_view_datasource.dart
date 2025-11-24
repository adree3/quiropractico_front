import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CitaDataSource extends CalendarDataSource {
  CitaDataSource(List<Cita> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Cita).fechaHoraInicio;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Cita).fechaHoraFin;
  }

  @override
  String getSubject(int index) {
    final cita = appointments![index] as Cita;
    return "${cita.nombreClienteCompleto} (${cita.estado})";
  }

  @override
  Color getColor(int index) {
    final cita = appointments![index] as Cita;
    switch (cita.estado) {
      case 'completada': return Colors.green;
      case 'cancelada': return Colors.redAccent;
      case 'ausente': return Colors.grey;
      default: return const Color(0xFF00AEEF);
    }
  }
}