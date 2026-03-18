import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// ─── Paleta mínima ────────────────────────────────────────────
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFECECF0);
const _kTextSub = Color(0xFF9095A3);
const _kTextMain = Color(0xFF1A1D23);

class AgendaSidePanel extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const AgendaSidePanel({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context);
    final allCitas = agendaProvider.citas;
    // Aplicar el mismo filtro de doctor que usa el calendario
    final citas = agendaProvider.filterDoctorId == null
        ? allCitas
        : allCitas.where((c) => c.idQuiropractico == agendaProvider.filterDoctorId).toList();
    final view = agendaProvider.currentView;
    final now = DateTime.now();

    // ── Citas del período visible ──────────────────────────────
    final totalCitas = citas.length;
    final completadas = citas.where((c) => c.estado == 'completada').length;
    final pendientes = citas.where((c) => c.estado == 'programada').length;

    // ── Huecos libres por cancelaciones (citas canceladas o ausentes recientes)
    final huecosCancelados = _getHuecosCancelados(citas, now, view);

    // ── Ocupación del período ──────────────────────────────────
    final ocupacion = _calcularOcupacion(
      citas,
      agendaProvider,
      horariosProvider,
      view,
      now,
    );

    // ── Próximas citas (solo vista diaria) ─────────────────────
    List<Cita> proximasCitas = [];
    if (view == CalendarView.day) {
      proximasCitas =
          citas.where((c) {
            return DateUtils.isSameDay(
                  c.fechaHoraInicio,
                  agendaProvider.selectedDate,
                ) &&
                c.fechaHoraFin.isAfter(now) &&
                c.estado == 'programada';
          }).toList();
      proximasCitas.sort(
        (a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio),
      );
    }

    // ── Título adaptativo ──────────────────────────────────────
    final titulo = _titulo(view, agendaProvider.selectedDate);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 60 : 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: _kBorder)),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: isCollapsed ? 60 : 280,
          maxWidth: isCollapsed ? 60 : 280,
          child:
              isCollapsed
                  ? _CollapsedPanel(
                    onToggle: onToggle,
                    totalCitas: totalCitas,
                    huecosCancelados: huecosCancelados.length,
                    completadas: completadas,
                    pendientes: pendientes,
                  )
                  : _ExpandedPanel(
                    titulo: titulo,
                    onToggle: onToggle,
                    totalCitas: totalCitas,
                    completadas: completadas,
                    pendientes: pendientes,
                    huecosCancelados: huecosCancelados,
                    ocupacion: ocupacion,
                    view: view,
                    proximasCitas: proximasCitas,
                    agendaProvider: agendaProvider,
                    horariosProvider: horariosProvider,
                    bloqueosProvider: bloqueosProvider,
                  ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _titulo(CalendarView view, DateTime date) {
    if (view == CalendarView.day) {
      return DateFormat("EEEE d", 'es_ES').format(date);
    }
    if (view == CalendarView.week) return "Semana actual";
    return "Mes actual";
  }

  List<Cita> _getHuecosCancelados(
    List<Cita> citas,
    DateTime now,
    CalendarView view,
  ) {
    // Citas canceladas/ausentes en el período visible cuyo hueco sigue siendo futuro
    return citas.where((c) {
        final esCancelada = c.estado == 'cancelada' || c.estado == 'ausente';
        final esHuecoFuturo = c.fechaHoraInicio.isAfter(now);
        return esCancelada && esHuecoFuturo;
      }).toList()
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
  }

  _OcupacionData _calcularOcupacion(
    List<Cita> citas,
    AgendaProvider agendaProvider,
    HorariosProvider horariosProvider,
    CalendarView view,
    DateTime now,
  ) {
    // Citas activas del período (no canceladas) — ya filtradas por doctor
    final List<Cita> citasBase = view == CalendarView.day
        ? citas.where((c) => DateUtils.isSameDay(c.fechaHoraInicio, agendaProvider.selectedDate)).toList()
        : citas;
    final ocupadas = citasBase.where((c) => c.estado != 'cancelada').length;

    // Horarios del doctor filtrado (o todos si no hay filtro)
    final horarios = agendaProvider.filterDoctorId == null
        ? horariosProvider.horariosGlobales
        : horariosProvider.horariosGlobales
            .where((h) => h.idQuiropractico == agendaProvider.filterDoctorId)
            .toList();

    // Calcula slots de 30min para un día dado
    int _slotsForDay(int diaSemana) {
      int slots = 0;
      for (final h in horarios.where((h) => h.diaSemana == diaSemana)) {
        final start = h.horaInicio.hour * 60 + h.horaInicio.minute;
        final end = h.horaFin.hour * 60 + h.horaFin.minute;
        slots += ((end - start) / 30).floor();
      }
      return slots;
    }

    int totalSlots = 0;
    if (view == CalendarView.day) {
      totalSlots = _slotsForDay(agendaProvider.selectedDate.weekday);
    } else if (view == CalendarView.week) {
      // Suma slots para los 7 días de la semana visible
      for (int d = 1; d <= 7; d++) {
        totalSlots += _slotsForDay(d);
      }
    } else {
      // Mensual: cuenta cuántos lunes, martes... hay en el mes y multiplica por slots del día
      final fecha = agendaProvider.selectedDate;
      final diasMes = DateUtils.getDaysInMonth(fecha.year, fecha.month);
      for (int day = 1; day <= diasMes; day++) {
        final weekday = DateTime(fecha.year, fecha.month, day).weekday;
        totalSlots += _slotsForDay(weekday);
      }
    }

    final sublabel = view == CalendarView.day
        ? 'hoy'
        : view == CalendarView.week
            ? 'esta semana'
            : 'este mes';

    if (totalSlots == 0) {
      return _OcupacionData(
        ocupadas: 0,
        total: 1,
        label: 'Sin horario',
        sublabel: sublabel,
      );
    }

    return _OcupacionData(
      ocupadas: ocupadas,
      total: totalSlots,
      label: '$ocupadas / $totalSlots huecos',
      sublabel: sublabel,
    );
  }
}

