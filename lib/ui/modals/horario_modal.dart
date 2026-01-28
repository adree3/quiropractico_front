import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/models/horario.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class HorarioModal extends StatefulWidget {
  final int? initialDay;
  final Horario? horarioToEdit;

  const HorarioModal({super.key, this.initialDay, this.horarioToEdit});

  @override
  State<HorarioModal> createState() => _HorarioModalState();
}

class _HorarioModalState extends State<HorarioModal> {
  int selectedDia = 1;
  TimeOfDay horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay horaFin = const TimeOfDay(hour: 14, minute: 0);

  String? diaError;
  String? horaError;
  String? globalMessage;

  @override
  void initState() {
    super.initState();
    if (widget.horarioToEdit != null) {
      final h = widget.horarioToEdit!;
      selectedDia = h.diaSemana;
      horaInicio = TimeOfDay(
        hour: h.horaInicio.hour,
        minute: h.horaInicio.minute,
      );
      horaFin = TimeOfDay(hour: h.horaFin.hour, minute: h.horaFin.minute);
    } else if (widget.initialDay != null) {
      selectedDia = widget.initialDay!;
    }
  }

  final List<Map<String, dynamic>> diasSemana = [
    {'id': 1, 'label': 'Lunes'},
    {'id': 2, 'label': 'Martes'},
    {'id': 3, 'label': 'Miércoles'},
    {'id': 4, 'label': 'Jueves'},
    {'id': 5, 'label': 'Viernes'},
    {'id': 6, 'label': 'Sábado'},
    {'id': 7, 'label': 'Domingo'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HorariosProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        widget.horarioToEdit != null ? 'Editar Turno' : 'Añadir Turno',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DÍA SEMANA
            DropdownButtonFormField<int>(
              value: selectedDia,
              items:
                  diasSemana
                      .map(
                        (d) => DropdownMenuItem<int>(
                          value: d['id'],
                          child: Text(d['label']),
                        ),
                      )
                      .toList(),
              onChanged:
                  (val) => setState(() {
                    selectedDia = val!;
                    diaError = null;
                  }),
              decoration: InputDecoration(
                labelText: 'Día de la Semana',
                prefixIcon: const Icon(Icons.calendar_today),
                errorText: diaError,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // HORAS
            Row(
              children: [
                Expanded(
                  child: _TimeInput(
                    label: "Inicio",
                    time: horaInicio,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: horaInicio,
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => horaInicio = picked);
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _TimeInput(
                    label: "Fin",
                    time: horaFin,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: horaFin,
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => horaFin = picked);
                    },
                  ),
                ),
              ],
            ),

            if (horaError != null) ...[
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
                        horaError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              diaError = null;
              horaError = null;
              globalMessage = null;
            });

            final startMinutes = horaInicio.hour * 60 + horaInicio.minute;
            final endMinutes = horaFin.hour * 60 + horaFin.minute;
            if (endMinutes <= startMinutes) {
              setState(() {
                horaError = 'La hora fin debe ser mayor a inicio';
              });
              return;
            }

            final messenger = ScaffoldMessenger.of(context);
            Map<String, dynamic> result;

            if (widget.horarioToEdit != null) {
              // --- EDICIÓN ---
              // Guardamos estado anterior para Deshacer
              final backupDia = widget.horarioToEdit!.diaSemana;
              final backupInicio = widget.horarioToEdit!.horaInicio;
              final backupFin = widget.horarioToEdit!.horaFin;
              final backupId = widget.horarioToEdit!.idHorario;

              result = await provider.updateHorario(
                backupId,
                selectedDia,
                horaInicio,
                horaFin,
              );

              if (context.mounted) {
                if (result['success'] == true) {
                  Navigator.pop(context);
                  CustomSnackBar.show(
                    context,
                    message:
                        'Turno del ${diasSemana.firstWhere((d) => d['id'] == selectedDia)['label']} editado',
                    type: SnackBarType.success,
                    actionLabel: "DESHACER",
                    onAction: () async {
                      messenger.hideCurrentSnackBar();
                      try {
                        await provider.updateHorario(
                          backupId,
                          backupDia,
                          backupInicio,
                          backupFin,
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
                        // Manejo de error silencioso o log
                      }
                    },
                  );
                } else {
                  _handleError(result);
                }
              }
            } else {
              // --- CREACIÓN ---
              result = await provider.createHorario(
                selectedDia,
                horaInicio,
                horaFin,
              );

              if (context.mounted) {
                if (result['success'] == true) {
                  Navigator.pop(context);

                  // Intentamos obtener ID para deshacer (borrar)
                  final createdData = result['data'];
                  final int? createdId =
                      createdData != null && createdData is Map
                          ? createdData['idHorario']
                          : null;

                  final diaLabel =
                      diasSemana.firstWhere(
                        (d) => d['id'] == selectedDia,
                        orElse: () => {'label': 'Día'},
                      )['label'];
                  final timeRange =
                      "${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')} - ${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}";

                  CustomSnackBar.show(
                    context,
                    message: 'Turno creado: $diaLabel $timeRange',
                    type: SnackBarType.success,
                    actionLabel: createdId != null ? "DESHACER" : null,
                    onAction:
                        createdId == null
                            ? null
                            : () async {
                              messenger.hideCurrentSnackBar();
                              try {
                                await provider.deleteHorario(createdId);
                                if (context.mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    messenger: messenger,
                                    message:
                                        "Creación deshecha (turno eliminado)",
                                    type: SnackBarType.info,
                                  );
                                }
                              } catch (e) {
                                // Log
                              }
                            },
                  );
                } else {
                  _handleError(result);
                }
              }
            }
          },
          child: Text(widget.horarioToEdit != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  void _handleError(Map<String, dynamic> result) {
    final code = result['code'];
    final msg = result['message'];

    setState(() {
      if (code == 'CONFLICTO_DIA') {
        diaError = msg;
      } else if (code == 'CONFLICTO_HORA') {
        horaError = msg;
      } else {
        horaError = msg ?? 'Error desconocido';
      }
    });
  }
}

class _TimeInput extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeInput({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
