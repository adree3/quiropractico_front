import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    final fechaActual = provider.selectedDate;

    final int diaSemana = fechaActual.weekday;
    final DateTime lunesSemana = fechaActual.subtract(
      Duration(days: diaSemana - 1),
    );
    final hoy = DateTime.now();

    final tituloMes =
        DateFormat('MMMM yyyy', 'es_ES').format(fechaActual).toUpperCase();
    final bool mostrarBotonHoy = !isSameDay(fechaActual, hoy);

    return Column(
      children: [
        // TÍTULO DEL MES Y BOTÓN HOY
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Selector de Fecha Integrado en el Título
              InkWell(
                onTap: () => _abrirPickerNativo(context, provider),
                borderRadius: BorderRadius.circular(10),
                child: Tooltip(
                  message: "Seleccionar fecha",
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tituloMes,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_calendar,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botón "Hoy" integrado al lado si no es hoy
              if (mostrarBotonHoy) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => provider.updateSelectedDate(hoy),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text("Hoy", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ),

        // BOLITAS DE DÍAS (Centradas)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children:
                    horariosProvider.diasActivosSemana.map((diaNum) {
                      final date = lunesSemana.add(Duration(days: diaNum - 1));
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
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // Date picker
  Future<void> _abrirPickerNativo(
    BuildContext context,
    AgendaProvider provider,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: '',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
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

    return GestureDetector(
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
    );
  }
}
