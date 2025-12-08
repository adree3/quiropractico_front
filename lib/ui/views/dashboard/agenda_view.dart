import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view_datasource.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_header.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/agenda_side_panel.dart'; 
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final CalendarController _calendarController = CalendarController();
  bool _esTurnoManana = true;

  @override
  void initState() {
    super.initState();
    if (DateTime.now().hour >= 15) {
      _esTurnoManana = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    
    // Sincronización
    if (_calendarController.displayDate != agendaProvider.selectedDate) {
      _calendarController.displayDate = agendaProvider.selectedDate;
    }

    return LayoutBuilder(
      builder: (context, constraits){
        final bool showSidePanel = constraits.maxWidth > 1200;
        return Column( 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agenda Diaria', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                
                Row(
                  children: [
                    // SELECTOR DE TURNO
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!)
                      ),
                      child: Row(
                        children: [
                          _TurnoButton(
                            label: "Mañana (09-14)",
                            icon: Icons.wb_sunny_outlined,
                            isSelected: _esTurnoManana,
                            onTap: () => setState(() => _esTurnoManana = true),
                          ),
                          const SizedBox(width: 5),
                          _TurnoButton(
                            label: "Tarde (16-21)",
                            icon: Icons.nights_stay_outlined,
                            isSelected: !_esTurnoManana,
                            onTap: () => setState(() => _esTurnoManana = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!showSidePanel) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              content: SizedBox(
                                width: 350,
                                height: 600,
                                child: Stack(
                                  children: [
                                    const ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                                      child: const AgendaSidePanel()
                                    ),
                                    
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton.filled(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.close, size: 18),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.grey[200], 
                                          foregroundColor: Colors.black54
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text("Resumen"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                      
                    ],
                  ],
                )
              ],
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        children: [
                          const AgendaHeader(),
                          
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                              child: SfCalendar(
                                controller: _calendarController,
                                view: CalendarView.day,
                                headerHeight: 0,
                                viewHeaderHeight: 0,
                                
                                timeSlotViewSettings: TimeSlotViewSettings(
                                  startHour: _esTurnoManana ? 8.5 : 15.5, 
                                  endHour: _esTurnoManana ? 14 : 21,
                                  timeInterval: const Duration(minutes: 30),
                                  timeIntervalHeight: 80,
                                  timeFormat: 'HH:mm',
                                  timeRulerSize: 60,
                                ),
                                
                                dataSource: CitaDataSource(agendaProvider.citas),
                                
                                appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                                  final Cita cita = details.appointments.first;
                                  Color colorBase;
                                  switch (cita.estado) {
                                    case 'completada': colorBase = Colors.green; break;
                                    case 'cancelada': colorBase = Colors.red; break;
                                    case 'ausente': colorBase = Colors.grey; break;
                                    default: colorBase = const Color(0xFF00AEEF);
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: colorBase.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border(left: BorderSide(color: colorBase, width: 4)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(cita.nombreClienteCompleto, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: colorBase, borderRadius: BorderRadius.circular(4)),
                                              child: Text(cita.estado.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Dr. ${cita.nombreQuiropractico.split(' ').first}", style: const TextStyle(color: Colors.black54, fontSize: 11)),
                                      ],
                                    ),
                                  );
                                },
        
                                onTap: (CalendarTapDetails details) {
                                  if (details.targetElement == CalendarElement.appointment || 
                                      details.targetElement == CalendarElement.calendarCell) {
                                    if (details.appointments != null && details.appointments!.isNotEmpty) {
                                      final dynamic rawAppointment = details.appointments![0];
                                      if (rawAppointment is Cita) {
                                        showDialog(context: context, builder: (context) => CitaDetalleModal(cita: rawAppointment));
                                      }
                                    } else {
                                      final fechaSeleccionada = details.date!;
                                      showDialog(context: context, builder: (context) => CitaModal(selectedDate: fechaSeleccionada));
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
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
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
                  ]
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
// Widget para los botones de Turno
class _TurnoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TurnoButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13
              ),
            ),
          ],
        ),
      ),
    );
  }
}