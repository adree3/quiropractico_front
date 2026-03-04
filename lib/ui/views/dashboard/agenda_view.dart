import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
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
  final DateTime? initialDate;

  const AgendaView({super.key, this.initialDate});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final CalendarController _calendarController = CalendarController();
  List<TimeRegion>? _cachedRegions;
  DateTime? _lastDateCalculated;
  int? _lastDataHash;
  bool _sidePanelCollapsed = false;

  @override
  void initState() {
    super.initState();
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

      if (widget.initialDate != null) {
        agendaProvider.updateSelectedDate(widget.initialDate!);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _calendarController.view == CalendarView.day) {
            // Un pequeño truco de Syncfusion: asignar el displayDate exacto incluyendo minutos
            // obliga al calendario a que el TimeRuler mueva esa hora al inicio visible.
            // Para que no se quede pegado arriba, restamos 30 minutos visuales.
            // Usamos displayDate directo sin restar 30 mins
            _calendarController.displayDate = widget.initialDate;
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _calendarController.view == CalendarView.day) {
            final ahora = DateTime.now();
            final agendaDataDate =
                Provider.of<AgendaProvider>(
                  context,
                  listen: false,
                ).selectedDate;
            if (DateUtils.isSameDay(ahora, agendaDataDate)) {
              _calendarController.displayDate = ahora;
            }
          }
        });
      }
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

  // Calcular horas límite dinámicas para un día
  Map<String, double> _calculateHourBoundaries(
    List<Horario> horarios,
    DateTime date,
  ) {
    // Filtramos solo los horarios que aplican al día seleccionado
    final horariosDia =
        horarios.where((h) => h.diaSemana == date.weekday).toList();

    if (horariosDia.isEmpty) {
      // Defaults si no hay nadie en todo el dia
      return {'min': 8.0, 'max': 21.0};
    }

    int minMinutes = 24 * 60;
    int maxMinutes = 0;

    for (var h in horariosDia) {
      final start = h.horaInicio.hour * 60 + h.horaInicio.minute;
      final end = h.horaFin.hour * 60 + h.horaFin.minute;

      if (start < minMinutes) minMinutes = start;
      if (end > maxMinutes) maxMinutes = end;
    }

    // Calcular horas base
    double minHour = (minMinutes / 30).floor() * 0.5;
    double maxHour = (maxMinutes / 30).ceil() * 0.5;

    // Aplicamos margen de media hora SÓLO por arriba para que el texto de la 1ª hora (ej: 09:00) no quede cortado.
    minHour = (minHour - 0.5).clamp(0.0, 24.0);
    // maxHour se queda exacto para no dejar espacio abajo
    // maxHour = (maxHour + 0.5).clamp(0.0, 24.0);

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

    final boundaries = _calculateHourBoundaries(
      horariosProvider.horariosGlobales,
      agendaProvider.selectedDate,
    );
    final minHour = boundaries['min']!;
    final maxHour = boundaries['max']!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 700;

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

                  const Spacer(),

                  // Botón + Cita
                  Tooltip(
                    message: "Crear Cita",
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final now = DateTime.now();
                        final agendaProv = Provider.of<AgendaProvider>(
                          context,
                          listen: false,
                        );
                        final fechaSel = agendaProv.selectedDate;
                        final horaInicio = DateTime(
                          fechaSel.year,
                          fechaSel.month,
                          fechaSel.day,
                          now.hour + 1,
                          0,
                        );
                        showDialog(
                          context: context,
                          builder:
                              (context) => CitaModal(selectedDate: horaInicio),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Cita"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            // En modo Drawer flotante, añade un padding extra derecho si está en modo mini (80)
                            // para que la agenda se pueda leer sin montarse
                            padding: EdgeInsets.only(
                              right:
                                  !isDesktop && _sidePanelCollapsed ? 100 : 0,
                            ),
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
                                        onViewChanged: (
                                          ViewChangedDetails details,
                                        ) {
                                          if (details.visibleDates.isNotEmpty) {
                                            final nuevaFechaVisible =
                                                details.visibleDates.first;
                                            if (!DateUtils.isSameDay(
                                              nuevaFechaVisible,
                                              agendaProvider.selectedDate,
                                            )) {
                                              SchedulerBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    agendaProvider
                                                        .updateSelectedDate(
                                                          nuevaFechaVisible,
                                                        );
                                                  });
                                            }
                                          }
                                        },
                                        timeSlotViewSettings:
                                            TimeSlotViewSettings(
                                              startHour: minHour,
                                              endHour: maxHour,
                                              timeInterval: const Duration(
                                                minutes: 30,
                                              ),
                                              timeIntervalHeight: 80,
                                              timeFormat: 'HH:mm',
                                              timeRulerSize: 60,
                                            ),

                                        dataSource: AgendaDataSource(
                                          agendaProvider.citas,
                                          bloqueosProvider.bloqueos,
                                          agendaProvider.selectedDate,
                                        ),

                                        appointmentBuilder: (
                                          BuildContext context,
                                          CalendarAppointmentDetails details,
                                        ) {
                                          final dynamic rawAppointment =
                                              details.appointments.first;

                                          // ---- DISEÑO DE BLOQUEO DE AGENDA (Fondo Naranja) ----
                                          if (rawAppointment is BloqueoAgenda) {
                                            return MouseRegion(
                                              cursor:
                                                  SystemMouseCursors
                                                      .basic, // Cursor básico, no es clicable
                                              child: GestureDetector(
                                                onTap: () {
                                                  // Capturar click y no hacer nada, bloquea el paso hacia la celda del calendario subyacente
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange
                                                          .shade50
                                                          .withOpacity(0.9),
                                                      border: Border.all(
                                                        color:
                                                            Colors
                                                                .orange
                                                                .shade200,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        // Marca de Agua (Warn pattern/Stripes)
                                                        Positioned(
                                                          right: -15,
                                                          bottom: -15,
                                                          child: Icon(
                                                            Icons.block,
                                                            size: 80,
                                                            color: Colors
                                                                .orange
                                                                .shade200
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                          ),
                                                        ),
                                                        // Contenido
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          child: Center(
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color:
                                                                      Colors
                                                                          .orange
                                                                          .shade700,
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    "Bloqueo por ${rawAppointment.motivo.isNotEmpty ? rawAppointment.motivo : "Clínica"}",
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .orange
                                                                              .shade900,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // ---- DISEÑO DE CITA ----
                                          if (rawAppointment is Cita) {
                                            final Cita cita = rawAppointment;
                                            Color colorBase;
                                            IconData iconBase;
                                            switch (cita.estado) {
                                              case 'completada':
                                                colorBase = Colors.green;
                                                iconBase =
                                                    Icons.check_circle_rounded;
                                                break;
                                              case 'cancelada':
                                                colorBase = Colors.red;
                                                iconBase = Icons.cancel_rounded;
                                                break;
                                              case 'ausente':
                                                colorBase = Colors.grey;
                                                iconBase =
                                                    Icons.person_off_rounded;
                                                break;
                                              default:
                                                colorBase = const Color(
                                                  0xFF00AEEF,
                                                );
                                                iconBase =
                                                    Icons
                                                        .calendar_month_rounded;
                                            }
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Tooltip(
                                                message: "Ver detalles",
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: colorBase
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: colorBase
                                                          .withOpacity(0.3),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Container(
                                                        width: 5,
                                                        decoration:
                                                            BoxDecoration(
                                                              color: colorBase,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero,
                                                            ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.fromLTRB(
                                                                8,
                                                                4,
                                                                8,
                                                                4,
                                                              ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      cita.nombreClienteCompleto,
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.black87,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 4,
                                                                    ),
                                                                    Text(
                                                                      cita.nombreQuiropractico
                                                                          .split(
                                                                            ' ',
                                                                          )
                                                                          .first,
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.black54,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              // Icono del Badge tamaño estandar Cliente Bonos Tab
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: colorBase
                                                                      .withOpacity(
                                                                        0.15,
                                                                      ),
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                                child: Icon(
                                                                  iconBase,
                                                                  color:
                                                                      colorBase,
                                                                  size: 22,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return const SizedBox.shrink();
                                        },

                                        onTap: (CalendarTapDetails details) {
                                          if (details.targetElement ==
                                                  CalendarElement.appointment ||
                                              details.targetElement ==
                                                  CalendarElement
                                                      .calendarCell) {
                                            if (details.appointments != null &&
                                                details
                                                    .appointments!
                                                    .isNotEmpty) {
                                              final dynamic rawAppointment =
                                                  details.appointments![0];
                                              if (rawAppointment is Cita) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) =>
                                                          CitaDetalleModal(
                                                            cita:
                                                                rawAppointment,
                                                          ),
                                                );
                                                return; // Evita seguir y "agendar"
                                              }
                                              // Si tocamos un bloqueo, cae a la lógica de abajo de "celda libre"
                                            }

                                            // Comportamiento de celda libre (o Bloqueo visual sin modal)
                                            final fechaSeleccionada =
                                                details.date!;

                                            final doctorDisponible =
                                                _getAvailableDoctor(
                                                  fechaSeleccionada,
                                                  agendaProvider.quiropracticos,
                                                  horariosProvider
                                                      .horariosGlobales,
                                                  bloqueosProvider.bloqueos,
                                                );

                                            if (doctorDisponible != null) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => CitaModal(
                                                      selectedDate:
                                                          fechaSeleccionada,
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
                                            // } <- Este era el else
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Modo Desktop: Panel como columna que empuja
                        if (isDesktop) ...[
                          const SizedBox(width: 20),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _sidePanelCollapsed ? 80 : 320,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
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
                              child: AgendaSidePanel(
                                isCollapsed: _sidePanelCollapsed,
                                onToggle: () {
                                  setState(() {
                                    _sidePanelCollapsed = !_sidePanelCollapsed;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Modo Drawer (Tablet/Mobile): Panel Flotante
                  if (!isDesktop)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: _sidePanelCollapsed ? 80 : 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1.0,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(-5, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          child: AgendaSidePanel(
                            isCollapsed: _sidePanelCollapsed,
                            onToggle: () {
                              setState(() {
                                _sidePanelCollapsed = !_sidePanelCollapsed;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