// ─── Panel colapsado ─────────────────────────────────────────

class _CollapsedPanel extends StatelessWidget {
  final VoidCallback onToggle;
  final int totalCitas;
  final int huecosCancelados;
  final int completadas;
  final int pendientes;

  const _CollapsedPanel({
    required this.onToggle,
    required this.totalCitas,
    required this.huecosCancelados,
    required this.completadas,
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.chevron_left, color: _kTextSub, size: 22),
            ),
          ),
          const SizedBox(height: 22),

          if (huecosCancelados > 0)
            _IconBadge(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              count: huecosCancelados,
              tooltip: "$huecosCancelados hueco(s) libre(s) por cancelación",
            ),
          if (huecosCancelados > 0) const SizedBox(height: 16),

          _CollapsedKpi(
            icon: Icons.event_note_rounded,
            color: AppTheme.primaryColor,
            value: "$totalCitas",
            tooltip: "Total citas del período",
          ),
          const SizedBox(height: 14),
          _CollapsedKpi(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            value: "$completadas",
            tooltip: "Completadas",
          ),
          const SizedBox(height: 14),
          _CollapsedKpi(
            icon: Icons.access_time_rounded,
            color: Colors.orange,
            value: "$pendientes",
            tooltip: "Pendientes",
          ),
        ],
      ),
    );
  }
}

// ─── Panel expandido ─────────────────────────────────────────

class _ExpandedPanel extends StatelessWidget {
  final String titulo;
  final VoidCallback onToggle;
  final int totalCitas;
  final int completadas;
  final int pendientes;
  final List<Cita> huecosCancelados;
  final _OcupacionData ocupacion;
  final CalendarView view;
  final List<Cita> proximasCitas;
  final AgendaProvider agendaProvider;
  final HorariosProvider horariosProvider;
  final AgendaBloqueoProvider bloqueosProvider;

