import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';

class WeekDaysHeader extends StatelessWidget {
  const WeekDaysHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context);
    final fechaActual = provider.selectedDate;
    final int diaSemana = fechaActual.weekday;
    final DateTime lunesDeEstaSemana = fechaActual.subtract(Duration(days: diaSemana - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final date = lunesDeEstaSemana.add(Duration(days: index));
          final isSelected = isSameDay(date, fechaActual);

          return _DayCircle(
            date: date,
            isSelected: isSelected,
            onTap: () => provider.updateSelectedDate(date),
          );
        }),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCircle extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCircle({required this.date, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E', 'es_ES').format(date).toUpperCase().replaceAll('.', '');
    final dayNumber = date.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          shape: BoxShape.circle,
          border: isSelected ? null : Border.all(color: Colors.grey[300]!), 
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold
              ),
            ),
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}