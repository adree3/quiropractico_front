import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class HorarioModal extends StatefulWidget {
  const HorarioModal({super.key});

  @override
  State<HorarioModal> createState() => _HorarioModalState();
}

class _HorarioModalState extends State<HorarioModal> {
  int selectedDia = 1;
  TimeOfDay horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay horaFin = const TimeOfDay(hour: 14, minute: 0);

  final List<Map<String, dynamic>> diasSemana = [
    {'id': 1, 'label': 'Lunes'}, {'id': 2, 'label': 'Martes'},
    {'id': 3, 'label': 'Miércoles'}, {'id': 4, 'label': 'Jueves'},
    {'id': 5, 'label': 'Viernes'}, {'id': 6, 'label': 'Sábado'}, {'id': 7, 'label': 'Domingo'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HorariosProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Añadir Turno', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DÍA SEMANA
            DropdownButtonFormField<int>(
              value: selectedDia,
              decoration: const InputDecoration(labelText: 'Día de la Semana', prefixIcon: Icon(Icons.calendar_today)),
              items: diasSemana.map((d) => DropdownMenuItem<int>(value: d['id'], child: Text(d['label']))).toList(),
              onChanged: (val) => setState(() => selectedDia = val!),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final startMinutes = horaInicio.hour * 60 + horaInicio.minute;
            final endMinutes = horaFin.hour * 60 + horaFin.minute;
            if (endMinutes <= startMinutes) {
              CustomSnackBar.show(context, 
                message: 'La hora fin debe ser mayor a inicio', 
                type: SnackBarType.info
              );
              return;
            }

            final String? error = await provider.createHorario(selectedDia, horaInicio, horaFin);

            if (context.mounted) {
              if (error == null) {
                Navigator.pop(context);
                CustomSnackBar.show(context, 
                  message: 'Turno añadido', 
                  type: SnackBarType.error
                );
              } else {
                CustomSnackBar.show(context, 
                  message: error, 
                  type: SnackBarType.error
                );
              }
            }
          },
          child: const Text('Guardar Turno'),
        ),
      ],
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeInput({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(
          "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}