import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';

class BloqueoModal extends StatefulWidget {
  const BloqueoModal({super.key});

  @override
  State<BloqueoModal> createState() => _BloqueoModalState();
}

class _BloqueoModalState extends State<BloqueoModal> {
  final _formKey = GlobalKey<FormState>();
  final motivoCtrl = TextEditingController();
  
  DateTime? start;
  DateTime? end;
  
  Usuario? selectedQuiro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agendaProv = Provider.of<AgendaProvider>(context, listen: false);
      if (agendaProv.quiropracticos.isEmpty) agendaProv.loadQuiropracticos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Registrar Ausencia / Festivo", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  ...agendaProvider.quiropracticos.map((u) => DropdownMenuItem(value: u, child: Text("Dr. ${u.nombreCompleto}"))),
                ],
                onChanged: (val) => setState(() => selectedQuiro = val),
              ),
              
              const SizedBox(height: 20),

              // ¿CUÁNDO?
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context, 
                    firstDate: DateTime.now(), 
                    lastDate: DateTime(2030),
                    locale: const Locale('es', 'ES')
                  );
                  if (picked != null) {
                    setState(() {
                      start = picked.start;
                      end = picked.end;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fechas',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    (start != null && end != null)
                        ? "${DateFormat('dd/MM/yyyy').format(start!)}  -  ${DateFormat('dd/MM/yyyy').format(end!)}"
                        : "Seleccionar rango de fechas",
                    style: TextStyle(
                      color: start == null ? Colors.grey : Colors.black87,
                      fontWeight: start == null ? FontWeight.normal : FontWeight.bold
                    ),
                  ),
                ),
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
              if (start == null || end == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes seleccionar las fechas"), backgroundColor: Colors.orange));
                return;
              }
              final fechaInicioReal = DateTime(start!.year, start!.month, start!.day, 0, 0, 0);
              final fechaFinReal = DateTime(end!.year, end!.month, end!.day, 23, 59, 59);

              final error = await bloqueoProvider.crearBloqueo(
                fechaInicioReal, 
                fechaFinReal, 
                motivoCtrl.text, 
                selectedQuiro?.idUsuario
              );

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bloqueo creado correctamente"), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            }
          },
          child: const Text('Guardar Bloqueo'),
        )
      ],
    );
  }
}