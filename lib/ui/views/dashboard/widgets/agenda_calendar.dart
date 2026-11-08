import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/modals/reprogramar_cita_dialog.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_utils.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:quiropractico_front/ui/widgets/whatsapp_status_badge.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';

class AgendaCalendar extends StatefulWidget {
  final CalendarController controller;
  final CalendarView view;
  final List<TimeRegion> specialRegions;
  final List<int> nonWorkingDays;
  final double minHour;
  final double maxHour;
  final AgendaDataSource dataSource;

  const AgendaCalendar({
    super.key,
    required this.controller,
    required this.view,
    required this.specialRegions,
    required this.nonWorkingDays,
    required this.minHour,
    required this.maxHour,
    required this.dataSource,
  });

  @override
  State<AgendaCalendar> createState() => _AgendaCalendarState();
}

class _AgendaCalendarState extends State<AgendaCalendar> {
  int _lastExternalTick = -1;

  CalendarController get controller => widget.controller;
  CalendarView get view => widget.view;
  List<TimeRegion> get specialRegions => widget.specialRegions;
  List<int> get nonWorkingDays => widget.nonWorkingDays;
  double get minHour => widget.minHour;
  double get maxHour => widget.maxHour;
  AgendaDataSource get dataSource => widget.dataSource;

  @override
  void initState() {
    super.initState();
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    _lastExternalTick = agendaProvider.externalNavigationTick;
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context, listen: false);
    final horariosProvider = Provider.of<HorariosProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Escalado visual de los slots
    final double dynamicHeight = (80.0 / 30.0) * settingsProvider.duracionCitaMinutos;
    final double clampedHeight = dynamicHeight.clamp(50.0, 120.0);

