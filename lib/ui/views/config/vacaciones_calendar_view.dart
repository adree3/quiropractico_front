import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
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
  
  bool _isSelectionMode = false;
  final Set<DateTime> _diasSeleccionados = {}; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<AgendaBloqueoProvider>(context, listen: false).loadBloqueos();
    });
  }

  // Lógica de filtrado
  List<BloqueoAgenda> _getBloqueosDelDia(DateTime day, List<BloqueoAgenda> todos) {
    return todos.where((bloqueo) {
      final inicio = DateTime(bloqueo.fechaInicio.year, bloqueo.fechaInicio.month, bloqueo.fechaInicio.day);
      final fin = DateTime(bloqueo.fechaFin.year, bloqueo.fechaFin.month, bloqueo.fechaFin.day);
      final check = DateTime(day.year, day.month, day.day);
      return !check.isBefore(inicio) && !check.isAfter(fin);
    }).toList();
  }

  // Obtener los bloqueos de los dia seleccionados
  List<BloqueoAgenda> _getBloqueosAcumulados(List<BloqueoAgenda> todos) {
    final Set<int> idsProcesados = {};
    final List<BloqueoAgenda> resultados = [];

    for (var dia in _diasSeleccionados) {
      final bloqueosDia = _getBloqueosDelDia(dia, todos);
      for (var b in bloqueosDia) {
        if (!idsProcesados.contains(b.idBloqueo)) {
          idsProcesados.add(b.idBloqueo);
          resultados.add(b);
        }
      }
    }
    return resultados;
  }

  // Metodo para seleccionar mes y año
  Future<void> _seleccionarMesAnio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked; 
      });
    }
  }

  // Logica para cuando se da clic en un dia
  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay, List<BloqueoAgenda> todosLosBloqueos, bool isLargeScreen) {
    setState(() {
      _focusedDay = focusedDay;
    });

    // Modo seleccion multiple (borrar)
    if (_isSelectionMode) {
      final tieneBloqueos = _getBloqueosDelDia(selectedDay, todosLosBloqueos).isNotEmpty;
      
      if (tieneBloqueos) {
        setState(() {
          if (_diasSeleccionados.contains(selectedDay)) {
            _diasSeleccionados.remove(selectedDay);
          } else {
            _diasSeleccionados.add(selectedDay);
          }
        });
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomSnackBar.show(context, 
          message: "Este día no tiene bloqueos para eliminar", 
          type: SnackBarType.info,
          duration: Duration(seconds: 1)
        );
      }
    } 
    // Modo seleccion simple (ver detalles)
    else {
      setState(() {
        _selectedDay = selectedDay;
      });
      if (!isLargeScreen) {
        _showDetailsDialog(selectedDay);
      }
    }
  }

  // Borrar en lote
  Future<void> _eliminarLote(AgendaBloqueoProvider provider) async {
    final bloqueosABorrar = _getBloqueosAcumulados(provider.bloqueos);
    if (bloqueosABorrar.isEmpty) return;

    final diasOrdenados = _diasSeleccionados.toList()..sort();
    String textoDias = "";
    if (diasOrdenados.length == 1) {
      textoDias = DateFormat('dd/MM').format(diasOrdenados.first);
    } else {
      textoDias = "${DateFormat('dd/MM').format(diasOrdenados.first)} - ${DateFormat('dd/MM').format(diasOrdenados.last)}";
    }
    
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Confirmar Eliminación", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              "Días seleccionados en calendario: ${_diasSeleccionados.length} ($textoDias)", 
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.normal)
            ),
          ],
        ),
        // Motrar lo que se va a borrar
        content: SizedBox(
          width: 500,
          height: bloqueosABorrar.length > 3 ? 300 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Se eliminarán ${bloqueosABorrar.length} registros. Esto afectará a todo el rango de fechas de cada bloqueo.",
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13)
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text("Registros a eliminar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 5),
              
              // Lista de bloques
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: bloqueosABorrar.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final b = bloqueosABorrar[index];
                    final isGlobal = b.idQuiropractico == null;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isGlobal ? Colors.red.shade100 : Colors.blue.shade100,
                        child: Icon(isGlobal ? Icons.business : Icons.person, color: isGlobal ? Colors.red : Colors.blue, size: 18),
                      ),
                      title: Text(b.nombreQuiropractico, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        "${DateFormat('dd/MM').format(b.fechaInicio)} al ${DateFormat('dd/MM').format(b.fechaFin)} • ${b.motivo}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Eliminar Definitivamente")
          )
        ],
      )
    );

    if (confirm == true) {
      final futures = bloqueosABorrar.map((b) => provider.borrarBloqueo(b.idBloqueo));
      await Future.wait(futures);
      
      setState(() {
        _diasSeleccionados.clear();
        _isSelectionMode = false; 
      });
      
      if (mounted) {
        CustomSnackBar.show(context, 
          message: "Bloqueos eliminados correctamente", 
          type: SnackBarType.success
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaBloqueoProvider>(context);
    final bloqueosDelDia = _getBloqueosDelDia(_selectedDay!, provider.bloqueos);
    final bloqueosAcumulados = _getBloqueosAcumulados(provider.bloqueos);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 1130;

        return Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER 
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    // Icono + Titulo
                    Icon(Icons.calendar_month_outlined, size: 24, color: Colors.grey.shade700),
                    const SizedBox(width: 10),
                    Text(
                      'Calendario de Vacaciones', 
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    
                    const Spacer(),

                    // CONTROLES DE ACCIÓN
                    if (_isSelectionMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200)
                        ),
                        child: Text(
                          _diasSeleccionados.isEmpty 
                            ? "Selecciona días..." 
                            : "${_diasSeleccionados.length} seleccionados", 
                          style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // Botones Acción
                      if (_diasSeleccionados.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => _eliminarLote(provider), 
                          icon: const Icon(Icons.delete, size: 18),
                          label: Text("Eliminar (${bloqueosAcumulados.length})")
                        ),
                      const SizedBox(width: 10),
                      
                      OutlinedButton.icon(
                        onPressed: () => setState(() { _isSelectionMode = false; _diasSeleccionados.clear(); }),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Cancelar"),
                      ),
                    ] else ...[
                      // Botones Modo Normal 
                      IconButton(
                        tooltip: "Borrar en lote",
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.grey),
                        color: Colors.red,
                        onPressed: () => setState(() { _isSelectionMode = true; _diasSeleccionados.clear(); }),
                      ),
                      const SizedBox(width: 15),
                      Container(width: 1, height: 30, color: Colors.grey.shade300), // Separador
                      const SizedBox(width: 15),
                      
                      _HoverableActionButton(
                        onTap: () => showDialog(context: context, builder: (_) => const BloqueoModal()), 
                        label: "Nuevo Bloqueo", 
                        icon: Icons.add,
                        isPrimary: true
                      ),
                    ]
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // CALENDARIO + DETALLES
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
                                      
                                      InkWell(
                                        onTap: _seleccionarMesAnio,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              Text(DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay).toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.edit_calendar, size: 18, color: AppTheme.primaryColor) 
                                            ],
                                          ),
                                        ),
                                      ),

                                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
                                    ],
                                  ),
                                ),
                                
                                const Divider(height: 1),

                                Expanded(
                                  child: TableCalendar<BloqueoAgenda>(
                                    locale: 'es_ES',
                                    firstDay: DateTime(1990), lastDay: DateTime(2100),
                                    focusedDay: _focusedDay,
                                    startingDayOfWeek: StartingDayOfWeek.monday,
                                    headerVisible: false,
                                    shouldFillViewport: true,
                                    daysOfWeekHeight: 40,
                                    selectedDayPredicate: (day) => _isSelectionMode ? _diasSeleccionados.any((d) => isSameDay(d, day)) : isSameDay(_selectedDay, day),
                                    eventLoader: (day) => _getBloqueosDelDia(day, provider.bloqueos),
                                    onDaySelected: (selected, focused) => _handleDaySelected(selected, focused, provider.bloqueos, isLargeScreen),
                                    onPageChanged: (focused) => _focusedDay = focused,

                                    calendarBuilders: CalendarBuilders(
                                      defaultBuilder: (context, day, focusedDay) => _buildCell(day, provider.bloqueos, isSelected: false, isToday: false),
                                      selectedBuilder: (context, day, focusedDay) => _buildCell(day, provider.bloqueos, isSelected: true, isToday: isSameDay(day, DateTime.now())),
                                      todayBuilder: (context, day, focusedDay) => _buildCell(day, provider.bloqueos, isSelected: false, isToday: true),
                                      outsideBuilder: (context, day, focusedDay) => _buildCell(day, provider.bloqueos, isSelected: false, isToday: false, isOutside: true),
                                      markerBuilder: (context, day, events) => const SizedBox(), 
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (isLargeScreen) ...[
                      const SizedBox(width: 20),
                      // PANEL LATERAL
                      Flexible(
                        flex: 1, 
                        child: Container( 
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _isSelectionMode 
                              ? _buildSelectionSummaryPanel(bloqueosAcumulados)
                              : _buildSidePanel(bloqueosDelDia) 
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // Widget celda del calendario
  Widget _buildDetailsContent(List<BloqueoAgenda> bloqueos, {VoidCallback? onClose}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DETALLES DEL DÍA", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEE d, MMM', 'es_ES').format(_selectedDay!).toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              
              // Botón Añadir
              IconButton(
                tooltip: "Añadir bloqueo este día",
                icon: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20)),
                onPressed: () {
                  showDialog(context: context, builder: (_) => BloqueoModal(preselectedDate: _selectedDay));
                },
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: onClose,
                  tooltip: "Cerrar",
                )
              ]
            ],
          ),
        ),
        const Divider(height: 1),
        
        if (onClose != null)
          Expanded(child: _buildDetailsList(bloqueos, isScrollable: true, showEdit: true))
        else
          _buildDetailsList(bloqueos, isScrollable: false, showEdit: true)
      ],
    );
  }

  // Widget detalles panel lateral (fijo)
  Widget _buildSidePanel(List<BloqueoAgenda> bloqueos) {
    return Column(
      children: [
        Expanded(child: _buildDetailsContent(bloqueos)),
      ],
    );
  }

  // Widget detalles dialog
  void _showDetailsDialog(DateTime day) {
    showDialog(
      context: context, 
      builder: (ctx) {
        final provider = Provider.of<AgendaBloqueoProvider>(ctx);
        final bloqueosDelDia = _getBloqueosDelDia(day, provider.bloqueos);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SizedBox(
            width: 450, 
            height: 500,
            child: _buildDetailsContent(bloqueosDelDia, onClose: () => Navigator.pop(ctx)),
          ),
        );
      }
    );
  }

  // Widget panel resumen (modo seleccion)
  Widget _buildSelectionSummaryPanel(List<BloqueoAgenda> bloqueosAcumulados) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.red.shade50.withOpacity(0.3),
      child: Container(
        constraints: const BoxConstraints(minHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ELEMENTOS A ELIMINAR", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text("${_diasSeleccionados.length} Días Marcados", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red)),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDetailsList(bloqueosAcumulados, isScrollable: false, showEdit: false),
          ],
        ),
      ),
    );
  }

  // Widget para los detalles del día
  Widget _buildDetailsList(List<BloqueoAgenda> bloqueos, {bool isScrollable = false, required bool showEdit}) {
    if (bloqueos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
              SizedBox(height: 15),
              Text("Día Operativo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 5),
              Text("No hay bloqueos ni festivos.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(15), 
      itemCount: bloqueos.length,
      separatorBuilder: (_,__) => const SizedBox(height: 15),
      shrinkWrap: !isScrollable,
      physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final bloqueo = bloqueos[index];
        final isGlobal = bloqueo.idQuiropractico == null;
        
        String fechaTexto;
        if (isSameDay(bloqueo.fechaInicio, bloqueo.fechaFin)) {
          fechaTexto = DateFormat('dd/MM/yyyy').format(bloqueo.fechaInicio);
        } else {
          fechaTexto = "Del ${DateFormat('dd/MM').format(bloqueo.fechaInicio)} al ${DateFormat('dd/MM').format(bloqueo.fechaFin)}";
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: isGlobal ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isGlobal ? Colors.red.shade100 : Colors.blue.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))]
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // ICONO 
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle
                ),
                child: Icon(isGlobal ? Icons.business : Icons.person, color: isGlobal ? Colors.red : Colors.blue, size: 24),
              ),
              
              const SizedBox(width: 15),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      isGlobal ? "Global" : bloqueo.nombreQuiropractico, 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                    ),
                    const SizedBox(height: 6),
                    
                    // MOTIVO
                    Text(
                      bloqueo.motivo, 
                      style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.3)
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // FECHA
                    Row(
                      children: [
                        Text(
                          fechaTexto, 
                          style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // BOTONES DE ACCIÓN
              if (showEdit) ...[
                const SizedBox(width: 10),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 22, color: Colors.grey),
                      onPressed: () => showDialog(context: context, builder: (_) => BloqueoModal(bloqueoEditar: bloqueo)),
                      tooltip: "Editar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 15), 
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 24, color: Colors.redAccent),
                      tooltip: "Eliminar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                         final provider = Provider.of<AgendaBloqueoProvider>(context, listen: false);
                         await provider.borrarBloqueo(bloqueo.idBloqueo);
                      },
                    )
                  ],
                )
              ]
            ],
          ),
        );
      },
    );
  }

  // Celda de calendario
  Widget _buildCell(DateTime day, List<BloqueoAgenda> todosLosBloqueos, {
    required bool isSelected, 
    required bool isToday, 
    bool isOutside = false
  }) {
    final eventosDelDia = _getBloqueosDelDia(day, todosLosBloqueos);
    final bool hayCierreGlobal = eventosDelDia.any((e) => e.idQuiropractico == null);
    final int doctoresFuera = eventosDelDia.where((e) => e.idQuiropractico != null).length;
    
    // Logica visual del modo seleccion
    bool isDimmed = false;
    if (_isSelectionMode) {
      if (eventosDelDia.isEmpty) {
        isDimmed = true;
      }
    }

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;

    if (isOutside || isDimmed) {
      bgColor = Colors.grey.shade50;
      textColor = Colors.grey.shade300;
    } else {
      if (hayCierreGlobal) {
        bgColor = Colors.red.shade50;
      } else if (doctoresFuera > 0) {
        bgColor = Colors.blue.shade50; 
      } else if (isToday) {
        bgColor = AppTheme.primaryColor.withOpacity(0.05);
      }
    }

    // Borde rojo si esta seleccionado en modo seleccion
    if (_isSelectionMode && _diasSeleccionados.any((d) => isSameDay(d, day))) {
      borderColor = Colors.red;
      bgColor = Colors.red.shade100;
    } else if (isSelected && !_isSelectionMode) {
      borderColor = AppTheme.primaryColor;
      if (!hayCierreGlobal && doctoresFuera == 0) bgColor = AppTheme.primaryColor.withOpacity(0.1);
    }

    return Opacity(
      opacity: isDimmed ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(left: 2, right: 2, bottom: 2, top: 0), 
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: (isSelected || (_isSelectionMode && borderColor == Colors.red)) ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${day.day}', style: TextStyle(fontWeight: (isToday && !isOutside) ? FontWeight.bold : FontWeight.normal, color: (isToday && !isOutside && !isDimmed) ? AppTheme.primaryColor : textColor, fontSize: 15)),
                  if (hayCierreGlobal && !isOutside) const Icon(Icons.lock, size: 14, color: Colors.red)
                ],
              ),
            ),
            const Spacer(),
            if (eventosDelDia.isNotEmpty && !isOutside)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hayCierreGlobal)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                        child: const Text("CERRADO", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    if (doctoresFuera > 0) ...[
                      if (hayCierreGlobal) const SizedBox(height: 2),
                      Row(children: List.generate(doctoresFuera > 5 ? 5 : doctoresFuera, (index) => Container(margin: const EdgeInsets.only(right: 3), width: 8, height: 8, decoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)))))
                    ]
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
class _HoverableActionButton extends StatefulWidget {
  final VoidCallback onTap; final String label; final IconData icon; final bool isPrimary;
  const _HoverableActionButton({required this.onTap, required this.label, required this.icon, this.isPrimary = false});
  @override State<_HoverableActionButton> createState() => _HoverableActionButtonState();
}
class _HoverableActionButtonState extends State<_HoverableActionButton> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(onEnter: (_) => setState(() => _isHovering = true), onExit: (_) => setState(() => _isHovering = false), cursor: SystemMouseCursors.click, child: GestureDetector(onTap: widget.onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: widget.isPrimary ? (_isHovering ? AppTheme.primaryColor.withOpacity(0.9) : AppTheme.primaryColor) : (_isHovering ? Colors.grey.shade100 : Colors.transparent), borderRadius: BorderRadius.circular(8), boxShadow: widget.isPrimary ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null), child: Row(children: [Icon(widget.icon, size: 18, color: widget.isPrimary ? Colors.white : Colors.grey), const SizedBox(width: 8), Text(widget.label, style: TextStyle(color: widget.isPrimary ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600))]))));
  }
}