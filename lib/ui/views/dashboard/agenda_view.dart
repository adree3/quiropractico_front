import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/ui_provider.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/stomp_service.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_utils.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
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
  late final AgendaDataSource _dataSource;
  late final AgendaProvider _agendaProvider;
  late final AgendaBloqueoProvider _bloqueosProvider;
  late final HorariosProvider _horariosProvider;
  VoidCallback? _unsubscribeAgendaWs;
  int _lastExternalNavigationTick = -1;

  CalendarView _currentView = CalendarView.day;
  List<TimeRegion> _cachedSpecialRegions = [];
  DateTime? _cachedRegionsFocusDate;
  int? _cachedFilterDoctorId;
  CalendarView? _cachedView;
  bool _initialWorkDayChecked = false;

  @override
  void initState() {
    super.initState();
    _dataSource = AgendaDataSource([], [], DateTime.now());

    _agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    _bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context, listen: false);
    _horariosProvider = Provider.of<HorariosProvider>(context, listen: false);

    _currentView = _agendaProvider.currentView;

    _agendaProvider.addListener(_onAgendaProviderChanged);
    _bloqueosProvider.addListener(_onBloqueosChanged);
    _horariosProvider.addListener(_onHorariosChanged);

    // Suscripción en tiempo real a eventos STOMP (/topic/agenda)
    _unsubscribeAgendaWs = StompService.instance.subscribeToAgenda(_onAgendaWsEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bloqueosProvider.loadBloqueos();
      _horariosProvider.loadAllHorariosGlobales();
      _agendaProvider.loadQuiropracticos();
      _agendaProvider.refreshCurrentView();

      if (widget.initialDate != null) {
        _agendaProvider.updateSelectedDate(widget.initialDate!);
        _calendarController.displayDate = widget.initialDate;
      } else {
        _calendarController.displayDate = DateTime.now();
      }

      _checkInitialWorkDay();
      _updateSpecialRegions(force: true);
      _syncDataSource();
    });
  }

  @override
  void dispose() {
    _unsubscribeAgendaWs?.call();
    _agendaProvider.removeListener(_onAgendaProviderChanged);
    _bloqueosProvider.removeListener(_onBloqueosChanged);
    _horariosProvider.removeListener(_onHorariosChanged);
    _calendarController.dispose();
    super.dispose();
  }

  void _onAgendaWsEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final String? action = (event['action'] ?? event['tipo'])?.toString().toUpperCase();
    if (action == null) return;

    if (action == 'CREATE' ||
        action == 'UPDATE' ||
        action == 'CITA_CREADA' ||
        action == 'CITA_ACTUALIZADA' ||
        action == 'CITA_FIRMADA') {
      final dynamic rawData = event['data'] ?? event['cita'] ?? event;
      if (rawData is Map<String, dynamic> && rawData.containsKey('fechaHoraInicio')) {
        _agendaProvider.upsertCitaLocal(Cita.fromJson(rawData));
      }
    } else if (action == 'DELETE' || action == 'CITA_ELIMINADA') {
      final dynamic rawId = event['idCita'] ??
          event['id'] ??
          (event['data'] is Map ? (event['data']['idCita'] ?? event['data']['id']) : event['data']);
      final int? idCita = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      if (idCita != null) {
        _agendaProvider.deleteCitaLocal(idCita);
      }
    }
  }

  void _syncDataSource() {
    final citasFiltradas = _agendaProvider.filterDoctorId == null
        ? _agendaProvider.citas
        : _agendaProvider.citas
            .where((c) => c.idQuiropractico == _agendaProvider.filterDoctorId)
            .toList();

    final bloqueosFiltrados = _bloqueosProvider.bloqueos.where((b) {
      if (b.idQuiropractico == null) return true;
      if (_agendaProvider.filterDoctorId == null) return true;
      return b.idQuiropractico == _agendaProvider.filterDoctorId;
    }).toList();

    _dataSource.updateAppointments(
      citasFiltradas,
      bloqueosFiltrados,
      _agendaProvider.selectedDate,
      notify: true,
    );
  }

  void _onAgendaProviderChanged() {
    if (!mounted) return;

    // 1. Cambio de vista (Día / Semana / Mes): actualizar controlador y vista
    if (_currentView != _agendaProvider.currentView) {
      _currentView = _agendaProvider.currentView;
      CalendarView targetView = _currentView;
      if (targetView == CalendarView.week) targetView = CalendarView.workWeek;
      if (_calendarController.view != targetView) {
        _calendarController.view = targetView;
      }
      _updateSpecialRegions(force: true);
      if (mounted) setState(() {});
      return;
    }

    // 2. Navegación externa directa (picker de fecha o botón hoy)
    if (_lastExternalNavigationTick != _agendaProvider.externalNavigationTick) {
      _lastExternalNavigationTick = _agendaProvider.externalNavigationTick;
      if (_calendarController.displayDate == null ||
          !DateUtils.isSameDay(_calendarController.displayDate, _agendaProvider.selectedDate)) {
        _calendarController.displayDate = _agendaProvider.selectedDate;
      }
    }

    _updateSpecialRegions();

    // 3. Sincronización in-place de appointments (NUNCA causa rebuild del widget tree)
    _syncDataSource();
  }

  void _checkInitialWorkDay() {
    if (_initialWorkDayChecked) return;
    if (_horariosProvider.horariosGlobales.isEmpty) return;

    final currentDate = _agendaProvider.selectedDate;
    final bool esValido = AgendaUtils.isDateWorkable(
      currentDate,
      _horariosProvider.horariosGlobales,
      _bloqueosProvider.bloqueos,
      idQuiropratico: _agendaProvider.filterDoctorId,
    );

    if (!esValido) {
      _initialWorkDayChecked = true;
      final proximoDia = AgendaUtils.findNextWorkDay(
        currentDate,
        _horariosProvider.horariosGlobales,
        _bloqueosProvider.bloqueos,
        forward: true,
        idQuiropratico: _agendaProvider.filterDoctorId,
      );
      _calendarController.displayDate = proximoDia;
      _agendaProvider.updateSelectedDate(proximoDia);
    } else {
      _initialWorkDayChecked = true;
    }
  }

  void _onBloqueosChanged() {
    if (!mounted) return;
    _checkInitialWorkDay();
    _updateSpecialRegions(force: true);
    _syncDataSource();
  }

  void _onHorariosChanged() {
    if (!mounted) return;
    _checkInitialWorkDay();
    _updateSpecialRegions(force: true);
    if (mounted) setState(() {});
  }

  void _updateSpecialRegions({bool force = false}) {
    final currentDate = _agendaProvider.selectedDate;
    final filterDoctorId = _agendaProvider.filterDoctorId;
    final currentView = _agendaProvider.currentView;

    // Cache masivo de 3 semanas (±21 días) para evitar cualquier cálculo durante swipe
    if (!force &&
        _cachedRegionsFocusDate != null &&
        _cachedFilterDoctorId == filterDoctorId &&
        _cachedView == currentView &&
        currentDate.difference(_cachedRegionsFocusDate!).inDays.abs() < 21) {
      return;
    }

    _cachedRegionsFocusDate = currentDate;
    _cachedFilterDoctorId = filterDoctorId;
    _cachedView = currentView;

    _cachedSpecialRegions = AgendaUtils.getDisabledRegions(
      focusDate: currentDate,
      currentView: currentView,
      selectedQuiropraticoId: filterDoctorId,
      doctores: _agendaProvider.quiropracticos,
      horariosGlobales: _horariosProvider.horariosGlobales,
      bloqueos: _bloqueosProvider.bloqueos,
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UiProvider>(context);

    CalendarView calendarView = _currentView;
    if (calendarView == CalendarView.week) {
      calendarView = CalendarView.workWeek;
    }

    final boundaries = AgendaUtils.calculateHourBoundaries(
      _horariosProvider.horariosGlobales,
      calendarView == CalendarView.day ? [_agendaProvider.selectedDate] : null,
    );
    final minHour = boundaries['min']!;
    final maxHour = boundaries['max']!;

    final workingDays = _horariosProvider.diasActivosSemana.toSet();
    final nonWorkingDays = <int>[
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Selector<AgendaProvider, CalendarView>(
                selector: (_, p) => p.currentView,
                builder: (context, view, _) {
                  return _buildHeader(context, _getTituloAgenda(view), constraints.maxWidth);
                },
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
                              padding: EdgeInsets.only(
                                right: !isDesktop && uiProvider.isAgendaSidePanelCollapsed ? 100 : 0,
                              ),
                              child: _buildCalendarContainer(
                                calendarView: calendarView,
                                disabledRegions: _cachedSpecialRegions,
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
            color: Colors.black.withValues(alpha: 0.05),
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
              final DateTime? fechaParaCita = agenda.currentView == CalendarView.day
                  ? agenda.selectedDate
                  : null;
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
              );
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AgendaHeader(calendarController: _calendarController),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: AgendaCalendar(
                key: const ValueKey('agenda_calendar'),
                controller: _calendarController,
                view: calendarView,
                specialRegions: disabledRegions,
                nonWorkingDays: nonWorkingDays,
                minHour: minHour,
                maxHour: maxHour,
                dataSource: _dataSource,
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
                  color: Colors.black.withValues(alpha: 0.05),
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
              color: Colors.black.withValues(alpha: 0.1),
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
