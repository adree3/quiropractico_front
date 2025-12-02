import 'package:flutter/material.dart';

class Horario {
  final int idHorario;
  final int diaSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  Horario({
    required this.idHorario,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      idHorario: json['idHorario'],
      diaSemana: json['diaSemana'],
      horaInicio: _parseTime(json['horaInicio']),
      horaFin: _parseTime(json['horaFin']),
    );
  }

  // Helper para parsear "09:00" a TimeOfDay
  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  // Helper para mostrar bonito "09:00"
  String get formattedRange {
    return "${_format(horaInicio)} - ${_format(horaFin)}";
  }

  String _format(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}