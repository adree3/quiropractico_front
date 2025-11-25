import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context);
    final fechaActual = provider.selectedDate;

    final int diaSemana = fechaActual.weekday;
    final DateTime lunesSemana = fechaActual.subtract(Duration(days: diaSemana - 1));
    final hoy = DateTime.now();

    final tituloMes = DateFormat('MMMM yyyy', 'es_ES').format(fechaActual).toUpperCase();
    const double buttonHeight = 42.0;

    return Column(
      children: [
        // TÍTULO DEL MES
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 5),
          child: Text(
            tituloMes, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.primaryColor,
              letterSpacing: 1.5
            )
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cita
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      final horaInicio = DateTime(fechaActual.year, fechaActual.month, fechaActual.day, now.hour + 1, 0);
                      showDialog(
                        context: context,
                        builder: (context) => CitaModal(selectedDate: horaInicio),
                      );
                    },
                    label: const Text("+ Cita"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      fixedSize: const Size.fromHeight(buttonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ),

              // BOLITAS DE DÍAS
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final date = lunesSemana.add(Duration(days: index));
                    final isSelected = isSameDay(date, fechaActual);
                    final esHoy = isSameDay(date, hoy);

                    return _DayCircle(
                      date: date,
                      isSelected: isSelected,
                      isToday: esHoy,
                      onTap: () => provider.updateSelectedDate(date),
                    );
                  }),
                ),
              ),

              // CALENDARIO
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filledTonal(
                    onPressed: () => _abrirPickerNativo(context, provider),
                    icon: const Icon(Icons.calendar_month_outlined),
                    iconSize: 22,
                    tooltip: "Seleccionar fecha",
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryColor,
                      fixedSize: const Size(buttonHeight, buttonHeight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // Date picker 
  Future<void> _abrirPickerNativo(BuildContext context, AgendaProvider provider) async {
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
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
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
    final dayName = DateFormat('E', 'es_ES').format(date).toUpperCase().replaceAll('.', '');
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
          border: isSelected ? null : Border.all(color: isToday ? AppTheme.primaryColor : Colors.grey[300]!),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: isToday
            // Solo texto centrado
            ? Center(
                child: Text(
                  "HOY",
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900
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
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}