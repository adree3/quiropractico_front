import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/ui_provider.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_utils.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_calendar.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_header.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_side_panel.dart';
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
      // Carga inicial de citas para el día/vista actual
      agendaProvider.refreshCurrentView();

      if (widget.initialDate != null) {
        agendaProvider.updateSelectedDate(widget.initialDate!);

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _calendarController.view == CalendarView.day) {
            _calendarController.displayDate = widget.initialDate;
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _calendarController.view == CalendarView.day) {
            _calendarController.displayDate = DateTime.now();
          }
        });
      }
    });
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

    final disabledRegions = AgendaUtils.getDisabledRegions(
      focusDate: agendaProvider.selectedDate,
      currentView: agendaProvider.currentView,
      selectedQuiropraticoId: agendaProvider.filterDoctorId,
      doctores: agendaProvider.quiropracticos,
      horariosGlobales: horariosProvider.horariosGlobales,
      bloqueos: bloqueosProvider.bloqueos,
    );

    // Calculamos las fechas visibles para determinar los límites de horas
    List<DateTime> visibleDates = [];
    if (agendaProvider.currentView == CalendarView.day) {
      visibleDates = [agendaProvider.selectedDate];
    } else {
      final monday = agendaProvider.selectedDate.subtract(
        Duration(days: agendaProvider.selectedDate.weekday - 1),
      );
      visibleDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    }

    final boundaries = AgendaUtils.calculateHourBoundaries(
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

          String tituloAgenda = _getTituloAgenda(agendaProvider.currentView);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, tituloAgenda, constraints.maxWidth),
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
                              padding: EdgeInsets.only(
                                right:
                                    !isDesktop &&
                                            uiProvider
                                                .isAgendaSidePanelCollapsed
                                        ? 100
                                        : 0,
                              ),
                              child: _buildCalendarContainer(
                                calendarView: calendarView,
                                disabledRegions: disabledRegions,
                                nonWorkingDays: nonWorkingDays,
                                minHour: minHour,
                                maxHour: maxHour,
                              ),
                            ),
                          ),

                          if (isDesktop) _buildSidePanel(uiProvider, true),
                        ],
                      ),
                    ),
                    if (!isDesktop) _buildSidePanel(uiProvider, false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getTituloAgenda(CalendarView view) {
    if (view == CalendarView.week) return "Agenda Semanal";
    if (view == CalendarView.month) return "Agenda Mensual";
    return "Agenda Diaria";
  }

  Widget _buildHeader(BuildContext context, String titulo, double maxWidth) {
    return Container(
      width: maxWidth,
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
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
              final agenda = Provider.of<AgendaProvider>(context, listen: false);
              // En vista diaria: pre-seleccionar la fecha visible
              final DateTime? fechaParaCita = agenda.currentView == CalendarView.day
                  ? agenda.selectedDate
                  : null;
              // Pre-seleccionar doctor activo si hay filtro
              final Usuario? doctorParaCita = agenda.filterDoctorId != null
                  ? agenda.quiropracticos.firstWhere(
                      (q) => q.idUsuario == agenda.filterDoctorId,
                      orElse: () => agenda.quiropracticos.first,
                    )
                  : null;
              showDialog(
                context: context,
                builder: (context) => CitaModal(
                  selectedDate: fechaParaCita,
                  preSelectedDoctor: doctorParaCita,
                ),
              ).then((val) {
                if (val == true) agenda.refreshCurrentView();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContainer({
    required CalendarView calendarView,
    required List<TimeRegion> disabledRegions,
    required List<int> nonWorkingDays,
    required double minHour,
    required double maxHour,
  }) {
    return Container(
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
              child: AgendaCalendar(
                controller: _calendarController,
                view: calendarView,
                specialRegions: disabledRegions,
                nonWorkingDays: nonWorkingDays,
                minHour: minHour,
                maxHour: maxHour,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(UiProvider uiProvider, bool isDesktop) {
    final content = AgendaSidePanel(
      isCollapsed: uiProvider.isAgendaSidePanelCollapsed,
      onToggle: () => uiProvider.toggleAgendaSidePanel(),
    );

    if (isDesktop) {
      return Row(
        children: [
          const SizedBox(width: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: uiProvider.isAgendaSidePanelCollapsed ? 80 : 320,
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
              child: content,
            ),
          ),
        ],
      );
    }

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        width: uiProvider.isAgendaSidePanelCollapsed ? 80 : 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 1.0),
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
          child: content,
        ),
      ),
    );
  }

}
