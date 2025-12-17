import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/bloqueo_agenda.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

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
      if (agendaProv.quiropracticos.isEmpty) await agendaProv.loadQuiropracticos();
      
      if (widget.bloqueoEditar != null && widget.bloqueoEditar!.idQuiropractico != null) {
        try {
          setState(() {
            selectedQuiro = agendaProv.quiropracticos.firstWhere(
              (u) => u.idUsuario == widget.bloqueoEditar!.idQuiropractico
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
    final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(context, listen: false);
    final esEdicion = widget.bloqueoEditar != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(esEdicion ? "Editar Bloqueo" : "Registrar Ausencia", style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ¿QUIÉN?
              DropdownButtonFormField<Usuario?>(
                decoration: const InputDecoration(
                  labelText: 'Afectado',
                  prefixIcon: Icon(Icons.person_pin_circle_outlined),
                  helperText: 'Selecciona "Toda la Clínica" para festivos generales'
                ),
                value: selectedQuiro,
                items: [
                  const DropdownMenuItem(value: null, child: Text("🏢 TODA LA CLÍNICA (Cierre)")),
                  ...agendaProvider.quiropracticos.map((u) => DropdownMenuItem(value: u, child: Text(u.nombreCompleto))),
                ],
                onChanged: (val) => setState(() => selectedQuiro = val),
              ),
              
              const SizedBox(height: 20),

              // ¿CUÁNDO?
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Desde', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(start)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hasta', prefixIcon: Icon(Icons.event), border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(end)),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // ¿POR QUÉ?
              TextFormField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Ej: Vacaciones, Congreso, Festivo...',
                  prefixIcon: Icon(Icons.info_outline)
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final fechaInicioReal = DateTime(start.year, start.month, start.day, 0, 0, 0);
              final fechaFinReal = DateTime(end.year, end.month, end.day, 23, 59, 59);

              String? error;
              
              if (esEdicion) {
                error = await bloqueoProvider.editarBloqueo(
                  widget.bloqueoEditar!.idBloqueo,
                  fechaInicioReal,
                  fechaFinReal,
                  motivoCtrl.text,
                  selectedQuiro?.idUsuario
                );
              } else {
                error = await bloqueoProvider.crearBloqueo(
                  fechaInicioReal, 
                  fechaFinReal, 
                  motivoCtrl.text, 
                  selectedQuiro?.idUsuario
                );
              }

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  CustomSnackBar.show(context, 
                    message: esEdicion ? "Bloqueo actualizado" : "Bloqueo creado", 
                    type: SnackBarType.success
                  );
                } else {
                  CustomSnackBar.show(context, 
                    message: "Error: $error", 
                    type: SnackBarType.error
                  );
                }
              }
            }
          },
          child: Text(esEdicion ? 'Actualizar' : 'Crear'),
        )
      ],
    );
  }
}