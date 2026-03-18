import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_utils.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';

class AgendaCalendar extends StatelessWidget {
  final CalendarController controller;
  final CalendarView view;
  final List<TimeRegion> specialRegions;
  final List<int> nonWorkingDays;
  final double minHour;
  final double maxHour;

  const AgendaCalendar({
    super.key,
    required this.controller,
    required this.view,
    required this.specialRegions,
    required this.nonWorkingDays,
    required this.minHour,
    required this.maxHour,
  });

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);

    return SfCalendar(
      controller: controller,
      view: view,
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
      onViewChanged: (ViewChangedDetails details) {
        if (details.visibleDates.isNotEmpty) {
          final nuevaFechaVisible = details.visibleDates.first;

          // Sincronizar selectedDate si ha cambiado el día base
          if (!DateUtils.isSameDay(
            nuevaFechaVisible,
            agendaProvider.selectedDate,
          )) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              agendaProvider.updateSelectedDate(nuevaFechaVisible);
            });
          }

          // Carga de datos por rango si estamos en Semana o Mes
          if (agendaProvider.currentView != CalendarView.day) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              agendaProvider.getCitasPorRango(
                details.visibleDates.first,
                details.visibleDates.last,
              );
            });
          }
        }
      },
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: minHour,
        endHour: maxHour,
        nonWorkingDays: nonWorkingDays,
        timeInterval: const Duration(minutes: 30),
        timeIntervalHeight: 80,
        timeFormat: 'HH:mm',
        timeRulerSize: 60,
      ),
      dataSource: AgendaDataSource(
        // Filtrado local de citas por doctor para garantizar coherencia visual
        agendaProvider.filterDoctorId == null
            ? agendaProvider.citas
            : agendaProvider.citas
                .where((c) => c.idQuiropractico == agendaProvider.filterDoctorId)
                .toList(),
        // Bloqueos: globales siempre; de doctor específico solo si coincide
        bloqueosProvider.bloqueos.where((b) {
          if (b.idQuiropractico == null) return true;
          if (agendaProvider.filterDoctorId == null) return true;
          return b.idQuiropractico == agendaProvider.filterDoctorId;
        }).toList(),
        agendaProvider.selectedDate,
      ),
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
    final isWorkDay = AgendaUtils.isDayWorkable(date, horariosProvider.horariosGlobales);
    final isGlobalBlocked = AgendaUtils.isGlobalBlocked(date, bloqueosProvider.bloqueos);
    final bool isToday = DateUtils.isSameDay(date, DateTime.now());
    final count = agendaProvider.citas
        .where((a) =>
          DateUtils.isSameDay(a.fechaHoraInicio, date) &&
          (agendaProvider.filterDoctorId == null ||
           a.idQuiropractico == agendaProvider.filterDoctorId))
        .length;

    Color? bgColor;
    if (!isWorkDay) {
      bgColor = Colors.grey.shade100;
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
                        }
                      : null,
                  hoverColor: Colors.blue.withOpacity(0.1),
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

    // ---- MENSUAL ----
    if (agendaProvider.currentView == CalendarView.month) {
      if (rawAppointment is Cita) {
        final cita = rawAppointment;
        Color colorBase = _getColorForEstado(cita.estado);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 0.5, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
          decoration: BoxDecoration(
            color: colorBase.withOpacity(0.12),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: colorBase,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cita.nombreClienteCompleto,
                  style: TextStyle(
                    color: colorBase.withAlpha(200),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // ---- DIA / SEMANA BLOQUEO ----
    if (rawAppointment is BloqueoAgenda) {
      return _buildBloqueoTile(rawAppointment);
    }

    // ---- DIA / SEMANA CITA ----
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
              color: Colors.orange.shade50.withOpacity(0.9),
              border: Border.all(color: Colors.orange.shade200, width: 1.0),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15, bottom: -15,
                  child: Icon(Icons.block, size: 80, color: Colors.orange.shade200.withOpacity(0.4)),
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

  Widget _buildCitaTile(Cita cita, AgendaProvider agendaProvider) {
    Color colorBase = _getColorForEstado(cita.estado);
    IconData iconBase;
    switch (cita.estado) {
      case 'completada': iconBase = Icons.check_circle_rounded; break;
      case 'cancelada': iconBase = Icons.cancel_rounded; break;
      case 'ausente': iconBase = Icons.person_off_rounded; break;
      default: iconBase = Icons.calendar_month_rounded;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: "Ver detalles",
        child: Container(
          decoration: BoxDecoration(
            color: colorBase.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colorBase.withOpacity(0.3), width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: colorBase),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cita.nombreClienteCompleto,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cita.nombreQuiropractico.split(' ').first,
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (agendaProvider.currentView == CalendarView.day)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: colorBase.withOpacity(0.15), shape: BoxShape.circle),
                          child: Icon(iconBase, color: colorBase, size: 22),
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

  void _handleOnTap(
    BuildContext context,
    CalendarTapDetails details,
    AgendaProvider agendaProvider,
    HorariosProvider horariosProvider,
    AgendaBloqueoProvider bloqueosProvider,
  ) {
    if (details.targetElement == null) return;
    final date = details.date!;

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
            if (value == "edit") {
              showDialog(
                context: context,
                builder: (context) => CitaModal(citaExistente: rawAppointment),
              ).then((valEdit) {
                if (valEdit == true) agendaProvider.refreshCurrentView();
              });
            } else if (value == true) {
              agendaProvider.refreshCurrentView();
            }
          });
        }
      }
    }
    // CASE 2: Celda vacia
    else if (details.targetElement == CalendarElement.calendarCell) {
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
      ).then((value) {
        if (value == true) agendaProvider.refreshCurrentView();
      });
    }
  }
}
