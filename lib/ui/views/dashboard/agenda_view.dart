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
  // Devuelve el primer doctor disponible para una fecha
  Usuario? _getAvailableDoctor(
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

  // Comprueba si hay un doctor disponible (wrapper para compatibilidad)
  bool _isSlotEnabled(
    DateTime date,
    List<Usuario> doctores,
    List<Horario> horariosGlobales,
    List<BloqueoAgenda> bloqueos,
  ) {
    return _getAvailableDoctor(date, doctores, horariosGlobales, bloqueos) !=
        null;
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

  // Calcular horas límite dinámicas para un día y turno específico
  Map<String, double> _calculateHourBoundaries(
    List<Horario> horarios,
    DateTime date,
    bool esTurnoManana,
  ) {
    // Filtramos solo los horarios que aplican al día seleccionado
    final horariosDia =
        horarios.where((h) => h.diaSemana == date.weekday).toList();

    // Filtramos según el turno
    // Mañana: Horarios que empiezan antes de las 15:00
    // Tarde: Horarios que terminan después de las 15:00
    final horariosTurno =
        horariosDia.where((h) {
          final startHour = h.horaInicio.hour + h.horaInicio.minute / 60.0;
          final endHour = h.horaFin.hour + h.horaFin.minute / 60.0;
          if (esTurnoManana) {
            return startHour < 15.0;
          } else {
            return endHour > 15.0;
          }
        }).toList();

    if (horariosTurno.isEmpty) {
      // Defaults si no hay nadie
      return esTurnoManana
          ? {'min': 8.0, 'max': 15.0}
          : {'min': 15.0, 'max': 21.0};
    }

    int minMinutes = 24 * 60;
    int maxMinutes = 0;

    for (var h in horariosTurno) {
      final start = h.horaInicio.hour * 60 + h.horaInicio.minute;
      final end = h.horaFin.hour * 60 + h.horaFin.minute;

      if (start < minMinutes) minMinutes = start;
      if (end > maxMinutes) maxMinutes = end;
    }

    // Calcular horas base
    double minHour = (minMinutes / 30).floor() * 0.5;
    double maxHour = (maxMinutes / 30).ceil() * 0.5;

    // Ajustes específicos por Turno
    if (esTurnoManana) {
      // Mañana:
      // Start: Dynamic (clamped 0-15)
      minHour = (minHour - 0.5).clamp(0.0, 15.0);

      // End: Dynamic.
      // Antes estaba fijo a 15.0. Ahora el usuario quiere que si acaban a las 14, se muestre hasta las 14.
      // Pero si acaban a las 14:00, visualmente necesitamos hasta las 14:00 (que es 14.0 o 14.5?).
      // Si maxHour calculado es 14.0, SfCalendar renderiza HASTA 14.0 (excluido) o INCLUIDO?
      // EndHour es exclusivo. Si pones 14.0, la última celda es 13:30-14:00.
      // Si el turno acaba a las 14:00, maxHour debería ser 14.0.
      // El calculo base ya hace ceil. S i acaba 14:00 -> maxMinutes/30.ceil -> 14.0.
      // Aplicamos un margen de +0.5 si se quiere ver "espacio", pero el usuario pidió "si trabaja hasta las 15 que aparezca, sino no".
      // Vamos a probar SIN margen extra al final si coincide exacto, o +0 para que sea justo.
      // Pero SfCalendar corta. Si endHour es 14:00, no ves la línea de las 14:00 al final del todo? Si.
      // DEJAMOS maxHour tal cual viene del calculo (que ya tiene margen arriba? no, arriba le puse +0.5).
      // Reviso el calculo base:
      // double maxHour = (maxMinutes / 30).ceil() * 0.5;
      // Si acaban a las 14:00 -> 14.0.

      // La logica anterior tenia: maxHour = (maxHour + 0.5).clamp...
      // Vamos a aplicar margen SOLO si queda muy justo?
      // Usuario dice: "está en gris 14-14:30 y 14:30-15. No quiero que sea así."
      // Significa que si acaba a las 14:00, quiere que se corte en 14:00.
      // Entonces NO sumamos margen por defecto.

      maxHour = maxHour.clamp(0.0, 15.0);
    } else {
      // Tarde
      // Start: >= 15.0
      if (minHour < 15.0) minHour = 15.0;
      // Aplicamos margen inicio?
      // Si entra a las 16:00, minHour base es 16.0.
      // Queremos ver 15:30? "la primera fila es a las 15" -> No le gustó.
      // "si el lunes entra a las 9, la primera casilla es a las 8:30" (margen SI).
      // "por la tarde no... la primera es a las 16".
      // Parece que quiere margen en la mañana pero por la tarde quiere ser estricto con huecos vacíos?
      // O quiere que si empieza a las 16, empiece a las 16 (o 15:30).
      // "Nadie entra a las 15:30 y la primera fila es a las 15... Esa parte no esta bien".
      // Vale, vamos a aplicar margen de 0.5 por estética (se ve mejor la hora de entrada), pero respetando el limite de 15:00.

      minHour = (minHour - 0.5).clamp(15.0, 24.0);

      // End: Dynamic
      // "El ultimo turno... quiero que se ponga por los horarios".
      // Si acaban a las 20:00 -> maxHour base es 20.0.
      // Mostramos hasta 20:00.
      maxHour = maxHour.clamp(15.0, 24.0);
    }

    return {'min': minHour, 'max': maxHour};
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

    // Calcular límites horarios dinámicos
    final boundaries = _calculateHourBoundaries(
      horariosProvider.horariosGlobales,
      agendaProvider.selectedDate,
      _esTurnoManana,
    );
    final minHour = boundaries['min']!;
    final maxHour = boundaries['max']!;

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
                          tooltip:
                              "Turno de mañana (${_formatHour(minHour)} - 15:00)",
                        ),
                        const SizedBox(width: 2),
                        _TurnoButton(
                          label: "Tarde",
                          icon: Icons.nights_stay_rounded,
                          isSelected: !_esTurnoManana,
                          onTap: () => setState(() => _esTurnoManana = false),
                          tooltip:
                              "Turno de tarde (15:00 - ${_formatHour(maxHour)})",
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
                                  startHour: minHour,
                                  endHour: maxHour,
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

                                      final doctorDisponible =
                                          _getAvailableDoctor(
                                            fechaSeleccionada,
                                            agendaProvider.quiropracticos,
                                            horariosProvider.horariosGlobales,
                                            bloqueosProvider.bloqueos,
                                          );

                                      if (doctorDisponible != null) {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => CitaModal(
                                                selectedDate: fechaSeleccionada,
                                                preSelectedDoctor:
                                                    doctorDisponible,
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

  String _formatHour(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
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
