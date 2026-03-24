import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/ui/widgets/fecha_picker_dialog.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:quiropractico_front/ui/widgets/user_avatar_widget.dart';

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(context);
    final fechaActual = provider.selectedDate;

    final int diaSemana = fechaActual.weekday;
    final DateTime lunesSemana = fechaActual.subtract(
      Duration(days: diaSemana - 1),
    );
    final hoy = DateTime.now();

    final tituloMes =
        DateFormat('MMMM yyyy', 'es_ES').format(fechaActual).toUpperCase();
    
    bool mostrarBotonHoy = false;
    if (provider.currentView == CalendarView.day) {
      mostrarBotonHoy = !isSameDay(fechaActual, hoy);
    } else if (provider.currentView == CalendarView.month) {
      mostrarBotonHoy = fechaActual.year != hoy.year || fechaActual.month != hoy.month;
    } else {
      // Semana o WorkWeek
      final DateTime lunesHoy = hoy.subtract(Duration(days: hoy.weekday - 1));
      mostrarBotonHoy = !isSameDay(DateTime(lunesSemana.year, lunesSemana.month, lunesSemana.day), 
                                   DateTime(lunesHoy.year, lunesHoy.month, lunesHoy.day));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // IZQUIERDA: Selector de Vistas
              Tooltip(
                message: "Cambiar vista de agenda",
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CalendarView>(
                      value: provider.currentView,
                      icon: const Icon(Icons.expand_more, size: 20, color: AppTheme.primaryColor),
                      style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                      onChanged: (v) => v != null ? provider.setCurrentView(v) : null,
                      items: const [
                        DropdownMenuItem(
                          value: CalendarView.day,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_view_day, size: 18, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text("Diaria"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: CalendarView.week,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_view_week, size: 18, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text("Semanal"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: CalendarView.month,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text("Mensual"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CENTRO: Título y Botón Hoy
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: "Seleccionar fecha específica",
                      child: InkWell(
                        onTap: () => _abrirPickerPersonalizado(
                          context,
                          provider,
                          horariosProvider,
                          bloqueoProvider,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tituloMes,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit_calendar_outlined, size: 20, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (mostrarBotonHoy) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => provider.updateSelectedDate(hoy),
                        icon: const Icon(Icons.today, size: 20),
                        tooltip: "Volver a hoy",
                        color: Colors.grey[600],
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // DERECHA: Selector de Quiroprácticos (Premium)
              Tooltip(
                message: "Filtrar por quiropráctico",
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: provider.filterDoctorId,
                      icon: const Icon(Icons.person_search_outlined, size: 20, color: AppTheme.primaryColor),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      onChanged: (id) => provider.setFilterDoctorId(id),
                      selectedItemBuilder: (context) {
                        return [
                          const Center(child: Text("Todos", style: TextStyle(fontWeight: FontWeight.bold))),
                          ...provider.quiropracticos.map((doc) {
                            return Center(
                              child: Row(
                                children: [
                                  UserAvatarWidget(
                                    usuario: doc,
                                    radius: 12,
                                    fontSize: 11,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    doc.nombreCompleto.split(' ').first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ];
                      },
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 18),
                              SizedBox(width: 8),
                              Text("Todos"),
                            ],
                          ),
                        ),
                        ...provider.quiropracticos.map((doc) => DropdownMenuItem(
                          value: doc.idUsuario,
                          child: Row(
                            children: [
                              UserAvatarWidget(
                                usuario: doc,
                                radius: 12,
                                fontSize: 12,
                              ),
                              const SizedBox(width: 10),
                              Text(doc.nombreCompleto),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // BOLITAS DE DÍAS (Solo en vista diaria)
        if (provider.currentView == CalendarView.day)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        provider.updateSelectedDate(
                          fechaActual.subtract(const Duration(days: 7)),
                        );
                      },
                      tooltip: 'Semana Anterior',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children:
                          horariosProvider.diasActivosSemana.map((diaNum) {
                            final date = lunesSemana.add(
                              Duration(days: diaNum - 1),
                            );
                            final isSelected = isSameDay(date, fechaActual);
                            final esHoy = isSameDay(date, hoy);

                            return _DayCircle(
                              date: date,
                              isSelected: isSelected,
                              isToday: esHoy,
                              onTap: () => provider.updateSelectedDate(date),
                            );
                          }).toList(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        provider.updateSelectedDate(
                          fechaActual.add(const Duration(days: 7)),
                        );
                      },
                      tooltip: 'Semana Siguiente',
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (provider.currentView == CalendarView.day)
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // Date picker personalizado
  Future<void> _abrirPickerPersonalizado(
    BuildContext context,
    AgendaProvider provider,
    HorariosProvider horariosProvider,
    AgendaBloqueoProvider bloqueoProvider,
  ) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => FechaPickerDialog(
        initialDate: provider.selectedDate,
        colorTema: AppTheme.primaryColor,
        diasActivosSemana: horariosProvider.diasActivosSemana,
        bloqueos: bloqueoProvider.bloqueos,
        idQuiroSeleccionado: provider.filterDoctorId,
      ),
    );

    if (picked != null && picked != provider.selectedDate) {
      provider.updateSelectedDate(picked);
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Widget bolita
class _DayCircle extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCircle({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat(
      'E',
      'es_ES',
    ).format(date).toUpperCase().replaceAll('.', '');
    final dayNumber = date.day.toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            shape: BoxShape.circle,
            border:
                isSelected
                    ? null
                    : Border.all(
                      color: isToday ? AppTheme.primaryColor : Colors.grey[300]!,
                    ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : [],
          ),
          child:
              isToday
                  // Solo texto centrado
                  ? Center(
                    child: Text(
                      "HOY",
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                  // Día + Número
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
