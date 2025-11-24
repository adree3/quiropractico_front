import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaView extends StatelessWidget {
  const AgendaView({super.key});

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agenda Diaria', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: Card(
            child: SfCalendar(
              view: CalendarView.day,
              
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 8,
                endHour: 21,
                timeInterval: Duration(minutes: 30),
                timeIntervalHeight: 60, // Altura de cada hora (más espacio para leer)
                timeFormat: 'HH:mm',
                timeRulerSize: 70
              ),
              
              // Datos
              dataSource: CitaDataSource(agendaProvider.citas),
              
              // Eventos
              onViewChanged: (ViewChangedDetails details) {
                // Aquí podríamos recargar datos si el usuario cambia de día
                // Por simplicidad, ahora carga HOY al inicio.
              },
              
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
                    } else {
                      print("ERROR: El objeto recibido no es de tipo Cita");
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
        ),
      ],
    );
  }
}