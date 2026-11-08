import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaUtils {
  /// Comprueba si hay un doctor disponible para una hora especifica
  /// Devuelve el primer doctor disponible para una fecha
  static Usuario? getAvailableDoctor(
    DateTime date,
    List<Usuario> doctores,
    List<Horario> horariosGlobales,
    List<BloqueoAgenda> bloqueos,
  ) {
    bool hayCierreGlobal = bloqueos.any(
      (b) =>
          b.idQuiropractico == null &&
          !date.isBefore(b.fechaInicio) &&
          !date.isAfter(b.fechaFin),
    );
    if (hayCierreGlobal) return null;

    final doctoresActivos = doctores.where((d) => d.activo).toList();

    for (var doc in doctoresActivos) {
      bool tieneTurno = horariosGlobales.any((h) {
        if (h.idQuiropractico != doc.idUsuario) return false;
        if (h.diaSemana != date.weekday) return false;

        final minutosSlot = date.hour * 60 + date.minute;
        final minutosInicio = h.horaInicio.hour * 60 + h.horaInicio.minute;
        final minutosFin = h.horaFin.hour * 60 + h.horaFin.minute;

        return minutosSlot >= minutosInicio && minutosSlot < minutosFin;
      });

      bool estaDeVacaciones = bloqueos.any(
        (b) =>
            b.idQuiropractico == doc.idUsuario &&
            !date.isBefore(b.fechaInicio) &&
            !date.isAfter(b.fechaFin),
      );

      if (tieneTurno && !estaDeVacaciones) {
        return doc;
      }
    }
    return null;
  }

  /// Comprueba si hay un doctor disponible
  static bool isSlotEnabled(
    DateTime date,
    List<Usuario> doctores,
    List<Horario> horariosGlobales,
    List<BloqueoAgenda> bloqueos,
  ) {
    return getAvailableDoctor(date, doctores, horariosGlobales, bloqueos) != null;
  }

  /// Comprueba si el día es laborable (hay algún horario global definido)
  static bool isDayWorkable(
    DateTime date,
    List<Horario> globals,
  ) {
    return globals.any((g) => g.diaSemana == date.weekday);
  }

  /// Comprueba si el día tiene un bloqueo global (festivo o cierre de clínica completo)
  static bool isGlobalBlocked(DateTime date, List<BloqueoAgenda> bloqueos) {
    final checkDay = DateTime(date.year, date.month, date.day);
    return bloqueos.any(
      (b) {
        if (b.idQuiropractico != null) return false;
        final startDay = DateTime(b.fechaInicio.year, b.fechaInicio.month, b.fechaInicio.day);
        final endDay = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
        return !checkDay.isBefore(startDay) && !checkDay.isAfter(endDay);
      },
    );
  }

  /// Comprueba si una fecha concreta es hábil y asignable (considerando clínica y quiropráctico opcional)
  static bool isDateWorkable(
    DateTime date,
    List<Horario> horariosGlobales,
    List<BloqueoAgenda> bloqueos, {
    int? idQuiropratico,
  }) {
    // 1. Debe haber turnos globales para este día de la semana
    if (!isDayWorkable(date, horariosGlobales)) return false;

    // 2. No debe estar bloqueado a nivel global (festivo o cierre de clínica)
    if (isGlobalBlocked(date, bloqueos)) return false;

    // 3. Si se especifica un quiropráctico, debe tener turno ese día y no estar bloqueado
    if (idQuiropratico != null) {
      final bool doctorTieneTurno = horariosGlobales.any(
        (h) => h.idQuiropractico == idQuiropratico && h.diaSemana == date.weekday,
      );
      if (!doctorTieneTurno) return false;

      final checkDay = DateTime(date.year, date.month, date.day);
      final bool doctorBloqueado = bloqueos.any((b) {
        if (b.idQuiropractico != idQuiropratico) return false;
        final startDay = DateTime(b.fechaInicio.year, b.fechaInicio.month, b.fechaInicio.day);
        final endDay = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
        return !checkDay.isBefore(startDay) && !checkDay.isAfter(endDay);
      });
      if (doctorBloqueado) return false;
    }

    return true;
  }

  /// Busca el siguiente o anterior día laborable válido saltando fines de semana,
  /// festivos y días en los que el doctor no trabaje o esté de vacaciones.
  static DateTime findNextWorkDay(
    DateTime fromDate,
    List<Horario> horariosGlobales,
    List<BloqueoAgenda> bloqueos, {
    required bool forward,
    int? idQuiropratico,
  }) {
    DateTime checkDate = fromDate;
    int iterations = 0;
    while (iterations < 30) {
      checkDate = forward
          ? checkDate.add(const Duration(days: 1))
          : checkDate.subtract(const Duration(days: 1));
      iterations++;

      if (isDateWorkable(
        checkDate,
        horariosGlobales,
        bloqueos,
        idQuiropratico: idQuiropratico,
      )) {
        return checkDate;
      }
    }
    return fromDate; // Fallback de seguridad si no hay días laborables en 30 iteraciones
  }

  /// Calcular horas límite dinámicas para un conjunto de días (o globales de la clínica si dates es null)
  static Map<String, double> calculateHourBoundaries(
    List<Horario> horarios,
    List<DateTime>? dates,
  ) {
    List<Horario> horariosVisibles;
    if (dates != null && dates.isNotEmpty) {
      final weekDays = dates.map((d) => d.weekday).toSet();
      horariosVisibles =
          horarios.where((h) => weekDays.contains(h.diaSemana)).toList();
    } else {
      horariosVisibles = horarios;
    }

    if (horariosVisibles.isEmpty) {
      return {'min': 8.0, 'max': 21.0};
    }

    int minMinutes = 24 * 60;
    int maxMinutes = 0;

    for (var h in horariosVisibles) {
      final start = h.horaInicio.hour * 60 + h.horaInicio.minute;
      final end = h.horaFin.hour * 60 + h.horaFin.minute;

      if (start < minMinutes) minMinutes = start;
      if (end > maxMinutes) maxMinutes = end;
    }

    double minHour = (minMinutes / 30).floor() * 0.5;
    double maxHour = (maxMinutes / 30).ceil() * 0.5;

    minHour = (minHour - 0.5).clamp(0.0, 24.0);

    return {'min': minHour, 'max': maxHour};
  }

  /// Genera las regiones deshabilitadas (gris suave) para una vista
  /// Enfocado en horas no laborables y bloqueos globales/específicos
  static List<TimeRegion> getDisabledRegions({
    required DateTime focusDate,
    required CalendarView currentView,
    required int? selectedQuiropraticoId,
    required List<Usuario> doctores,
    required List<Horario> horariosGlobales,
    required List<BloqueoAgenda> bloqueos,
  }) {
    final List<TimeRegion> regions = [];
    final List<DateTime> visibleDates = [];

    // Calcular fechas visibles
    if (currentView == CalendarView.month) return []; // En mes se usa monthCellBuilder

    if (currentView == CalendarView.day) {
      // Pre-calcular día actual y adyacentes (±1 día) para swipe fluido
      for (int i = -1; i <= 1; i++) {
        visibleDates.add(focusDate.add(Duration(days: i)));
      }
    } else {
      // Semana: Pre-calcular semana actual + semana anterior y siguiente (21 días)
      // para evitar repintado brusco de zonas grises durante el deslizamiento
      final monday = focusDate.subtract(Duration(days: focusDate.weekday - 1));
      for (int i = -7; i < 14; i++) {
        visibleDates.add(monday.add(Duration(days: i)));
      }
    }

    for (var date in visibleDates) {
      final baseDate = DateTime(date.year, date.month, date.day);
      
      // 1. Bloqueos Globales (Vacaciones clínica, Festivos)
      final globalBlocks = bloqueos.where((b) => 
        b.idQuiropractico == null &&
        (DateUtils.isSameDay(date, b.fechaInicio) || 
         (date.isAfter(b.fechaInicio) && date.isBefore(b.fechaFin)))
      ).toList();

      if (globalBlocks.isNotEmpty) {
        // Si hay bloqueo global de TODO el día, pintamos todo el día
        regions.add(TimeRegion(
          startTime: baseDate,
          endTime: baseDate.add(const Duration(hours: 23, minutes: 59)),
          enablePointerInteraction: false,
          color: Colors.grey.withValues(alpha: 0.25),
          text: currentView == CalendarView.day ? 'Clínica Cerrada' : '',
        ));
        continue; // No pintamos horarios si está cerrado
      }

      // 2. Horarios Laborables vs No Laborables
      final dayHorarios = horariosGlobales.where((h) {
        if (h.diaSemana != date.weekday) return false;
        if (selectedQuiropraticoId != null) {
          return h.idQuiropractico == selectedQuiropraticoId;
        }
        return true; // En vista "Todos", si ALGUIEN trabaja, el slot puede ser libre
      }).toList();

      if (dayHorarios.isEmpty) {
        // Día no laborable completo
        regions.add(TimeRegion(
          startTime: baseDate,
          endTime: baseDate.add(const Duration(hours: 23, minutes: 59)),
          enablePointerInteraction: false,
          color: Colors.grey.withValues(alpha: 0.25),
          text: currentView == CalendarView.day ? 'No laborable' : '',
        ));
      } else {
        // Pintamos los huecos entre turnos (mañana y tarde p.ej)
        // Ordenamos por hora
        dayHorarios.sort((a, b) => a.horaInicio.hour * 60 + a.horaInicio.minute 
                         - (b.horaInicio.hour * 60 + b.horaInicio.minute));

        // Hueco antes del primer turno (desde las 00:00 hasta el primer inicio)
        final firstStart = dayHorarios.first.horaInicio;
        regions.add(TimeRegion(
          startTime: baseDate,
          endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, firstStart.hour, firstStart.minute),
          enablePointerInteraction: false,
          color: Colors.grey.withValues(alpha: 0.18),
        ));

        // Huecos entre turnos
        for (int i = 0; i < dayHorarios.length - 1; i++) {
          final endCurrent = dayHorarios[i].horaFin;
          final startNext = dayHorarios[i + 1].horaInicio;
          if (startNext.isAfter(endCurrent)) {
             regions.add(TimeRegion(
              startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, endCurrent.hour, endCurrent.minute),
              endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, startNext.hour, startNext.minute),
              enablePointerInteraction: false,
              color: Colors.grey.withValues(alpha: 0.18),
            ));
          }
        }

        // Hueco tras el último turno (hasta las 23:59)
        final lastEnd = dayHorarios.last.horaFin;
        regions.add(TimeRegion(
          startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, lastEnd.hour, lastEnd.minute),
          endTime: baseDate.add(const Duration(hours: 23, minutes: 59)),
          enablePointerInteraction: false,
          color: Colors.grey.withValues(alpha: 0.18),
        ));
      }

      // 3. Bloqueos específicos del doctor (si está seleccionado)
      if (selectedQuiropraticoId != null) {
        final doctorBlocks = bloqueos.where((b) => 
          b.idQuiropractico == selectedQuiropraticoId &&
          (DateUtils.isSameDay(date, b.fechaInicio) || 
           (date.isAfter(b.fechaInicio) && date.isBefore(b.fechaFin)))
        ).toList();

        for (var b in doctorBlocks) {
          regions.add(TimeRegion(
            startTime: b.fechaInicio,
            endTime: b.fechaFin,
            enablePointerInteraction: false,
            color: Colors.grey.withValues(alpha: 0.22),
          ));
        }
      }
    }

    return regions;
  }

  /// Redondea una hora al múltiplo de intervalo más cercano evitando errores de cambio de día
  static DateTime roundToNearestInterval(DateTime time, int intervalMinutes) {
    if (intervalMinutes <= 0) return time;
    final int totalMinutes = time.hour * 60 + time.minute;
    final int roundedMinutes = ((totalMinutes / intervalMinutes).round() * intervalMinutes);
    return DateTime(time.year, time.month, time.day).add(Duration(minutes: roundedMinutes));
  }
}
