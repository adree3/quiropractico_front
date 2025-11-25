import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_header.dart'; 
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    
    // Sincronización
    if (_calendarController.displayDate != agendaProvider.selectedDate) {
      _calendarController.displayDate = agendaProvider.selectedDate;
    }

    return Stack(
      children: [        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agenda Diaria', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  children: [
                    const AgendaHeader(),
                    Expanded(
                      child: SfCalendar(
                        controller: _calendarController,
                        view: CalendarView.day,
                        headerHeight: 0,
                        viewHeaderHeight: 0,
                        
                        timeSlotViewSettings: const TimeSlotViewSettings(
                          startHour: 8,
                          endHour: 21,
                          timeInterval: Duration(minutes: 30),
                          timeIntervalHeight: 60,
                          timeFormat: 'HH:mm',
                          timeRulerSize: 60,
                        ),
                        
                        dataSource: CitaDataSource(agendaProvider.citas),
                        
                        onTap: (CalendarTapDetails details) {
                          if (details.targetElement == CalendarElement.appointment || 
                              details.targetElement == CalendarElement.calendarCell) {
                            if (details.appointments != null && details.appointments!.isNotEmpty) {
                              final dynamic rawAppointment = details.appointments![0];
                              if (rawAppointment is Cita) {
                                showDialog(
                                  context: context,
                                  builder: (context) => CitaDetalleModal(cita: rawAppointment),
                                );
                              }
                            } else {
                              final fechaSeleccionada = details.date!;
                              showDialog(
                                context: context,
                                builder: (context) => CitaModal(selectedDate: fechaSeleccionada),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}