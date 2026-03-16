import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/ui_provider.dart';
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
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
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

  // Seguimiento para doble toque en Mes
  DateTime? _lastTapTime;
  DateTime? _lastTapDate;

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
    // Si es vista diferente a diaria, invalidamos cache por ahora para simplificar
    // o calculamos un hash que incluya el inicio de la semana
    final bool isDayView = _calendarController.view == CalendarView.day;

    if (isDayView &&
        _cachedRegions != null &&
        DateUtils.isSameDay(_lastDateCalculated, currentDate) &&
        _lastDataHash == currentHash) {
      return _cachedRegions!;
    }

    List<TimeRegion> regions = [];

    // Si es semana, calculamos para los 7 días (o los visibles)
    int daysToCalculate = isDayView ? 1 : 7;
    DateTime startDate;

    if (isDayView) {
      startDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        0,
        0,
      );
    } else {
      // Lunes de la semana actual
      startDate = currentDate.subtract(Duration(days: currentDate.weekday - 1));
      startDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
      );
    }

    for (int i = 0; i < daysToCalculate; i++) {
      DateTime day = startDate.add(Duration(days: i));
      DateTime current = day;
      DateTime endTime = DateTime(day.year, day.month, day.day, 23, 59);

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
    }

    if (isDayView) {
      _cachedRegions = regions;
      _lastDateCalculated = currentDate;
      _lastDataHash = currentHash;
    }

    return regions;
  }

  // Calcular horas límite dinámicas para un conjunto de días (global para la vista)
  Map<String, double> _calculateHourBoundaries(
    List<Horario> horarios,
    List<DateTime> dates,
  ) {
    // Obtenemos los días de la semana únicos presentes en las fechas proporcionadas
    final weekDays = dates.map((d) => d.weekday).toSet();

    // Filtramos solo los horarios que aplican a los días visibles
    final horariosVisibles =
        horarios.where((h) => weekDays.contains(h.diaSemana)).toList();

    if (horariosVisibles.isEmpty) {
      // Defaults si no hay nadie en todos los días visibles
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

    // Calcular horas base
    double minHour = (minMinutes / 30).floor() * 0.5;
    double maxHour = (maxMinutes / 30).ceil() * 0.5;

    // Aplicamos margen de media hora SÓLO por arriba para que el texto de la 1ª hora (ej: 09:00) no quede cortado.
    minHour = (minHour - 0.5).clamp(0.0, 24.0);

    return {'min': minHour, 'max': maxHour};
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UiProvider>(context);
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context);

    // Sincronización de fecha y VISTA
    if (_calendarController.displayDate != null &&
        !DateUtils.isSameDay(
          _calendarController.displayDate,
          agendaProvider.selectedDate,
        )) {
      _calendarController.displayDate = agendaProvider.selectedDate;
    }

    // Mapeo forzado a WorkWeek para la vista semanal si queremos filtrar días no laborales
    CalendarView calendarView = agendaProvider.currentView;
    if (calendarView == CalendarView.week) {
      calendarView = CalendarView.workWeek;
    }

    // Sincronizar la vista del controlador con la vista mapeada (importante para workWeek)
    if (_calendarController.view != calendarView) {
      _calendarController.view = calendarView;
    }

    final disabledRegions = _getDisabledRegions(
      agendaProvider.selectedDate,
      agendaProvider.quiropracticos,
      horariosProvider.horariosGlobales,
      bloqueosProvider.bloqueos,
    );

    // Calculamos las fechas visibles para determinar los límites de horas
    List<DateTime> visibleDates = [];
    if (agendaProvider.currentView == CalendarView.day) {
      visibleDates = [agendaProvider.selectedDate];
    } else {
      // Para semana o mes (aunque mes sea distinto, calculamos el rango de la semana seleccionada)
      final monday = agendaProvider.selectedDate.subtract(
        Duration(days: agendaProvider.selectedDate.weekday - 1),
      );
      visibleDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    }

    final boundaries = _calculateHourBoundaries(
      horariosProvider.horariosGlobales,
      visibleDates,
    );
    final minHour = boundaries['min']!;
    final maxHour = boundaries['max']!;

    // Días no laborales para ocultar en la vista semanal
    final workingDays = horariosProvider.diasActivosSemana.toSet();
    final nonWorkingDays =
        <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ].where((d) => !workingDays.contains(d)).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 700;

          String tituloAgenda = "Agenda Diaria";
          if (agendaProvider.currentView == CalendarView.week) {
            tituloAgenda = "Agenda Semanal";
          } else if (agendaProvider.currentView == CalendarView.month) {
            tituloAgenda = "Agenda Mensual";
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SUPERIOR (TITULO + BOTÓN NUEVA CITA)
              Container(
                width: constraints.maxWidth,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(height: 40, width: 10),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tituloAgenda,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HoverableActionButton(
                      label: "Nueva Cita",
                      icon: Icons.add,
                      isPrimary: true,
                      tooltip: "Crear una nueva cita",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const CitaModal(),
                        );
                      },
                    ),
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
                                    !isDesktop &&
                                            uiProvider
                                                .isAgendaSidePanelCollapsed
                                        ? 100
                                        : 0,
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
                                    AgendaHeader(),

                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),

                                        child: SfCalendar(
                                          controller: _calendarController,
                                          view: calendarView,
                                          firstDayOfWeek: 1, // Lunes
                                          headerHeight: 0,
                                          viewHeaderHeight:
                                              agendaProvider.currentView ==
                                                      CalendarView.day
                                                  ? 0
                                                  : 60,
                                          viewHeaderStyle: ViewHeaderStyle(
                                            dayTextStyle: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            dateTextStyle: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          specialRegions: disabledRegions,
                                          onViewChanged: (
                                            ViewChangedDetails details,
                                          ) {
                                            if (details
                                                .visibleDates
                                                .isNotEmpty) {
                                              final nuevaFechaVisible =
                                                  details.visibleDates.first;

                                              // Sincronizar selectedDate si ha cambiado el día base
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

                                              // Carga de datos por rango si estamos en Semana o Mes
                                              if (agendaProvider.currentView !=
                                                  CalendarView.day) {
                                                SchedulerBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      agendaProvider
                                                          .getCitasPorRango(
                                                            details
                                                                .visibleDates
                                                                .first,
                                                            details
                                                                .visibleDates
                                                                .last,
                                                          );
                                                    });
                                              }
                                            }
                                          },
                                          timeSlotViewSettings:
                                              TimeSlotViewSettings(
                                                startHour: minHour,
                                                endHour: maxHour,
                                                nonWorkingDays: nonWorkingDays,
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

                                          // MonthViewSettings con modo appointment para que use el appointmentBuilder
                                          monthViewSettings:
                                              const MonthViewSettings(
                                                appointmentDisplayMode:
                                                    MonthAppointmentDisplayMode
                                                        .appointment,
                                                showTrailingAndLeadingDates:
                                                    false,
                                              ),

                                          monthCellBuilder: (context, details) {
                                            final date = details.date;
                                            final isWorkDay = _isDayWorkable(
                                              date,
                                              agendaProvider.quiropracticos,
                                              horariosProvider.horariosGlobales,
                                            );
                                            final isGlobalBlocked =
                                                _isGlobalBlocked(
                                                  date,
                                                  bloqueosProvider.bloqueos,
                                                );
                                            final bool isToday =
                                                DateUtils.isSameDay(
                                                  date,
                                                  DateTime.now(),
                                                );
                                            final count =
                                                agendaProvider.citas
                                                    .where(
                                                      (a) =>
                                                          DateUtils.isSameDay(
                                                            a.fechaHoraInicio,
                                                            date,
                                                          ),
                                                    )
                                                    .length;

                                            Color? bgColor;
                                            if (!isWorkDay) {
                                              bgColor = Colors.grey.shade100;
                                            } else if (isGlobalBlocked) {
                                              bgColor = Colors.red.shade50;
                                            }

                                            return Tooltip(
                                              message: isGlobalBlocked ? "Día bloqueado" : "",
                                              child: MouseRegion(
                                                cursor: (isWorkDay && !isGlobalBlocked)
                                                    ? SystemMouseCursors.click
                                                    : SystemMouseCursors.basic,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: bgColor,
                                                    border: Border.all(
                                                      color: Colors.grey.shade200,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      // CONTADOR ARRIBA IZQUIERDA
                                                      if (count > 3)
                                                        Positioned(
                                                          top: 5,
                                                          left: 5,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 1,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors.blue.shade50,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(4),
                                                            ),
                                                            child: Text(
                                                              "+${count - 3} más",
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                color:
                                                                    Colors
                                                                        .blue
                                                                        .shade700,
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      // DÍA ARRIBA DERECHA
                                                      Positioned(
                                                        top: 5,
                                                        right: 5,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                isToday
                                                                    ? const Color(
                                                                      0xFF01AEEF,
                                                                    ) // Color primario
                                                                    : Colors
                                                                        .transparent,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Text(
                                                            date.day.toString(),
                                                            style: TextStyle(
                                                              color:
                                                                  isToday
                                                                      ? Colors.white
                                                                      : (isWorkDay
                                                                          ? Colors
                                                                              .black87
                                                                          : Colors
                                                                              .grey),
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  isToday
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (isGlobalBlocked)
                                                        const Center(
                                                          child: Icon(
                                                            Icons
                                                                .lock_clock_outlined,
                                                            color: Colors.black26,
                                                            size: 16,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },

                                          appointmentBuilder: (
                                            BuildContext context,
                                            CalendarAppointmentDetails details,
                                          ) {
                                            final dynamic rawAppointment =
                                                details.appointments.first;

                                            // ---- DISEÑO PARA VISTA MENSUAL (Píldoras minimalistas) ----
                                            if (agendaProvider.currentView ==
                                                CalendarView.month) {
                                              if (rawAppointment is Cita) {
                                                final Cita cita =
                                                    rawAppointment;
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
                                                    colorBase = const Color(
                                                      0xFF00AEEF,
                                                    );
                                                }

                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 1,
                                                        horizontal: 2,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorBase
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 3,
                                                        decoration: BoxDecoration(
                                                          color: colorBase,
                                                          borderRadius:
                                                              const BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      4,
                                                                    ),
                                                                bottomLeft:
                                                                    Radius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          cita.nombreClienteCompleto,
                                                          style: TextStyle(
                                                            color: colorBase
                                                                .withAlpha(200),
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            letterSpacing: -0.2,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            }

                                            // ---- DISEÑO DE BLOQUEO DE AGENDA (Día/Semana) ----
                                            if (rawAppointment
                                                is BloqueoAgenda) {
                                              return MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.basic,
                                                child: GestureDetector(
                                                  onTap: () {},
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
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
                                                                            Colors.orange.shade900,
                                                                        fontWeight:
                                                                            FontWeight.bold,
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

                                            // ---- DISEÑO DE CITA (Día/Semana) ----
                                            if (rawAppointment is Cita) {
                                              final Cita cita = rawAppointment;
                                              Color colorBase;
                                              IconData iconBase;
                                              switch (cita.estado) {
                                                case 'completada':
                                                  colorBase = Colors.green;
                                                  iconBase =
                                                      Icons
                                                          .check_circle_rounded;
                                                  break;
                                                case 'cancelada':
                                                  colorBase = Colors.red;
                                                  iconBase =
                                                      Icons.cancel_rounded;
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
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: Tooltip(
                                                  message: "Ver detalles",
                                                  child: Container(
                                                    margin: EdgeInsets.zero,
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
                                                                color:
                                                                    colorBase,
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
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
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
                                                                if (agendaProvider
                                                                        .currentView ==
                                                                    CalendarView
                                                                        .day)
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
                                            // DETECCIÓN DE DOBLE TOQUE EN MES
                                            if (agendaProvider.currentView ==
                                                CalendarView.month) {
                                              final date = details.date;
                                              if (date != null &&
                                                  (!_isDayWorkable(
                                                        date,
                                                        agendaProvider
                                                            .quiropracticos,
                                                        horariosProvider
                                                            .horariosGlobales,
                                                      ) ||
                                                      _isGlobalBlocked(
                                                        date,
                                                        bloqueosProvider
                                                            .bloqueos,
                                                      ))) {
                                                // Bloquear interacción en días no laborables o bloqueados
                                                return;
                                              }

                                              final now = DateTime.now();
                                              if (_lastTapTime != null &&
                                                  _lastTapDate != null &&
                                                  now.difference(
                                                        _lastTapTime!,
                                                      ) <
                                                      const Duration(
                                                        milliseconds: 400,
                                                      ) &&
                                                  DateUtils.isSameDay(
                                                    _lastTapDate,
                                                    details.date,
                                                  )) {
                                                // DOBLE CLICK -> CAMBIAR A DÍA
                                                agendaProvider.setCurrentView(
                                                  CalendarView.day,
                                                );
                                                agendaProvider
                                                    .updateSelectedDate(
                                                      details.date!,
                                                    );
                                                _lastTapTime = null;
                                                return;
                                              }
                                              _lastTapTime = now;
                                              _lastTapDate = details.date;
                                            }

                                            // CASE 1: Clic directo sobre una cita (Appointment)
                                            if (details.targetElement ==
                                                CalendarElement.appointment) {
                                              if (details.appointments !=
                                                      null &&
                                                  details
                                                      .appointments!
                                                      .isNotEmpty) {
                                                final dynamic rawAppointment =
                                                    details.appointments![0];
                                                if (rawAppointment is Cita) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => CitaDetalleModal(
                                                          cita: rawAppointment,
                                                        ),
                                                  ).then((value) {
                                                    if (value == 'edit') {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => CitaModal(
                                                              citaExistente:
                                                                  rawAppointment,
                                                            ),
                                                      ).then((valEdit) {
                                                        if (valEdit == true) {
                                                          agendaProvider
                                                              .refreshCurrentView();
                                                        }
                                                      });
                                                    } else if (value == true) {
                                                      agendaProvider
                                                          .refreshCurrentView();
                                                    }
                                                  });
                                                }
                                              }
                                            }
                                            // CASE 2: Clic en la celda del calendario (el hueco)
                                            else if (details.targetElement ==
                                                CalendarElement.calendarCell) {
                                              // Comportamiento de celda libre
                                              DateTime? fechaSeleccionada =
                                                  details.date;
                                              if (fechaSeleccionada == null) {
                                                return;
                                              }

                                              // VALIDACIÓN DE DÍA BLOQUEADO/NO LABORABLE TAMBIÉN EN CLIC SIMPLE
                                              if (!_isDayWorkable(
                                                    fechaSeleccionada,
                                                    agendaProvider
                                                        .quiropracticos,
                                                    horariosProvider
                                                        .horariosGlobales,
                                                  ) ||
                                                  _isGlobalBlocked(
                                                    fechaSeleccionada,
                                                    bloqueosProvider.bloqueos,
                                                  )) {
                                                return;
                                              }

                                              if (fechaSeleccionada.hour == 0 &&
                                                  agendaProvider.currentView ==
                                                      CalendarView.month) {
                                                fechaSeleccionada = DateTime(
                                                  fechaSeleccionada.year,
                                                  fechaSeleccionada.month,
                                                  fechaSeleccionada.day,
                                                  9,
                                                  0,
                                                );
                                              }

                                              // VALIDACIÓN DE DISPONIBILIDAD (ZONA GRIS)
                                              if (!_isSlotEnabled(
                                                fechaSeleccionada,
                                                agendaProvider.quiropracticos,
                                                horariosProvider
                                                    .horariosGlobales,
                                                bloqueosProvider.bloqueos,
                                              )) {
                                                CustomSnackBar.show(
                                                  context,
                                                  message:
                                                      "No hay disponibilidad en este horario",
                                                  type: SnackBarType.info,
                                                );
                                                return;
                                              }

                                              final doctorDisponible =
                                                  _getAvailableDoctor(
                                                    fechaSeleccionada,
                                                    agendaProvider
                                                        .quiropracticos,
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
                                                ).then((value) {
                                                  if (value == true) {
                                                    agendaProvider
                                                        .refreshCurrentView();
                                                  }
                                                });
                                              } else {
                                                if (agendaProvider
                                                        .currentView ==
                                                    CalendarView.month) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (context) => CitaModal(
                                                          selectedDate:
                                                              fechaSeleccionada,
                                                        ),
                                                  ).then((value) {
                                                    if (value == true) {
                                                      agendaProvider
                                                          .refreshCurrentView();
                                                    }
                                                  });
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
                          ),

                          // Modo Desktop: Panel como columna que empuja
                          if (isDesktop) ...[
                            const SizedBox(width: 20),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width:
                                  uiProvider.isAgendaSidePanelCollapsed
                                      ? 80
                                      : 320,
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
                                  isCollapsed:
                                      uiProvider.isAgendaSidePanelCollapsed,
                                  onToggle: () {
                                    uiProvider.toggleAgendaSidePanel();
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
                          width:
                              uiProvider.isAgendaSidePanelCollapsed ? 80 : 320,
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
                              isCollapsed:
                                  uiProvider.isAgendaSidePanelCollapsed,
                              onToggle: () {
                                uiProvider.toggleAgendaSidePanel();
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
      ),
    );
  }

  bool _isDayWorkable(
    DateTime date,
    List<Usuario> docs,
    List<Horario> globals,
  ) {
    // Es laborable si hay algún horario global definido para ese día de la semana
    return globals.any((g) => g.diaSemana == date.weekday);
  }

  bool _isGlobalBlocked(DateTime date, List<BloqueoAgenda> bloqueos) {
    // Es bloqueo global si no tiene quiropráctico asociado y coincide el día
    return bloqueos.any(
      (b) => b.idQuiropractico == null && DateUtils.isSameDay(date, b.fechaInicio),
    );
  }
}
