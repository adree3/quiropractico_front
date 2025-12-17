import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';

import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/horario_modal.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  int _visualizerYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgendaBloqueoProvider>(context, listen: false).loadBloqueos();
      Provider.of<HorariosProvider>(context, listen: false).loadDoctoresActive();
    });
  }

  // Obtiene los meses con bloqueos
  List<int> _getMesesConBloqueos(List<BloqueoAgenda> todosBloqueos, int? idDoctor) {
    final Set<int> mesesActivos = {};
    for (var bloqueo in todosBloqueos) {
      if (bloqueo.fechaInicio.year == _visualizerYear || bloqueo.fechaFin.year == _visualizerYear) {
        bool afectaAlDoctor = (bloqueo.idQuiropractico == null) || (idDoctor != null && bloqueo.idQuiropractico == idDoctor);
        if (afectaAlDoctor) {
          int startMonth = bloqueo.fechaInicio.month;
          int endMonth = bloqueo.fechaFin.month;
          if (bloqueo.fechaInicio.year < _visualizerYear) startMonth = 1;
          if (bloqueo.fechaFin.year > _visualizerYear) endMonth = 12;
          for (int m = startMonth; m <= endMonth; m++) mesesActivos.add(m);
        }
      }
    }
    return mesesActivos.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HorariosProvider>(context);
    final bloqueosProvider = Provider.of<AgendaBloqueoProvider>(context);
    final List<Usuario> doctoresList = provider.doctores; 
    final Usuario? currentDoctor = provider.selectedDoctor;
    final mesesAfectados = _getMesesConBloqueos(bloqueosProvider.bloqueos, currentDoctor?.idUsuario);
    
    return Column(
      children: [
        // Titulo, selector y boton
        Row(
          children: [
            const Expanded(
              child: Text("Horarios", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            
            // Selector del quiropractico
            if (doctoresList.isEmpty)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                 decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
                 child: const Text("Sin quiroprácticos activos", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               )
            else
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Usuario>(
                    value: currentDoctor,
                    hint: const Text("Seleccionar ", style: TextStyle(fontWeight: FontWeight.bold)),
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                    items: doctoresList.map((u) => DropdownMenuItem(
                      value: u, 
                      child: Text(u.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600))
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) provider.selectDoctor(val);
                    },
                  ),
                ),
              ),
              
            const SizedBox(width: 20),
            
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: currentDoctor == null 
                      ? null 
                      : () => showDialog(context: context, builder: (_) => const HorarioModal()),
                  icon: const Icon(Icons.add_alarm),
                  label: const Text("Añadir Turno"),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),

        // Horario y Calendario
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horarios 
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 550,
                      maxHeight: 730
                    ),
                    child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 0, bottom: 40, right: 10), 
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final diaNum = index + 1; 
                        final nombreDia = _getDiaNombre(diaNum);
                        final turnosDelDia = currentDoctor == null 
                          ? [] 
                          : provider.horarios.where((h) => h.diaSemana == diaNum).toList();
                            
                        if (turnosDelDia.isNotEmpty) {
                          turnosDelDia.sort((a, b) => (a.horaInicio.hour * 60 + a.horaInicio.minute).compareTo(b.horaInicio.hour * 60 + b.horaInicio.minute));
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          elevation: 0, 
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column( 
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombreDia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                                const SizedBox(height: 10),
                                if (doctoresList.isEmpty)
                                  const Text("No hay personal activo", style: TextStyle(color: Colors.grey, fontSize: 13))
                                else if (currentDoctor == null)
                                  const Text("Seleccione un doctor para ver horarios", style: TextStyle(color: Colors.orange, fontSize: 13))
                                else if (turnosDelDia.isEmpty) 
                                  const Text("Sin turnos asignados", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
                                else
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: turnosDelDia.map((turno) => Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(turno.formattedRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      backgroundColor: Colors.blue.shade50,
                                      side: BorderSide.none,
                                      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.red),
                                      onDeleted: () async => await provider.deleteHorario(turno.idHorario),
                                    )).toList(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ),

              const SizedBox(width: 20),

              // Calendario
              Expanded(
                flex: 1, 
                child: Align(
                  alignment: Alignment.topCenter, 
                  
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                      maxHeight: 730,
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Afectaciones $_visualizerYear", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _visualizerYear--)),
                                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _visualizerYear++)),
                                  ],
                                )
                              ],
                            ),
                            const Divider(),
                            Row(
                              children: [
                                _buildLegendItem(Colors.red.shade100, "Clínica Cerrada"),
                                const SizedBox(width: 15),
                                if (currentDoctor != null)
                                  _buildLegendItem(Colors.blue.shade100, "Vacaciones ${currentDoctor.nombreCompleto.split(' ')[0]}"),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // GRID
                            Expanded(
                              child: mesesAfectados.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(30.0),
                                      child: Text("Sin bloqueos este año", style: TextStyle(color: Colors.grey)),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final double width = constraints.maxWidth;
                                        final int columnas = width < 100 ? 1 : 2;

                                        return GridView.builder(
                                          shrinkWrap: true,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columnas,
                                            mainAxisExtent: 210, 
                                            crossAxisSpacing: 15,
                                            mainAxisSpacing: 15,
                                          ),
                                          itemCount: mesesAfectados.length,
                                          itemBuilder: (context, index) {
                                            return _buildMonthMiniature(mesesAfectados[index], _visualizerYear, bloqueosProvider.bloqueos, currentDoctor?.idUsuario);
                                          },
                                        );
                                      },
                                    ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // Optener el nombre del dia
  String _getDiaNombre(int dia) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[dia - 1];
  }

  // Para la leyenda
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // Para contruir cada mes
  Widget _buildMonthMiniature(int month, int year, List<BloqueoAgenda> bloqueos, int? selectedDoctorId) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDay = DateTime(year, month, 1);
    final offset = firstDay.weekday - 1; 

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8)
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(DateFormat('MMMM', 'es_ES').format(firstDay).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['L','M','X','J','V','S','D'].map((d) => 
              Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))))
            ).toList(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: daysInMonth + offset,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox(); 
                
                final dayNum = index - offset + 1;
                final currentDate = DateTime(year, month, dayNum);
                
                Color? cellColor;
                bool isGlobal = false;
                
                final bloqueosDia = bloqueos.where((b) {
                  final inicio = DateTime(b.fechaInicio.year, b.fechaInicio.month, b.fechaInicio.day);
                  final fin = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
                  return !currentDate.isBefore(inicio) && !currentDate.isAfter(fin);
                }).toList();

                if (bloqueosDia.isNotEmpty) {
                  if (bloqueosDia.any((b) => b.idQuiropractico == null)) {
                    cellColor = Colors.red.shade100;
                    isGlobal = true;
                  } else if (selectedDoctorId != null && bloqueosDia.any((b) => b.idQuiropractico == selectedDoctorId)) {
                    cellColor = Colors.blue.shade100;
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(2)),
                  child: Center(
                    child: Text(
                      "$dayNum", 
                      style: TextStyle(
                        fontSize: 9, 
                        color: isGlobal ? Colors.red.shade900 : Colors.black87, 
                        fontWeight: cellColor != null ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}