import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_header.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_side_panel.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final CalendarController _calendarController = CalendarController();
  bool _esTurnoManana = true;

  List<TimeRegion>? _cachedRegions;
  DateTime? _lastDateCalculated;
  int? _lastDataHash;

  @override
  void initState() {
    super.initState();
    if (DateTime.now().hour >= 15) {
      _esTurnoManana = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(
        context,
        listen: false,
      );
      final horariosProvider = Provider.of<HorariosProvider>(
        context,
        listen: false,
      );
      final agendaProvider = Provider.of<AgendaProvider>(
        context,
        listen: false,
      );

      bloqueoProvider.loadBloqueos();
      horariosProvider.loadAllHorariosGlobales();
      agendaProvider.loadQuiropracticos();
    });
  }

  // Comprueba si hay un doctor disponible para una hora especifica
  bool _isSlotEnabled(
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
    if (hayCierreGlobal) return false;

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
        return true;
      }
    }
    return false;
  }

  // Generador de regiones grises
  List<TimeRegion> _getDisabledRegions(
    DateTime currentDate,
    List<Usuario> doctores,
    List<Horario> horarios,
    List<BloqueoAgenda> bloqueos,
  ) {
    final currentHash = doctores.length + horarios.length + bloqueos.length;

    if (_cachedRegions != null &&
        DateUtils.isSameDay(_lastDateCalculated, currentDate) &&
        _lastDataHash == currentHash) {
      return _cachedRegions!;
    }

    List<TimeRegion> regions = [];
    DateTime current = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      0,
      0,
    );
    DateTime endTime = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      23,
      59,
    );

    while (current.isBefore(endTime)) {
      if (!_isSlotEnabled(current, doctores, horarios, bloqueos)) {
        regions.add(
          TimeRegion(
            startTime: current,
            endTime: current.add(const Duration(minutes: 30)),
            color: Colors.grey.withOpacity(0.15),
            enablePointerInteraction: false,
            textStyle: const TextStyle(color: Colors.transparent),
          ),
        );
      }
      current = current.add(const Duration(minutes: 30));
    }

    _cachedRegions = regions;
    _lastDateCalculated = currentDate;
    _lastDataHash = currentHash;

    return regions;
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context);

    // Sincronización
    if (_calendarController.displayDate != null &&
        !DateUtils.isSameDay(
          _calendarController.displayDate,
          agendaProvider.selectedDate,
        )) {
      _calendarController.displayDate = agendaProvider.selectedDate;
    }

    final disabledRegions = _getDisabledRegions(
      agendaProvider.selectedDate,
      agendaProvider.quiropracticos,
      horariosProvider.horariosGlobales,
      bloqueosProvider.bloqueos,
    );

    return LayoutBuilder(
      builder: (context, constraits) {
        final bool showSidePanel = constraits.maxWidth > 1200;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Estándar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 24,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Agenda Diaria",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),

                  // Toggle Turno
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TurnoButton(
                          label: "Mañana",
                          icon: Icons.wb_sunny_rounded,
                          isSelected: _esTurnoManana,
                          onTap: () => setState(() => _esTurnoManana = true),
                          tooltip: "Turno de mañana (08:30 - 14:00)",
                        ),
                        const SizedBox(width: 2),
                        _TurnoButton(
                          label: "Tarde",
                          icon: Icons.nights_stay_rounded,
                          isSelected: !_esTurnoManana,
                          onTap: () => setState(() => _esTurnoManana = false),
                          tooltip: "Turno de tarde (15:30 - 21:00)",
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Botón Resumen (solo si no hay panel lateral)
                  if (!showSidePanel)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                contentPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                content: SizedBox(
                                  width: 350,
                                  height: 600,
                                  child: Stack(
                                    children: [
                                      const ClipRRect(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                        child: AgendaSidePanel(),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: IconButton.filled(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            foregroundColor: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text("Resumen"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const AgendaHeader(),

                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),

                              child: SfCalendar(
                                controller: _calendarController,
                                view: CalendarView.day,
                                headerHeight: 0,
                                viewHeaderHeight: 0,
                                specialRegions: disabledRegions,
                                onViewChanged: (ViewChangedDetails details) {
                                  if (details.visibleDates.isNotEmpty) {
                                    final nuevaFechaVisible =
                                        details.visibleDates.first;
                                    if (!DateUtils.isSameDay(
                                      nuevaFechaVisible,
                                      agendaProvider.selectedDate,
                                    )) {
                                      SchedulerBinding.instance
                                          .addPostFrameCallback((_) {
                                            agendaProvider.updateSelectedDate(
                                              nuevaFechaVisible,
                                            );
                                          });
                                    }
                                  }
                                },
                                timeSlotViewSettings: TimeSlotViewSettings(
                                  startHour: _esTurnoManana ? 8.5 : 15.5,
                                  endHour: _esTurnoManana ? 14 : 21,
                                  timeInterval: const Duration(minutes: 30),
                                  timeIntervalHeight: 80,
                                  timeFormat: 'HH:mm',
                                  timeRulerSize: 60,
                                ),

                                dataSource: CitaDataSource(
                                  agendaProvider.citas,
                                ),

                                appointmentBuilder: (
                                  BuildContext context,
                                  CalendarAppointmentDetails details,
                                ) {
                                  final Cita cita = details.appointments.first;
                                  Color colorBase;
                                  switch (cita.estado) {
                                    case 'completada':
                                      colorBase = Colors.green;
                                      break;
                                    case 'cancelada':
                                      colorBase = Colors.red;
                                      break;
                                    case 'ausente':
                                      colorBase = Colors.grey;
                                      break;
                                    default:
                                      colorBase = const Color(0xFF00AEEF);
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: colorBase.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border(
                                        left: BorderSide(
                                          color: colorBase,
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      4,
                                      4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cita.nombreClienteCompleto,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorBase,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                cita.estado.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cita.nombreQuiropractico
                                              .split(' ')
                                              .first,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },

                                onTap: (CalendarTapDetails details) {
                                  if (details.targetElement ==
                                          CalendarElement.appointment ||
                                      details.targetElement ==
                                          CalendarElement.calendarCell) {
                                    if (details.appointments != null &&
                                        details.appointments!.isNotEmpty) {
                                      final dynamic rawAppointment =
                                          details.appointments![0];
                                      if (rawAppointment is Cita) {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => CitaDetalleModal(
                                                cita: rawAppointment,
                                              ),
                                        );
                                      }
                                    } else {
                                      final fechaSeleccionada = details.date!;

                                      if (_isSlotEnabled(
                                        fechaSeleccionada,
                                        agendaProvider.quiropracticos,
                                        horariosProvider.horariosGlobales,
                                        bloqueosProvider.bloqueos,
                                      )) {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => CitaModal(
                                                selectedDate: fechaSeleccionada,
                                              ),
                                        );
                                      } else {
                                        CustomSnackBar.show(
                                          context,
                                          message:
                                              "No hay quiroprácticos disponibles en este horario",
                                          type: SnackBarType.info,
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (showSidePanel) ...[
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: const AgendaSidePanel(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TurnoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _TurnoButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.tooltip = "",
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