    return SfCalendar(
      controller: controller,
      view: view,
      viewNavigationMode: ViewNavigationMode.none,
      firstDayOfWeek: 1, // Lunes
      headerHeight: 0,
      viewHeaderHeight: agendaProvider.currentView == CalendarView.day ? 0 : 60,
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
      specialRegions: specialRegions,
      // Desbloqueo nativo de Drag & Drop y Resize
      allowDragAndDrop: true,
      allowAppointmentResize: true,
      dragAndDropSettings: const DragAndDropSettings(
        allowNavigation: true,
        allowScroll: true,
        showTimeIndicator: true,
      ),
      onDragEnd: (details) => _handleDragEnd(
        context,
        details,
        agendaProvider,
        horariosProvider,
        bloqueosProvider,
        settingsProvider,
      ),
      onAppointmentResizeEnd: (details) => _handleResizeEnd(
        context,
        details,
        agendaProvider,
        settingsProvider,
      ),
      onViewChanged: (ViewChangedDetails details) {
        if (details.visibleDates.isEmpty) return;

        final DateTime nuevaFechaVisible = details.visibleDates.first;
        final bool isDayView = agendaProvider.currentView == CalendarView.day;
        final bool esSwipe = _lastExternalTick == agendaProvider.externalNavigationTick;
        _lastExternalTick = agendaProvider.externalNavigationTick;

        // 1. Swipe Inteligente en Vista Diaria
        if (isDayView && esSwipe) {
          final bool esValido = AgendaUtils.isDateWorkable(
            nuevaFechaVisible,
            horariosProvider.horariosGlobales,
            bloqueosProvider.bloqueos,
            idQuiropratico: agendaProvider.filterDoctorId,
          );

          if (!esValido) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final direccionAdelante = nuevaFechaVisible.isAfter(agendaProvider.selectedDate);
              final diaReal = AgendaUtils.findNextWorkDay(
                nuevaFechaVisible,
                horariosProvider.horariosGlobales,
                bloqueosProvider.bloqueos,
                forward: direccionAdelante,
                idQuiropratico: agendaProvider.filterDoctorId,
              );
              controller.displayDate = diaReal;
              agendaProvider.updateSelectedDate(diaReal);
            });
            return;
          }
        }

        // 2. Corrección de Rango del Mes en el Cortafuegos (Stale-While-Revalidate sin fogonazos)
        // Syncfusion a veces devuelve 42 días en la vista mensual, y a veces 35, dependiendo de cómo cuadre el mes.
        if (agendaProvider.currentView == CalendarView.month) {
          // Si la nueva fecha central del mes ya está dentro de un rango pedido previamente, no petar la red.
          final centralDate = details.visibleDates[(details.visibleDates.length / 2).floor()];
          if (agendaProvider.lastRangeStart != null && agendaProvider.lastRangeEnd != null) {
            if (centralDate.isAfter(agendaProvider.lastRangeStart!) &&
                centralDate.isBefore(agendaProvider.lastRangeEnd!)) {
              return; 
            }
          }
        }

        final DateTime fechaRepresentativa = agendaProvider.currentView == CalendarView.month
            ? details.visibleDates[(details.visibleDates.length / 2).floor()]
            : details.visibleDates.first;
        final DateTime nuevaInicio = details.visibleDates.first;
        final DateTime nuevaFin = details.visibleDates.last;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          agendaProvider.onCalendarViewChanged(
            fechaRepresentativa: fechaRepresentativa,
            rangoInicio: nuevaInicio,
            rangoFin: nuevaFin,
          );
        });
      },
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: minHour,
        endHour: maxHour,
        nonWorkingDays: nonWorkingDays,
        timeInterval: Duration(minutes: settingsProvider.duracionCitaMinutos),
        timeIntervalHeight: clampedHeight,
        timeFormat: 'HH:mm',
        timeRulerSize: 60,
      ),
      dataSource: dataSource,
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayCount: 3,
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showTrailingAndLeadingDates: false,
      ),
      monthCellBuilder: (context, details) => _buildMonthCell(context, details, agendaProvider, bloqueosProvider, horariosProvider),
      appointmentBuilder: (context, details) => _buildAppointment(context, details, agendaProvider),
      onTap: (details) => _handleOnTap(context, details, agendaProvider, horariosProvider, bloqueosProvider),
    );
  }

  Widget _buildMonthCell(
    BuildContext context,
    MonthCellDetails details,
    AgendaProvider agendaProvider,
    AgendaBloqueoProvider bloqueosProvider,
    HorariosProvider horariosProvider,
  ) {
    final date = details.date;
    final bool isWorkDay;
    if (agendaProvider.filterDoctorId != null) {
      final bool docTieneTurno = horariosProvider.horariosGlobales.any(
        (h) => h.idQuiropractico == agendaProvider.filterDoctorId && h.diaSemana == date.weekday,
      );
      final checkDay = DateTime(date.year, date.month, date.day);
      final bool docBloqueado = bloqueosProvider.bloqueos.any((b) {
        if (b.idQuiropractico != agendaProvider.filterDoctorId) return false;
        final startDay = DateTime(b.fechaInicio.year, b.fechaInicio.month, b.fechaInicio.day);
        final endDay = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
        return !checkDay.isBefore(startDay) && !checkDay.isAfter(endDay);
      });
      isWorkDay = docTieneTurno && !docBloqueado;
    } else {
      isWorkDay = !nonWorkingDays.contains(date.weekday);
    }
    final bool isGlobalBlocked = AgendaUtils.isGlobalBlocked(date, bloqueosProvider.bloqueos);
    final bool isToday = DateUtils.isSameDay(date, DateTime.now());
    final int count = details.appointments.whereType<Cita>().length;

    Color? bgColor;
    if (!isWorkDay) {
      bgColor = Colors.grey.shade200;
    } else if (isGlobalBlocked) {
      bgColor = Colors.red.shade50;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          if (count > 3)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Tooltip(
                  message: "+${count - 3} citas más",
                  child: Text(
                    "+${count - 3}",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 5,
            right: 5,
            child: Tooltip(
              message: isToday ? "Hoy (clic para ver día)" : "Ver vista diaria del ${date.day}",
              child: MouseRegion(
                cursor: (isWorkDay && !isGlobalBlocked) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: InkWell(
                  onTap: (isWorkDay && !isGlobalBlocked)
                      ? () {
                          agendaProvider.setCurrentView(CalendarView.day);
                          agendaProvider.updateSelectedDate(date);
                          controller.view = CalendarView.day;
                          controller.displayDate = date;
                        }
                      : null,
                  hoverColor: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF01AEEF) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isToday ? Colors.white : (isWorkDay ? Colors.black87 : Colors.grey),
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isGlobalBlocked)
            const Center(
              child: Tooltip(
                message: "Día bloqueado",
                child: Icon(
                  Icons.lock_clock_outlined,
                  color: Colors.black26,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
    AgendaProvider agendaProvider,
  ) {
    final dynamic rawAppointment = details.appointments.first;

    // ---- BLOQUEO (Día / Semana) ----
    if (rawAppointment is BloqueoAgenda) {
      return _buildBloqueoTile(rawAppointment);
    }

    // ---- CITA (Mes / Día / Semana) ----
    if (rawAppointment is Cita) {
      return _buildCitaTile(rawAppointment, agendaProvider);
    }

    return const SizedBox.shrink();
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'completada': return Colors.green;
      case 'cancelada': return Colors.red;
      case 'ausente': return Colors.grey;
      default: return const Color(0xFF00AEEF);
    }
  }

  Widget _buildBloqueoTile(BloqueoAgenda bloqueo) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50.withValues(alpha: 0.9),
              border: Border.all(color: Colors.orange.shade200, width: 1.0),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15, bottom: -15,
                  child: Icon(Icons.block, size: 80, color: Colors.orange.shade200.withValues(alpha: 0.4)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Bloqueo por ${bloqueo.motivo.isNotEmpty ? bloqueo.motivo : "Clínica"}",
                            style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildMicroCitaTile(Cita cita, Color colorBase, bool esPrimera) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.5, horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: esPrimera ? Colors.deepPurple.shade50 : colorBase.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: esPrimera ? Colors.deepPurple.shade300 : colorBase.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: cita.pagada ? Colors.green.shade600 : Colors.amber.shade800,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          if (esPrimera)
            Text(
              "1ª ",
              style: TextStyle(
                color: Colors.deepPurple.shade900,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          Expanded(
            child: Text(
              cita.nombreClienteCompleto,
              style: TextStyle(
                color: esPrimera ? Colors.deepPurple.shade900 : Colors.black87,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitaTile(Cita cita, AgendaProvider agendaProvider) {
    final Color colorBase = _getColorForEstado(cita.estado);
    final bool esPrimera = cita.esPrimeraVisita || cita.tipoPagoTag == 'PRIMERA_VISITA';

    // En vista mensual evitamos LayoutBuilder y Tooltips pesados para garantizar 60fps durante el swipe
    if (agendaProvider.currentView == CalendarView.month) {
      return _buildMicroCitaTile(cita, colorBase, esPrimera);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 60) {
          return _buildMicroCitaTile(cita, colorBase, esPrimera);
        }

        // ---- TARJETA COMPLETA (Vista diaria o semanal con maxWidth >= 60px) ----
        final bool isCompact = constraints.maxHeight < 40;
        final bool isNarrow = constraints.maxWidth < 130;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: "${cita.nombreClienteCompleto}\n${cita.nombreQuiropractico}\n${cita.pagada ? 'Cubierto / Pagado' : 'Pendiente de cobro (${cita.infoPago})'}",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: colorBase.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: esPrimera ? Colors.deepPurple.shade300 : colorBase.withValues(alpha: 0.35),
                    width: esPrimera ? 1.0 : 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Barra lateral indicadora de estado / primera visita
                    Container(
                      width: esPrimera ? 5.0 : 4.0,
                      decoration: BoxDecoration(
                        color: esPrimera ? Colors.deepPurpleAccent : colorBase,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                    ),

                    // Contenido principal de la tarjeta protegido contra overflow
                    Expanded(
                      child: ClipRect(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: isCompact ? 1 : 2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Fila: Nombre + Badge 1ª Visita + Whatsapp protegidos con Flexible
                                      Row(
                                        children: [
                                          if (esPrimera && !isNarrow) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              margin: const EdgeInsets.only(right: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurple.shade50,
                                                borderRadius: BorderRadius.circular(3),
                                                border: Border.all(color: Colors.deepPurple.shade300, width: 0.8),
                                              ),
                                              child: Text(
                                                "1ª VISITA",
                                                style: TextStyle(
                                                  color: Colors.deepPurple.shade800,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Flexible(
                                            child: Text(
                                              cita.nombreClienteCompleto,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isCompact ? 11 : 12.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          if (!isNarrow && (cita.confirmadaWhatsapp || cita.recordatorioEnviado)) ...[
                                            const SizedBox(width: 4),
                                            WhatsappStatusBadge(cita: cita, showText: false),
                                          ],
                                        ],
                                      ),

                                      // Fila secundaria: Doctor (solo si hay altura suficiente y no es compacto)
                                      if (!isCompact && constraints.maxHeight >= 46) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          cita.nombreQuiropractico.split(' ').first,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 10.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Semáforo Financiero (Icono compacto en esquina derecha)
                              Tooltip(
                                message: cita.pagada
                                    ? "Cubierto / Pagado"
                                    : "Pendiente de cobro (${cita.infoPago})",
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    color: cita.pagada
                                        ? Colors.green.shade50
                                        : Colors.amber.shade50,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cita.pagada
                                          ? Colors.green.shade300
                                          : Colors.amber.shade600,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Icon(
                                    cita.pagada
                                        ? Icons.verified_outlined
                                        : Icons.payments_outlined,
                                    size: isCompact ? 11 : 13,
                                    color: cita.pagada
                                        ? Colors.green.shade700
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDragEnd(
    BuildContext context,
    AppointmentDragEndDetails details,
    AgendaProvider agendaProvider,
    HorariosProvider horariosProvider,
    AgendaBloqueoProvider bloqueosProvider,
    SettingsProvider settingsProvider,
  ) async {
    print('--- INICIO DRAG & DROP ---');
    print('1. Elemento arrastrado tipo: ${details.appointment.runtimeType}');

    final rawAppointment = details.appointment;
    if (rawAppointment is! Cita) {
      print('❌ FALLO: El elemento no es una Cita. Es: $rawAppointment');
      return;
    }

    print('2. Dropping time detectado: ${details.droppingTime}');
    if (details.droppingTime == null) {
      print('❌ FALLO: droppingTime es null. El motor no detectó la celda.');
      return;
    }

    // Rescatar la cita original sin mutaciones visuales de Syncfusion
    final Cita citaOriginal = agendaProvider.citas.firstWhere(
      (c) => c.idCita == rawAppointment.idCita,
      orElse: () => rawAppointment,
    );

    if (citaOriginal.estado == 'cancelada') {
      CustomSnackBar.show(
        context,
        message: 'No se puede reprogramar una cita cancelada.',
        type: SnackBarType.error,
      );
      agendaProvider.restoreLocalView();
      return;
    }

    final Duration duracion = citaOriginal.fechaHoraFin.difference(citaOriginal.fechaHoraInicio);
    final bool isMonthView = agendaProvider.currentView == CalendarView.month;
    print('3. Vista actual es Mes: $isMonthView');

    // ---- BIFURCACIÓN VISTA MENSUAL: DIÁLOGO INTERACTIVO REPROGRAMAR CITA ----
    if (isMonthView) {
      final dropDate = details.droppingTime!;
      int? nuevoIdQuiro;

      final DateTime? nuevaFechaInicio = await showDialog<DateTime>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ReprogramarCitaDialog(
          cita: citaOriginal,
          fechaDestino: dropDate,
          agendaProvider: agendaProvider,
          onDoctorSelected: (doc) {
            nuevoIdQuiro = doc.idUsuario;
          },
        ),
      );

      if (nuevaFechaInicio == null) {
        agendaProvider.restoreLocalView();
        return;
      }

      final DateTime nuevoFin = nuevaFechaInicio.add(duracion);

      // Si soltó en el mismo día y eligió exactamente la misma hora y doctor, abortar
      if (nuevaFechaInicio == citaOriginal.fechaHoraInicio &&
          nuevoFin == citaOriginal.fechaHoraFin &&
          (nuevoIdQuiro == null || nuevoIdQuiro == citaOriginal.idQuiropractico)) {
        agendaProvider.restoreLocalView();
        return;
      }

      if (!context.mounted) return;

      _ejecutarReprogramacion(
        context: context,
        agendaProvider: agendaProvider,
        cita: citaOriginal,
        nuevoInicio: nuevaFechaInicio,
        nuevoFin: nuevoFin,
        nuevoIdQuiro: nuevoIdQuiro,
      );
      return;
    }

    // ---- VISTA DIARIA O SEMANAL: SNAPPING MAGNÉTICO AUTOMÁTICO ----
    final int intervalo = settingsProvider.duracionCitaMinutos;
    final DateTime nuevoInicio = AgendaUtils.roundToNearestInterval(details.droppingTime!, intervalo);
    final DateTime nuevoFin = nuevoInicio.add(duracion);

    if (nuevoInicio == citaOriginal.fechaHoraInicio && nuevoFin == citaOriginal.fechaHoraFin) {
      return;
    }

    // Validar si el día/hora es laborable
    if (!AgendaUtils.isDayWorkable(nuevoInicio, horariosProvider.horariosGlobales) ||
        AgendaUtils.isGlobalBlocked(nuevoInicio, bloqueosProvider.bloqueos)) {
      CustomSnackBar.show(
        context,
        message: 'No es posible mover la cita a un horario cerrado o bloqueado.',
        type: SnackBarType.error,
      );
      agendaProvider.restoreLocalView();
      return;
    }

    _ejecutarReprogramacion(
      context: context,
      agendaProvider: agendaProvider,
      cita: citaOriginal,
      nuevoInicio: nuevoInicio,
      nuevoFin: nuevoFin,
    );
  }

  void _ejecutarReprogramacion({
    required BuildContext context,
    required AgendaProvider agendaProvider,
    required Cita cita,
    required DateTime nuevoInicio,
    required DateTime nuevoFin,
    int? nuevoIdQuiro,
  }) {
    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        final ok = await agendaProvider.reprogramarCitaOptimista(
          cita,
          nuevoInicio,
          nuevoFin,
          nuevoIdQuiro: nuevoIdQuiro,
        );
        if (ok && context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Cita de ${cita.nombreClienteCompleto.split(' ').first} reprogramada a las ${DateFormat('HH:mm').format(nuevoInicio)}',
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          CustomSnackBar.show(
            context,
            message: msg.isNotEmpty ? msg : 'Error al reprogramar la cita',
            type: SnackBarType.error,
          );
        }
      }
    });
  }

  void _handleResizeEnd(
    BuildContext context,
    AppointmentResizeEndDetails details,
    AgendaProvider agendaProvider,
    SettingsProvider settingsProvider,
  ) {
    final rawAppointment = details.appointment;
    if (rawAppointment is! Cita) return;
    if (details.startTime == null || details.endTime == null) return;

    final cita = rawAppointment;
    if (cita.estado == 'cancelada') {
      CustomSnackBar.show(
        context,
        message: 'No se puede redimensionar una cita cancelada.',
        type: SnackBarType.error,
      );
      agendaProvider.restoreLocalView();
      return;
    }

    final int intervalo = settingsProvider.duracionCitaMinutos;
    final DateTime nuevoInicio = AgendaUtils.roundToNearestInterval(details.startTime!, intervalo);
    final DateTime nuevoFin = AgendaUtils.roundToNearestInterval(details.endTime!, intervalo);

    if (!nuevoFin.isAfter(nuevoInicio)) {
      CustomSnackBar.show(
        context,
        message: 'La duración mínima debe ser de $intervalo minutos.',
        type: SnackBarType.error,
      );
      agendaProvider.restoreLocalView();
      return;
    }

    if (nuevoInicio == cita.fechaHoraInicio && nuevoFin == cita.fechaHoraFin) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        final ok = await agendaProvider.reprogramarCitaOptimista(
          cita,
          nuevoInicio,
          nuevoFin,
        );
        if (ok && context.mounted) {
          final duracionMin = nuevoFin.difference(nuevoInicio).inMinutes;
          CustomSnackBar.show(
            context,
            message: 'Duración ajustada a $duracionMin min',
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          CustomSnackBar.show(
            context,
            message: msg.isNotEmpty ? msg : 'Error al redimensionar la cita',
            type: SnackBarType.error,
          );
        }
      }
    });
  }

  void _handleOnTap(
    BuildContext context,
    CalendarTapDetails details,
    AgendaProvider agendaProvider,
    HorariosProvider horariosProvider,
    AgendaBloqueoProvider bloqueosProvider,
  ) {
    if (details.date == null) return;
    final DateTime date = details.date!;

    if (!AgendaUtils.isDayWorkable(date, horariosProvider.horariosGlobales) ||
        AgendaUtils.isGlobalBlocked(date, bloqueosProvider.bloqueos)) {
      return;
    }

    // CASE 1: Cita
    if (details.targetElement == CalendarElement.appointment) {
      if (details.appointments != null && details.appointments!.isNotEmpty) {
        final dynamic rawAppointment = details.appointments![0];

        if (rawAppointment is Cita) {
          showDialog(
            context: context,
            builder: (context) => CitaDetalleModal(cita: rawAppointment),
          ).then((value) {
            if (value == "edit" && context.mounted) {
              showDialog(
                context: context,
                builder: (context) => CitaModal(citaExistente: rawAppointment),
              );
            }
          });
        }
      }
    }
    // CASE 2: Celda vacia
    else if (details.targetElement == CalendarElement.calendarCell) {
      if (agendaProvider.currentView == CalendarView.month) return;
      DateTime f = date;
      if (f.hour == 0 && agendaProvider.currentView == CalendarView.month) {
        f = DateTime(f.year, f.month, f.day, 9, 0);
      }
      
      if (!AgendaUtils.isSlotEnabled(f, agendaProvider.quiropracticos, horariosProvider.horariosGlobales, bloqueosProvider.bloqueos)) {
        CustomSnackBar.show(context, message: "No hay disponibilidad en este horario", type: SnackBarType.info);
        return;
      }

      // Si hay un doctor filtrado, pre-seleccionarlo; si no, buscar el disponible para ese hueco
      final Usuario? preDoc = agendaProvider.filterDoctorId != null
          ? agendaProvider.quiropracticos.firstWhere(
              (q) => q.idUsuario == agendaProvider.filterDoctorId,
              orElse: () => agendaProvider.quiropracticos.first,
            )
          : AgendaUtils.getAvailableDoctor(f, agendaProvider.quiropracticos, horariosProvider.horariosGlobales, bloqueosProvider.bloqueos);

      showDialog(
        context: context,
        builder: (context) => CitaModal(selectedDate: f, preSelectedDoctor: preDoc),
      );
    }
  }
}
