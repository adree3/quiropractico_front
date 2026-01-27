import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/exceptions/bloqueo_conflict_exception.dart';

class BloqueoModal extends StatefulWidget {
  final BloqueoAgenda? bloqueoEditar;
  final DateTime? preselectedDate;

  const BloqueoModal({super.key, this.bloqueoEditar, this.preselectedDate});

  @override
  State<BloqueoModal> createState() => _BloqueoModalState();
}

class _BloqueoModalState extends State<BloqueoModal> {
  final _formKey = GlobalKey<FormState>();
  final motivoCtrl = TextEditingController();

  late DateTime start;
  late DateTime end;
  Usuario? selectedQuiro;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.bloqueoEditar != null) {
      final b = widget.bloqueoEditar!;
      start = b.fechaInicio;
      end = b.fechaFin;
      motivoCtrl.text = b.motivo;
    } else {
      final baseDate = widget.preselectedDate ?? DateTime.now();
      start = DateTime(baseDate.year, baseDate.month, baseDate.day);
      end = DateTime(baseDate.year, baseDate.month, baseDate.day);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final agendaProv = Provider.of<AgendaProvider>(context, listen: false);
      if (agendaProv.quiropracticos.isEmpty)
        await agendaProv.loadQuiropracticos();

      if (widget.bloqueoEditar != null &&
          widget.bloqueoEditar!.idQuiropractico != null) {
        try {
          setState(() {
            selectedQuiro = agendaProv.quiropracticos.firstWhere(
              (u) => u.idUsuario == widget.bloqueoEditar!.idQuiropractico,
            );
          });
        } catch (_) {}
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : (end.isBefore(start) ? start : end),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        _errorMessage = null; // Limpiar error al cambiar fecha
        if (isStart) {
          start = picked;
          if (end.isBefore(start)) {
            end = start;
          }
        } else {
          if (picked.isBefore(start)) {
            end = start;
          } else {
            end = picked;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(
      context,
      listen: false,
    );
    final esEdicion = widget.bloqueoEditar != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        esEdicion ? "Editar Bloqueo" : "Asignar Bloqueo",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Usuario?>(
                decoration: const InputDecoration(
                  labelText: 'Afectado',
                  prefixIcon: Icon(Icons.person_pin_circle_outlined),
                  helperText:
                      'Selecciona "Toda la Clínica" para festivos generales',
                ),
                value: selectedQuiro,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("🏢 TODA LA CLÍNICA (Cierre)"),
                  ),
                  ...agendaProvider.quiropracticos.map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.nombreCompleto),
                    ),
                  ),
                ],
                onChanged:
                    (val) => setState(() {
                      selectedQuiro = val;
                      _errorMessage = null; // Limpiar error al cambiar usuario
                    }),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(start)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          prefixIcon: Icon(Icons.event),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(end)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Ej: Vacaciones, Congreso, Festivo...',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final fechaInicioReal = DateTime(
                start.year,
                start.month,
                start.day,
                0,
                0,
                0,
              );
              final fechaFinReal = DateTime(
                end.year,
                end.month,
                end.day,
                23,
                59,
                59,
              );

              // Reset error state
              setState(() => _errorMessage = null);

              try {
                String? apiError;
                BloqueoAgenda? nuevoBloqueo;

                if (esEdicion) {
                  final err = await bloqueoProvider.editarBloqueo(
                    widget.bloqueoEditar!.idBloqueo,
                    fechaInicioReal,
                    fechaFinReal,
                    motivoCtrl.text,
                    selectedQuiro?.idUsuario,
                  );
                  // Editar devuelve String? (error) o null (éxito)
                  if (err is String) apiError = err;

                  // Si no hay error, preparamos para el snackbar (el flujo unificado abajo lo maneja)
                  // Solo necesitamos asegurarnos de que la lógica de deshacer tenga acceso a los datos originales
                } else {
                  final result = await bloqueoProvider.crearBloqueo(
                    fechaInicioReal,
                    fechaFinReal,
                    motivoCtrl.text,
                    selectedQuiro?.idUsuario,
                  );

                  if (result is BloqueoAgenda) {
                    nuevoBloqueo = result;
                  } else if (result is String) {
                    apiError = result;
                  }
                }

                if (apiError != null) {
                  if (context.mounted) {
                    setState(() => _errorMessage = apiError);
                  }
                  return;
                }

                if (context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);

                  final isGlobal = selectedQuiro == null;
                  String mensaje;

                  // Formateo de fechas
                  String fechasStr;
                  if (fechaInicioReal.year == fechaFinReal.year &&
                      fechaInicioReal.month == fechaFinReal.month &&
                      fechaInicioReal.day == fechaFinReal.day) {
                    fechasStr =
                        "${fechaInicioReal.day}/${fechaInicioReal.month}";
                  } else {
                    fechasStr =
                        "${fechaInicioReal.day}/${fechaInicioReal.month} - ${fechaFinReal.day}/${fechaFinReal.month}";
                  }

                  if (isGlobal) {
                    mensaje =
                        esEdicion
                            ? "Bloqueo global actualizado ($fechasStr)"
                            : "Bloqueo global creado ($fechasStr)";
                  } else {
                    final nombre = selectedQuiro!.nombreCompleto;
                    final accion = esEdicion ? "actualizado" : "creado";
                    mensaje = "Bloqueo $accion para $nombre ($fechasStr)";
                  }

                  // Mostrar SnackBar con opción de Deshacer
                  CustomSnackBar.show(
                    context,
                    message: mensaje,
                    type: SnackBarType.success,
                    actionLabel: "DESHACER",
                    onAction: () async {
                      try {
                        if (esEdicion) {
                          // DESHACER EDICIÓN: Restaurar valores originales
                          final original = widget.bloqueoEditar!;
                          await bloqueoProvider.editarBloqueo(
                            original.idBloqueo,
                            original.fechaInicio,
                            original.fechaFin,
                            original.motivo,
                            original.idQuiropractico,
                          );
                        } else {
                          // DESHACER CREACIÓN: Borrar el nuevo
                          if (nuevoBloqueo != null) {
                            await bloqueoProvider.borrarBloqueo(
                              nuevoBloqueo.idBloqueo,
                            );
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
                          message: "Error al cancelar: ${e.toString()}",
                          type: SnackBarType.error,
                        );
                      }
                    },
                  );
                }
              } on BloqueoConflictException catch (e) {
                if (e.code == 'CONFLICTO_BLOQUEO_INDIVIDUAL' &&
                    context.mounted) {
                  final conflicting =
                      bloqueoProvider.bloqueos.where((b) {
                        final overlap =
                            b.fechaInicio.isBefore(fechaFinReal) &&
                            b.fechaFin.isAfter(fechaInicioReal);
                        final userMatch =
                            (selectedQuiro == null) ||
                            (b.idQuiropractico == selectedQuiro?.idUsuario) ||
                            (b.idQuiropractico == null);
                        return overlap && userMatch;
                      }).toList();

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.amber[800],
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  "Conflicto de Agenda",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),

                                if (conflicting.isNotEmpty) ...[
                                  Text(
                                    conflicting.length == 1
                                        ? "Se eliminará el siguiente bloqueo:"
                                        : "Se eliminarán los siguientes bloqueos:",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 150,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.red.shade100,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children:
                                            conflicting.map((b) {
                                              final nombre =
                                                  b.nombreQuiropractico;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.block,
                                                      size: 16,
                                                      color: Colors.red,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            nombre,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                          Text(
                                                            "Motivo: ${b.motivo}",
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          Text(
                                                            "${b.fechaInicio.day}/${b.fechaInicio.month} - ${b.fechaFin.day}/${b.fechaFin.month}",
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    "Conflicto con bloqueo existente reconocido por el servidor.",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),
                                Text(
                                  e.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 25),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: const Text(
                                          "Cancelar",
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                        child: const Text(
                                          "Sobrescribir",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      // Reintentar con force=true
                      final result = await bloqueoProvider.crearBloqueo(
                        fechaInicioReal,
                        fechaFinReal,
                        motivoCtrl.text,
                        selectedQuiro?.idUsuario,
                        force: true,
                      );

                      if (context.mounted) {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);

                        BloqueoAgenda? nuevoGlobal;
                        if (result is BloqueoAgenda) {
                          nuevoGlobal = result;
                        }

                        CustomSnackBar.show(
                          context,
                          message: "Conflictos resueltos y bloqueo creado",
                          type: SnackBarType.success,
                          actionLabel: "DESHACER",
                          onAction: () async {
                            // 1. Borrar el global creado
                            if (nuevoGlobal != null) {
                              await bloqueoProvider.borrarBloqueo(
                                nuevoGlobal.idBloqueo,
                              );
                            }

                            // 2. Restaurar los conflictos previos
                            for (final b in conflicting) {
                              await bloqueoProvider.crearBloqueo(
                                b.fechaInicio,
                                b.fechaFin,
                                b.motivo,
                                b.idQuiropractico,
                                force:
                                    true, // Force por seguridad, aunque no deberia haber conflicto ya
                              );
                            }

                            messenger.hideCurrentSnackBar();
                            CustomSnackBar.show(
                              context,
                              messenger: messenger,
                              message:
                                  "Cambios cancelados y bloqueos restaurados",
                              type: SnackBarType.info,
                            );
                          },
                        );
                      }
                    } catch (forceEx) {
                      if (context.mounted) {
                        setState(() => _errorMessage = forceEx.toString());
                      }
                    }
                  }
                } else {
                  // Otros errores bloqueantes
                  if (context.mounted) {
                    setState(() => _errorMessage = e.message);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  setState(() => _errorMessage = e.toString());
                }
              }
            }
          },
          child: Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
