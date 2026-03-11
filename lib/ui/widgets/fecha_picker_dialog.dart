import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';

class FechaPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final Color colorTema;
  final List<int> diasActivosSemana;
  final List<BloqueoAgenda> bloqueos;
  final int? idQuiroSeleccionado;

  const FechaPickerDialog({
    required this.initialDate,
    required this.colorTema,
    required this.diasActivosSemana,
    required this.bloqueos,
    this.idQuiroSeleccionado,
  });

  @override
  State<FechaPickerDialog> createState() => FechaPickerDialogState();
}

class FechaPickerDialogState extends State<FechaPickerDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Modo del calendario: 'month' | 'year' | 'monthSelect'
  String _mode = 'month';
  int _pickerYear = DateTime.now().year;

  static final _firstDay = DateTime(1990, 1, 1);
  DateTime get _lastDay => DateTime(DateTime.now().year + 1, 12, 31);

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  BloqueoAgenda? _bloqueoParaDia(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (final b in widget.bloqueos) {
      final afectaQuiro =
          b.idQuiropractico == null ||
          b.idQuiropractico == widget.idQuiroSeleccionado;
      if (!afectaQuiro) continue;
      final inicio = DateTime(
        b.fechaInicio.year,
        b.fechaInicio.month,
        b.fechaInicio.day,
      );
      final fin = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
      if (!d.isBefore(inicio) && !d.isAfter(fin)) return b;
    }
    return null;
  }

  bool _esDiaActivo(DateTime day) =>
      widget.diasActivosSemana.contains(day.weekday);
  bool _isDaySelectable(DateTime day) =>
      _esDiaActivo(day) && _bloqueoParaDia(day) == null;

  void _goToToday() => setState(() {
    _focusedDay = DateTime.now();
    _mode = 'month';
  });

  // Header personalizado
  Widget _buildHeader(Color color) {
    final monthLabel = DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay);
    final monthLabelCap = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return Row(
      children: [
        // Chevron izquierdo
        if (_mode == 'month')
          Tooltip(
            message: 'Mes anterior',
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: color),
              visualDensity: VisualDensity.compact,
              onPressed:
                  () => setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                  }),
            ),
          )
        else
          Tooltip(
            message: 'Año anterior',
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: color),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _pickerYear--),
            ),
          ),

        // Título clicable
        Expanded(
          child: Tooltip(
            message:
                _mode == 'month'
                    ? 'Seleccionar mes/año'
                    : 'Volver al calendario',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap:
                    () => setState(() {
                      if (_mode == 'month') {
                        _pickerYear = _focusedDay.year;
                        _mode = 'year';
                      } else {
                        _mode = 'month';
                      }
                    }),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _mode == 'month' ? monthLabelCap : '$_pickerYear',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _mode == 'month'
                            ? Icons.expand_more
                            : Icons.expand_less,
                        size: 16,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botón "ir a hoy" — solo visible si no estás en el mes actual
        if (_mode == 'month' &&
            !(_focusedDay.year == DateTime.now().year &&
                _focusedDay.month == DateTime.now().month))
          Tooltip(
            message: 'Volver a hoy',
            child: IconButton(
              icon: Icon(
                Icons.today_outlined,
                size: 18,
                color: color.withOpacity(0.7),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: _goToToday,
            ),
          ),

        // Chevron derecho
        if (_mode == 'month')
          Tooltip(
            message: 'Mes siguiente',
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: color),
              visualDensity: VisualDensity.compact,
              onPressed:
                  () => setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                  }),
            ),
          )
        else
          Tooltip(
            message: 'Año siguiente',
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: color),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _pickerYear++),
            ),
          ),
      ],
    );
  }

  // Picker de meses (tras elegir año)
  Widget _buildMonthPicker(Color color) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (ctx, i) {
        final isCurrentMonth =
            _focusedDay.month == i + 1 && _focusedDay.year == _pickerYear;
        return _HoverCell(
          color: color,
          isSelected: isCurrentMonth,
          onTap:
              () => setState(() {
                _focusedDay = DateTime(_pickerYear, i + 1);
                _mode = 'month';
              }),
          child: Text(
            months[i],
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
              color: isCurrentMonth ? color : Colors.grey[700],
            ),
          ),
        );
      },
    );
  }

  // Picker de años
  Widget _buildYearPicker(Color color) {
    final startYear = _firstDay.year;
    final endYear = _lastDay.year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return SizedBox(
      height: 220,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.6,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: years.length,
        itemBuilder: (ctx, i) {
          final year = years[i];
          final isCurrent = year == _focusedDay.year;
          return _HoverCell(
            color: color,
            isSelected: isCurrent,
            onTap:
                () => setState(() {
                  _pickerYear = year;
                  _mode = 'monthSelect';
                }),
            child: Text(
              '$year',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? color : Colors.grey[700],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.colorTema;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabecera fija
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecciona una fecha',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Cerrar',
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ── Sub-header navegación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildHeader(color),
            ),

            // ── Contenido variable
            if (_mode == 'year')
              _buildYearPicker(color)
            else if (_mode == 'monthSelect')
              _buildMonthPicker(color)
            else ...[
              // ── TableCalendar (tamaño fijo con rowHeight)
              TableCalendar(
                locale: 'es_ES',
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!_isDaySelectable(selectedDay)) return;
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  Navigator.pop(context, selectedDay);
                },
                onPageChanged:
                    (focusedDay) => setState(() => _focusedDay = focusedDay),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                headerVisible: false,
                rowHeight: 36,
                daysOfWeekHeight: 24,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: color, width: 1.5),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: color.withOpacity(0.75),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  defaultTextStyle: const TextStyle(fontSize: 13),
                  weekendTextStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  disabledTextStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[300],
                  ),
                  cellMargin: const EdgeInsets.all(2),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focusedDay) {
                    final bloqueo = _bloqueoParaDia(day);
                    final activo = _esDiaActivo(day);

                    if (bloqueo != null) {
                      return Tooltip(
                        message: 'Cerrado · ${bloqueo.motivo}',
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!activo) {
                      return Container(
                        margin: const EdgeInsets.all(2),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500]!.withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    // Día disponible → cursor pointer + hover sombra
                    return _HoverDay(
                      color: color,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                  selectedBuilder:
                      (ctx, day, focusedDay) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.50),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  todayBuilder:
                      (ctx, day, focusedDay) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ],

            // ── Leyenda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                    color: color.withOpacity(0.75),
                    label: 'Disponible',
                  ),
                  const SizedBox(width: 14),
                  _LegendDot(color: Colors.red.shade300, label: 'Bloqueado'),
                  const SizedBox(width: 14),
                  _LegendDot(
                    color: Colors.grey.shade300,
                    label: 'No laborable',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}

// ── Celda con hover para pickers de año/mes ────────────

class _HoverCell extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  const _HoverCell({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });
  @override
  State<_HoverCell> createState() => _HoverCellState();
}

class _HoverCellState extends State<_HoverCell> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? widget.color.withOpacity(0.15)
                    : _hovered
                    ? widget.color.withOpacity(0.07)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.isSelected
                      ? widget.color
                      : (_hovered
                          ? widget.color.withOpacity(0.3)
                          : Colors.grey.shade200),
            ),
            boxShadow:
                _hovered
                    ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Día clicable con hover sutil ────────────────────────

class _HoverDay extends StatefulWidget {
  final Color color;
  final Widget child;
  const _HoverDay({required this.color, required this.child});
  @override
  State<_HoverDay> createState() => _HoverDayState();
}

class _HoverDayState extends State<_HoverDay> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hovered ? widget.color.withOpacity(0.08) : Colors.transparent,
          boxShadow:
              _hovered
                  ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
