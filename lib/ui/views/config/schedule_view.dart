import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/horario_modal.dart';
import 'package:quiropractico_front/ui/modals/bloqueo_modal.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

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
      Provider.of<HorariosProvider>(
        context,
        listen: false,
      ).loadDoctoresActive();
    });
  }

  // Obtiene los meses con bloqueos
  List<int> _getMesesConBloqueos(
    List<BloqueoAgenda> todosBloqueos,
    int? idDoctor,
  ) {
    final Set<int> mesesActivos = {};
    for (var bloqueo in todosBloqueos) {
      if (bloqueo.fechaInicio.year == _visualizerYear ||
          bloqueo.fechaFin.year == _visualizerYear) {
        bool afectaAlDoctor =
            (bloqueo.idQuiropractico == null) ||
            (idDoctor != null && bloqueo.idQuiropractico == idDoctor);
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
    final mesesAfectados = _getMesesConBloqueos(
      bloqueosProvider.bloqueos,
      currentDoctor?.idUsuario,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(height: 40, width: 10),
                Icon(
                  Icons.access_time_outlined,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  "Horarios",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(width: 20),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 20),

                // Selector del quiropractico
                if (doctoresList.isEmpty)
                  const Text(
                    "Sin quiroprácticos activos",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  DashboardDropdown<Usuario?>(
                    selectedValue: currentDoctor,
                    tooltip: "Seleccionar quiropráctico",
                    customLabel:
                        currentDoctor == null
                            ? "Seleccionar Doctor"
                            : currentDoctor.nombreCompleto,
                    onSelected: (val) {
                      if (val != null) provider.selectDoctor(val);
                    },
                    options:
                        doctoresList
                            .map(
                              (u) => DropdownOption<Usuario?>(
                                value: u,
                                label: u.nombreCompleto,
                                iconWidget: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    u.nombreCompleto.isNotEmpty
                                        ? u.nombreCompleto[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                const Spacer(),
                const SizedBox(width: 20),

                HoverableActionButton(
                  label: "Turno",
                  icon: Icons.add_alarm,
                  isPrimary: true,
                  tooltip: "Crear nuevo turno",
                  onTap:
                      currentDoctor == null
                          ? () {}
                          : () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => const HorarioModal(),
                            );
                            if (context.mounted) {
                              _handleScheduleResult(result);
                            }
                          },
                ),
              ],
            ),
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
                    child:
                        provider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 0,
                                bottom: 40,
                                right: 10,
                              ),
                              itemCount: 7,
                              itemBuilder: (context, index) {
                                final diaNum = index + 1;
                                final nombreDia = _getDiaNombre(diaNum);
                                final turnosDelDia =
                                    currentDoctor == null
                                        ? []
                                        : provider.horarios
                                            .where((h) => h.diaSemana == diaNum)
                                            .toList();

                                if (turnosDelDia.isNotEmpty) {
                                  turnosDelDia.sort(
                                    (a, b) => (a.horaInicio.hour * 60 +
                                            a.horaInicio.minute)
                                        .compareTo(
                                          b.horaInicio.hour * 60 +
                                              b.horaInicio.minute,
                                        ),
                                  );
                                }
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              nombreDia,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            if (currentDoctor != null)
                                              Tooltip(
                                                message:
                                                    "Turno para el $nombreDia",
                                                child: SizedBox(
                                                  height: 28,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final result =
                                                          await showDialog(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => HorarioModal(
                                                                  initialDay:
                                                                      diaNum,
                                                                ),
                                                          );
                                                      if (context.mounted) {
                                                        _handleScheduleResult(
                                                          result,
                                                        );
                                                      }
                                                    },
                                                    style: ButtonStyle(
                                                      elevation:
                                                          WidgetStateProperty.all(
                                                            0,
                                                          ),
                                                      backgroundColor:
                                                          WidgetStateProperty.resolveWith((
                                                            states,
                                                          ) {
                                                            if (states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )) {
                                                              return AppTheme
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                    0.05,
                                                                  );
                                                            }
                                                            return Colors
                                                                .transparent;
                                                          }),
                                                      foregroundColor:
                                                          WidgetStateProperty.all(
                                                            AppTheme
                                                                .primaryColor,
                                                          ),
                                                      padding:
                                                          WidgetStateProperty.all(
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 0,
                                                            ),
                                                          ),
                                                      shape: WidgetStateProperty.all(
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          side: BorderSide(
                                                            color: AppTheme
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.add,
                                                      size: 14,
                                                    ),
                                                    label: const Text(
                                                      "Nuevo",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (doctoresList.isEmpty)
                                          const Text(
                                            "No hay personal activo",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          )
                                        else if (currentDoctor == null)
                                          const Text(
                                            "Seleccione un doctor para ver horarios",
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 13,
                                            ),
                                          )
                                        else if (turnosDelDia.isEmpty)
                                          const Text(
                                            "Sin turnos asignados",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                            ),
                                          )
                                        else
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children:
                                                turnosDelDia.map((turno) {
                                                  return Tooltip(
                                                    message: "Editar",
                                                    child: InputChip(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      label: Text(
                                                        turno.formattedRange,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Colors.blue.shade50,
                                                      side: BorderSide.none,
                                                      onPressed: () async {
                                                        final result =
                                                            await showDialog(
                                                              context: context,
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => HorarioModal(
                                                                    horarioToEdit:
                                                                        turno,
                                                                  ),
                                                            );
                                                        if (context.mounted) {
                                                          _handleScheduleResult(
                                                            result,
                                                          );
                                                        }
                                                      },
                                                      deleteIcon: const Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: Colors.red,
                                                      ),
                                                      onDeleted: () async {
                                                        final backup = turno;
                                                        final messenger =
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            );
                                                        final err =
                                                            await provider
                                                                .deleteHorario(
                                                                  turno
                                                                      .idHorario,
                                                                );

                                                        if (err == null) {
                                                          if (context.mounted) {
                                                            CustomSnackBar.show(
                                                              context,
                                                              messenger:
                                                                  messenger,
                                                              message:
                                                                  "Turno borrado: $nombreDia ${turno.formattedRange}",
                                                              type:
                                                                  SnackBarType
                                                                      .success,
                                                              actionLabel:
                                                                  "DESHACER",
                                                              onAction: () async {
                                                                messenger
                                                                    .hideCurrentSnackBar();
                                                                // Re-crear horario (Deshacer)
                                                                await provider.createHorario(
                                                                  backup
                                                                      .diaSemana,
                                                                  backup
                                                                      .horaInicio,
                                                                  backup
                                                                      .horaFin,
                                                                );
                                                                if (context
                                                                    .mounted) {
                                                                  CustomSnackBar.show(
                                                                    context,
                                                                    message:
                                                                        "Eliminación deshecha",
                                                                    type:
                                                                        SnackBarType
                                                                            .info,
                                                                  );
                                                                }
                                                              },
                                                            );
                                                          }
                                                        } else {
                                                          if (context.mounted) {
                                                            CustomSnackBar.show(
                                                              context,
                                                              message: err,
                                                              type:
                                                                  SnackBarType
                                                                      .error,
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ),
                const SizedBox(width: 20),

                // Calendario
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          right: 15,
                          left: 15,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => setState(() => _visualizerYear--),
                                    tooltip: "Año anterior",
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  Text(
                                    "Vacaciones $_visualizerYear",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => setState(() => _visualizerYear++),
                                    tooltip: "Año siguiente",
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem(
                                  Colors.red.shade100,
                                  "Clínica Cerrada",
                                ),
                                const SizedBox(width: 15),
                                if (currentDoctor != null)
                                  _buildLegendItem(
                                    Colors.blue.shade100,
                                    "Vacaciones ${currentDoctor.nombreCompleto.split(' ')[0]}",
                                  ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // WRAP DE MESES
                            Expanded(
                              child:
                                  mesesAfectados.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.event_available_rounded,
                                              size: 64,
                                              color: Colors.grey.shade300,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "Sin bloqueos este año",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : LayoutBuilder(
                                        builder: (context, constraints) {
                                          final width = constraints.maxWidth;
                                          final itemMinWidth = 220.0;
                                          final itemHeight = 240.0;

                                          // Calcular columnas dinamicamnete
                                          int crossAxisCount =
                                              (width / itemMinWidth).floor();
                                          if (crossAxisCount < 1)
                                            crossAxisCount = 1;

                                          // Calcular ratio para mantener altura fija
                                          final itemWidth =
                                              width / crossAxisCount;
                                          final childAspectRatio =
                                              itemWidth / itemHeight;

                                          return GridView.builder(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      crossAxisCount,
                                                  childAspectRatio:
                                                      childAspectRatio,
                                                  crossAxisSpacing: 15,
                                                  mainAxisSpacing: 15,
                                                ),
                                            itemCount: mesesAfectados.length,
                                            itemBuilder: (context, index) {
                                              return _buildMonthMiniature(
                                                mesesAfectados[index],
                                                _visualizerYear,
                                                bloqueosProvider.bloqueos,
                                                currentDoctor?.idUsuario,
                                              );
                                            },
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Optener el nombre del dia
  String _getDiaNombre(int dia) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[dia - 1];
  }

  // Para la leyenda
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // Mostrar dialogo de detalles
  void _showDetailsDialog(DateTime day, List<BloqueoAgenda> bloqueosDelDia) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox(
            width: 450,
            height: 500,
            child: _buildDetailsContent(
              bloqueosDelDia,
              day,
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsContent(
    List<BloqueoAgenda> bloqueos,
    DateTime day, {
    VoidCallback? onClose,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header semlificado (Sin botón Añadir)
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
                    Text(
                      "DETALLES DEL DÍA",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEE d, MMM',
                        'es_ES',
                      ).format(day).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: onClose,
                  tooltip: "Cerrar",
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildDetailsList(
            bloqueos,
            isScrollable: true,
            showEdit: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsList(
    List<BloqueoAgenda> bloqueos, {
    bool isScrollable = false,
    required bool showEdit,
  }) {
    if (bloqueos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
              SizedBox(height: 15),
              Text(
                "Día Operativo",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "No hay bloqueos ni festivos.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(15),
      itemCount: bloqueos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      shrinkWrap: !isScrollable,
      physics:
          isScrollable
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      itemBuilder: (itemCtx, index) {
        final bloqueo = bloqueos[index];
        final isGlobal = bloqueo.idQuiropractico == null;

        String fechaTexto;
        if (isSameDay(bloqueo.fechaInicio, bloqueo.fechaFin)) {
          fechaTexto = DateFormat('dd/MM/yyyy').format(bloqueo.fechaInicio);
        } else {
          fechaTexto =
              "Del ${DateFormat('dd/MM').format(bloqueo.fechaInicio)} al ${DateFormat('dd/MM').format(bloqueo.fechaFin)}";
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: isGlobal ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isGlobal ? Colors.red.shade100 : Colors.blue.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGlobal ? Icons.business : Icons.person,
                  color: isGlobal ? Colors.red : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGlobal ? "Global" : bloqueo.nombreQuiropractico,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bloqueo.motivo,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          fechaTexto,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showEdit) ...[
                const SizedBox(width: 10),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 22,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        // Cerrar dialogo actual antes de abrir edicion
                        Navigator.pop(itemCtx);
                        final result = await showDialog(
                          context: context,
                          builder: (_) => BloqueoModal(bloqueoEditar: bloqueo),
                        );

                        if (result != null && result is Map) {
                          _handleBloqueoResult(result);
                        }
                      },
                      tooltip: "Editar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 15),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 24,
                        color: Colors.redAccent,
                      ),
                      tooltip: "Eliminar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final provider = Provider.of<AgendaBloqueoProvider>(
                          context,
                          listen: false,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(itemCtx);
                        final backup = bloqueo;

                        try {
                          await provider.borrarBloqueo(bloqueo.idBloqueo);

                          if (mounted) {
                            final dateStr = DateFormat(
                              'dd/MM',
                            ).format(bloqueo.fechaInicio);
                            CustomSnackBar.show(
                              context,
                              messenger: messenger,
                              message: "Bloqueo del $dateStr eliminado",
                              type: SnackBarType.success,
                              actionLabel: "DESHACER",
                              onAction: () async {
                                // Restaurar bloqueo
                                await provider.crearBloqueo(
                                  backup.fechaInicio,
                                  backup.fechaFin,
                                  backup.motivo,
                                  backup.idQuiropractico,
                                  force: true,
                                );
                                messenger.hideCurrentSnackBar();
                                CustomSnackBar.show(
                                  context,
                                  messenger: messenger,
                                  message: "Eliminación deshecha",
                                  type: SnackBarType.info,
                                );
                              },
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackBar.show(
                              context,
                              message: "Error al eliminar: $e",
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Para contruir cada mes
  Widget _buildMonthMiniature(
    int month,
    int year,
    List<BloqueoAgenda> bloqueos,
    int? selectedDoctorId,
  ) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Titulo del Mes
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              DateFormat('MMMM', 'es_ES').format(firstDay).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Calendario Miniatura
          Expanded(
            child: TableCalendar<BloqueoAgenda>(
              locale: 'es_ES',
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: firstDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerVisible: false,
              shouldFillViewport: true,
              daysOfWeekHeight: 18,
              rowHeight: 28,
              pageJumpingEnabled: false,
              availableGestures: AvailableGestures.none,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                weekendStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),

              calendarBuilders: CalendarBuilders(
                defaultBuilder:
                    (context, day, focusedDay) => _buildMiniCell(
                      day,
                      bloqueos,
                      selectedDoctorId,
                      isOutside: false,
                    ),
                todayBuilder:
                    (context, day, focusedDay) => _buildMiniCell(
                      day,
                      bloqueos,
                      selectedDoctorId,
                      isOutside: false,
                      isToday: true,
                    ),
                outsideBuilder:
                    (context, day, focusedDay) => const SizedBox.shrink(),
                markerBuilder: (context, day, events) => const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builder celda miniatura
  Widget _buildMiniCell(
    DateTime day,
    List<BloqueoAgenda> bloqueos,
    int? selectedDoctorId, {
    bool isOutside = false,
    bool isToday = false,
  }) {
    if (isOutside) return const SizedBox.shrink();

    final bloqueosDia =
        bloqueos.where((b) {
          final inicio = DateTime(
            b.fechaInicio.year,
            b.fechaInicio.month,
            b.fechaInicio.day,
          );
          final fin = DateTime(
            b.fechaFin.year,
            b.fechaFin.month,
            b.fechaFin.day,
          );
          final check = DateTime(day.year, day.month, day.day);
          return !check.isBefore(inicio) && !check.isAfter(fin);
        }).toList();

    Color? bgColor;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;

    bool hasRelevantBlocks = false;

    if (bloqueosDia.isNotEmpty) {
      if (bloqueosDia.any((b) => b.idQuiropractico == null)) {
        // Bloqueo Global
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        fontWeight = FontWeight.bold;
        hasRelevantBlocks = true;
      } else if (selectedDoctorId != null &&
          bloqueosDia.any((b) => b.idQuiropractico == selectedDoctorId)) {
        // Bloqueo Doctor Seleccionado
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        fontWeight = FontWeight.bold;
        hasRelevantBlocks = true;
      }
    }

    if (isToday && bgColor == null) {
      textColor = AppTheme.primaryColor;
      fontWeight = FontWeight.bold;
      bgColor = AppTheme.primaryColor.withOpacity(0.05);
    }

    Widget cellContent = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );

    if (hasRelevantBlocks) {
      return Tooltip(
        message: "Ver detalles",
        child: InkWell(
          onTap: () => _showDetailsDialog(day, bloqueosDia),
          borderRadius: BorderRadius.circular(4),
          child: cellContent,
        ),
      );
    }

    return cellContent;
  }

  void _handleBloqueoResult(Map result) {
    if (!mounted) return;

    final provider = Provider.of<AgendaBloqueoProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final action = result['action'];
    final BloqueoAgenda? bloqueoObj = result['bloqueo'];
    final bool isGlobal = result['isGlobal'] ?? false;
    final String? nombreQuiro = result['nombreQuiro'];
    final String? fechasStr = result['fechasStr'];
    final List<BloqueoAgenda>? conflicting = result['conflicting'];

    String mensaje = "";
    if (action == 'create_forced') {
      mensaje = "Conflictos resueltos y bloqueo creado";
    } else {
      if (isGlobal) {
        mensaje =
            action == 'update'
                ? "Bloqueo global actualizado ($fechasStr)"
                : "Bloqueo global creado ($fechasStr)";
      } else {
        final accion = action == 'update' ? "actualizado" : "creado";
        mensaje = "Bloqueo $accion para $nombreQuiro ($fechasStr)";
      }
    }

    CustomSnackBar.show(
      context,
      message: mensaje,
      type: SnackBarType.success,
      actionLabel: "DESHACER",
      onAction: () async {
        try {
          if (action == 'update') {
            if (bloqueoObj != null) {
              await provider.editarBloqueo(
                bloqueoObj.idBloqueo,
                bloqueoObj.fechaInicio,
                bloqueoObj.fechaFin,
                bloqueoObj.motivo,
                bloqueoObj.idQuiropractico,
              );
            }
          } else if (action == 'create') {
            if (bloqueoObj != null) {
              await provider.borrarBloqueo(bloqueoObj.idBloqueo);
            }
          } else if (action == 'create_forced') {
            if (bloqueoObj != null) {
              await provider.borrarBloqueo(bloqueoObj.idBloqueo);
            }
            if (conflicting != null) {
              for (final b in conflicting) {
                await provider.crearBloqueo(
                  b.fechaInicio,
                  b.fechaFin,
                  b.motivo,
                  b.idQuiropractico,
                  force: true,
                );
              }
            }
          }

          messenger.hideCurrentSnackBar();
          CustomSnackBar.show(
            context,
            messenger: messenger,
            message: "Cambios cancelados",
            type: SnackBarType.info,
          );
        } catch (e) {
          messenger.hideCurrentSnackBar();
          CustomSnackBar.show(
            context,
            messenger: messenger,
            message: "Error restaurando: $e",
            type: SnackBarType.error,
          );
        }
      },
    );
  }

  void _handleScheduleResult(dynamic result) {
    if (result == null || result is! Map || result['success'] != true) return;

    final action = result['action'];
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<HorariosProvider>(context, listen: false);

    if (action == 'create') {
      final displayData = result['displayData'];
      final createdId = result['createdId'];
      final message =
          'Turno creado: ${displayData['diaLabel']} ${displayData['timeRange']}';

      CustomSnackBar.show(
        context,
        message: message,
        type: SnackBarType.success,
        actionLabel: "DESHACER",
        onAction: () async {
          messenger.hideCurrentSnackBar();
          if (createdId != null) {
            final deleteErr = await provider.deleteHorario(createdId);
            if (deleteErr == null && context.mounted) {
              CustomSnackBar.show(
                context,
                messenger: messenger,
                message: "Creación deshecha",
                type: SnackBarType.info,
              );
            }
          }
        },
      );
    } else if (action == 'update') {
      final displayData = result['displayData'];
      final backup = result['backup'];
      final message = 'Turno editado: ${displayData?['timeRange'] ?? ''}';

      CustomSnackBar.show(
        context,
        message: message,
        type: SnackBarType.success,
        actionLabel: "DESHACER",
        onAction: () async {
          messenger.hideCurrentSnackBar();
          if (backup != null) {
            try {
              await provider.updateHorario(
                backup['idHorario'],
                backup['diaSemana'],
                backup['horaInicio'],
                backup['horaFin'],
              );
              if (context.mounted) {
                CustomSnackBar.show(
                  context,
                  messenger: messenger,
                  message: "Edición deshecha",
                  type: SnackBarType.info,
                );
              }
            } catch (e) {
              // Log error
            }
          }
        },
      );
    }
  }
}
