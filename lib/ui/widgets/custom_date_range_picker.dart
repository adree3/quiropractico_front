import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDateRangePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTimeRange>(
      context: context,
      builder:
        (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: CustomDateRangePicker(
            initialStartDate: initialStartDate,
            initialEndDate: initialEndDate,
            firstDate: firstDate ?? DateTime(2020),
            lastDate:
                lastDate ?? DateTime.now().add(const Duration(days: 365)),
          ),
        ),
    );
  }

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    if (_rangeStart != null) {
      _focusedDay = _rangeStart!;
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 340,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildCalendar(),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = "Seleccionar Fechas";
    if (_rangeStart != null) {
      final startStr = DateFormat('dd MMM', 'es_ES').format(_rangeStart!);
      if (_rangeEnd != null) {
        final endStr = DateFormat('dd MMM yyyy', 'es_ES').format(_rangeEnd!);
        title = "$startStr - $endStr";
      } else {
        title = "$startStr - ...";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppTheme.primaryColor,
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: widget.firstDate,
        lastDay: widget.lastDate,
        focusedDay: _focusedDay,

        // Configuración de Rango
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        rangeSelectionMode: RangeSelectionMode.toggledOn,
        onRangeSelected: _onRangeSelected,

        // Estilo
        startingDayOfWeek: StartingDayOfWeek.monday,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          rangeHighlightColor: AppTheme.primaryColor.withOpacity(0.1),
          rangeStartDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text("Cancelar"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed:
                (_rangeStart != null)
                    ? () {
                      final start = _rangeStart!;
                      final end = _rangeEnd ?? start;
                      Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: start, end: end));
                    }
                    : null,
            child: const Text("Aplicar"),
          ),
        ],
      ),
    );
  }
}