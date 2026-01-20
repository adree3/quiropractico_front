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
                      );
                      if (picked != null) setState(() => horaFin = picked);
                    },
                  ),
                ),
              ],
            ),

            if (horaError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  horaError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

            Map<String, dynamic> result;
            if (widget.horarioToEdit != null) {
              // Actualizar
              result = await provider.updateHorario(
                widget.horarioToEdit!.idHorario,
                selectedDia,
                horaInicio,
                horaFin,
              );
            } else {
              // Crear
              result = await provider.createHorario(
                selectedDia,
                horaInicio,
                horaFin,
              );
            }

            if (context.mounted) {
              if (result['success'] == true) {
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  message:
                      widget.horarioToEdit != null
                          ? 'Turno actualizado'
                          : 'Turno añadido',
                  type: SnackBarType.success,
                );
              } else {
                final code = result['code'];
                final msg = result['message'];

                setState(() {
                  if (code == 'CONFLICTO_DIA') {
                    diaError = msg;
                  } else if (code == 'CONFLICTO_HORA') {
                    horaError = msg;
                  } else {
                    // Fallback: mostrar error debajo de las horas
                    horaError = msg ?? 'Error desconocido';
                  }
                });
              }
            }
          },
          child: Text(widget.horarioToEdit != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
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
