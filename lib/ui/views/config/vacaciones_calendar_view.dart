import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/ui/modals/bloqueo_modal.dart';

class VacacionesCalendarView extends StatefulWidget {
  const VacacionesCalendarView({super.key});

  @override
  State<VacacionesCalendarView> createState() => _VacacionesCalendarViewState();
}

class _VacacionesCalendarViewState extends State<VacacionesCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<BloqueoAgenda> _getBloqueosDelDia(DateTime day, List<BloqueoAgenda> todos) {
    return todos.where((bloqueo) {
      final inicio = DateTime(bloqueo.fechaInicio.year, bloqueo.fechaInicio.month, bloqueo.fechaInicio.day);
      final fin = DateTime(bloqueo.fechaFin.year, bloqueo.fechaFin.month, bloqueo.fechaFin.day);
      final check = DateTime(day.year, day.month, day.day);

      return !check.isBefore(inicio) && !check.isAfter(fin);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaBloqueoProvider>(context);
    final bloqueosDelDiaSeleccionado = _getBloqueosDelDia(_selectedDay!, provider.bloqueos);

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Row(
            children: [
              const Text("Calendario de Ausencias", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showDialog(context: context, builder: (_) => const BloqueoModal()),
                icon: const Icon(Icons.add),
                label: const Text("Nuevo Bloqueo"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // CALENDARIO + LISTA LATERAL 
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CALENDARIO 
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TableCalendar<BloqueoAgenda>(
                        locale: 'es_ES',
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: (day) => _getBloqueosDelDia(day, provider.bloqueos),
                        
                        // CONFIGURACIÓN DE REJILLA
                        rowHeight: 100,
                        daysOfWeekHeight: 40,
                        
                        headerStyle: const HeaderStyle(
                          titleCentered: true, 
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                        ),

                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) => _focusedDay = focusedDay,

                        calendarBuilders: CalendarBuilders(
                          // DÍA POR DEFECTO
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildCell(day, provider.bloqueos, isSelected: false, isToday: false);
                          },
                          // DÍA SELECCIONADO
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildCell(day, provider.bloqueos, isSelected: true, isToday: isSameDay(day, DateTime.now()));
                          },
                          // DÍA DE HOY
                          todayBuilder: (context, day, focusedDay) {
                            return _buildCell(day, provider.bloqueos, isSelected: false, isToday: true);
                          },
                          // DÍAS FUERA DEL MES (GRISES)
                          outsideBuilder: (context, day, focusedDay) {
                            // Ahora usamos la misma celda pero con el flag isOutside
                            return _buildCell(day, provider.bloqueos, isSelected: false, isToday: false, isOutside: true);
                          },
                          markerBuilder: (context, day, events) => const SizedBox(), 
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // DETALLE DEL DÍA SELECCIONADO
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300))
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Detalles",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: bloqueosDelDiaSeleccionado.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade200),
                                    const SizedBox(height: 10),
                                    const Text("Día Operativo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const Text("No hay bloqueos", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(15),
                                itemCount: bloqueosDelDiaSeleccionado.length,
                                separatorBuilder: (_,__) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final bloqueo = bloqueosDelDiaSeleccionado[index];
                                  final isGlobal = bloqueo.idQuiropractico == null;

                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isGlobal ? Colors.red.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isGlobal ? Colors.red.shade200 : Colors.blue.shade200
                                      )
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isGlobal ? Icons.lock : Icons.person_off,
                                          color: isGlobal ? Colors.red : Colors.blue,
                                          size: 20
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                bloqueo.nombreQuiropractico, 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  fontSize: 13,
                                                  color: isGlobal ? Colors.red.shade900 : Colors.blue.shade900
                                                )
                                              ),
                                              Text(bloqueo.motivo, style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          onPressed: () async {
                                            final confirm = await showDialog(
                                              context: context, 
                                              builder: (ctx) => AlertDialog(
                                                title: const Text("Eliminar"),
                                                content: const Text("¿Desbloquear este horario?"),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
                                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sí"))
                                                ],
                                              )
                                            );
                                            if (confirm == true) {
                                              await provider.borrarBloqueo(bloqueo.idBloqueo);
                                            }
                                          }, 
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

// WIDGET PARA CADA CELDA
  Widget _buildCell(DateTime day, List<BloqueoAgenda> todosLosBloqueos, {
    required bool isSelected, 
    required bool isToday, 
    bool isOutside = false // Nuevo parámetro para pintar días grises igual
  }) {
    // 1. Filtrar eventos de este día concreto
    final eventosDelDia = _getBloqueosDelDia(day, todosLosBloqueos);
    
    // 2. Determinar si hay cierre global
    final bool hayCierreGlobal = eventosDelDia.any((e) => e.idQuiropractico == null);
    final int doctoresFuera = eventosDelDia.where((e) => e.idQuiropractico != null).length;

    // 3. Colores
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;

    // Lógica visual para días fuera del mes
    if (isOutside) {
      bgColor = Colors.grey.shade50;
      textColor = Colors.grey.shade400;
    } 
    // Lógica para días normales
    else {
      if (hayCierreGlobal) {
        bgColor = Colors.red.shade50; 
      } else if (isToday) {
        bgColor = Colors.blue.shade50.withOpacity(0.3); 
      }
    }

    if (isSelected) {
      borderColor = AppTheme.primaryColor;
      // Opcional: poner un fondo sutil al seleccionar
      if (!hayCierreGlobal) bgColor = AppTheme.primaryColor.withOpacity(0.05); 
    }

    // --- AQUÍ ESTABA EL ERROR: QUITAMOS GESTURE DETECTOR ---
    return Container(
      margin: const EdgeInsets.all(1), 
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NÚMERO DEL DÍA
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${day.day}', 
                  style: TextStyle(
                    fontWeight: (isToday && !isOutside) ? FontWeight.bold : FontWeight.normal,
                    color: (isToday && !isOutside) ? AppTheme.primaryColor : textColor
                  )
                ),
                if (hayCierreGlobal && !isOutside)
                  const Icon(Icons.lock, size: 12, color: Colors.red)
              ],
            ),
          ),
          
          const Spacer(),

          // INDICADORES (Solo si no es outside para limpiar ruido visual)
          if (eventosDelDia.isNotEmpty && !isOutside)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hayCierreGlobal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3)),
                      child: const Text("CERRADO", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  
                  if (doctoresFuera > 0) ...[
                    if (hayCierreGlobal) const SizedBox(height: 2),
                    Row(
                      children: List.generate(doctoresFuera > 4 ? 4 : doctoresFuera, (index) => 
                        Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        )
                      ),
                    )
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }
}