  const _ExpandedPanel({
    required this.titulo,
    required this.onToggle,
    required this.totalCitas,
    required this.completadas,
    required this.pendientes,
    required this.huecosCancelados,
    required this.ocupacion,
    required this.view,
    required this.proximasCitas,
    required this.agendaProvider,
    required this.horariosProvider,
    required this.bloqueosProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, color: _kTextSub, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Sección 1: Alertas de huecos libres ────────────
          if (huecosCancelados.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.warning_amber_rounded,
              label: "Huecos disponibles",
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            ...huecosCancelados
                .take(3)
                .map(
                  (c) =>
                      _HuecoCard(cita: c, onFill: () => _fillHueco(context, c)),
                ),
            if (huecosCancelados.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  "+${huecosCancelados.length - 3} más",
                  style: const TextStyle(fontSize: 11, color: _kTextSub),
                ),
              ),
            const SizedBox(height: 18),
            const Divider(color: _kBorder, height: 1),
            const SizedBox(height: 18),
          ],

          // ── Sección 2: Balance del período ─────────────────
          _SectionLabel(
            icon: Icons.insights_rounded,
            label: "Balance del período",
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _KpiRow(
            totalCitas: totalCitas,
            completadas: completadas,
            pendientes: pendientes,
          ),
          const SizedBox(height: 14),
          _OcupacionBar(data: ocupacion),

          // ── Sección 3 (Solo Diaria): Próximos pacientes ────
          if (view == CalendarView.day) ...[
            const SizedBox(height: 18),
            const Divider(color: _kBorder, height: 1),
            const SizedBox(height: 18),
            _SectionLabel(
              icon: Icons.person_pin_circle_rounded,
              label: "Siguiente en entrar",
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            if (proximasCitas.isEmpty)
              const _EmptySlot(message: "No hay más citas programadas")
            else ...[
              _NextPatientCard(cita: proximasCitas.first),
              if (proximasCitas.length > 1) ...[
                const SizedBox(height: 14),
                _SectionLabel(
                  icon: Icons.format_list_bulleted_rounded,
                  label: "A continuación",
                  color: _kTextSub,
                ),
                const SizedBox(height: 8),
                ...proximasCitas
                    .skip(1)
                    .take(5)
                    .map((c) => _UpcomingCitaTile(cita: c)),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _fillHueco(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (ctx) => CitaModal(selectedDate: cita.fechaHoraInicio),
    ).then((val) {
      if (val == true) agendaProvider.refreshCurrentView();
    });
  }
}

// ─── Widgets pequeños ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int totalCitas;
  final int completadas;
  final int pendientes;

  const _KpiRow({
    required this.totalCitas,
    required this.completadas,
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiChip(
          value: "$totalCitas",
          label: "Total",
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        _KpiChip(value: "$completadas", label: "Hechas", color: Colors.green),
        const SizedBox(width: 8),
        _KpiChip(value: "$pendientes", label: "Pend.", color: Colors.orange),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _KpiChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcupacionBar extends StatelessWidget {
  final _OcupacionData data;
  const _OcupacionBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct =
        data.total == 0 ? 0.0 : (data.ocupadas / data.total).clamp(0.0, 1.0);
    final pctInt = (pct * 100).round();

    Color barColor;
    if (pct < 0.4)
      barColor = Colors.red.shade400;
    else if (pct < 0.7)
      barColor = Colors.orange.shade400;
    else
      barColor = Colors.green.shade500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ocupación",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$pctInt%",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                data.label,
                style: const TextStyle(fontSize: 11, color: _kTextSub),
              ),
              const Spacer(),
              Text(
                data.sublabel,
                style: const TextStyle(fontSize: 10, color: _kTextSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HuecoCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onFill;

  const _HuecoCard({required this.cita, required this.onFill});

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat(
      'EEE dd/MM · HH:mm',
      'es_ES',
    ).format(cita.fechaHoraInicio);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hora,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextMain,
              ),
            ),
          ),
          InkWell(
            onTap: onFill,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Llenar",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPatientCard extends StatelessWidget {
  final Cita cita;
  const _NextPatientCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                "${DateFormat('HH:mm').format(cita.fechaHoraInicio)} – ${DateFormat('HH:mm').format(cita.fechaHoraFin)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cita.nombreClienteCompleto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            "Dr. ${cita.nombreQuiropractico.split(' ').first}",
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCitaTile extends StatelessWidget {
  final Cita cita;
  const _UpcomingCitaTile({required this.cita});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateFormat('HH:mm').format(cita.fechaHoraInicio),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita.nombreClienteCompleto,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Dr. ${cita.nombreQuiropractico.split(' ').first}",
                  style: const TextStyle(fontSize: 10, color: _kTextSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String message;
  const _EmptySlot({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: _kTextSub),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Colapsado: iconos con badge / kpis ───────────────────────

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String tooltip;
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.count,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedKpi extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String tooltip;

  const _CollapsedKpi({
    required this.icon,
    required this.color,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modelo de datos de ocupación ─────────────────────────────

class _OcupacionData {
  final int ocupadas;
  final int total;
  final String label;
  final String sublabel;

  const _OcupacionData({
    required this.ocupadas,
    required this.total,
    required this.label,
    required this.sublabel,
  });
}
