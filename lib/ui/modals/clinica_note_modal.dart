import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/historial_provider.dart';

class ClinicalNoteModal extends StatefulWidget {
  final int idCita;
  final String pacienteNombre;

  const ClinicalNoteModal({super.key, required this.idCita, required this.pacienteNombre});

  @override
  State<ClinicalNoteModal> createState() => _ClinicalNoteModalState();
}

class _ClinicalNoteModalState extends State<ClinicalNoteModal> {
  final _formKey = GlobalKey<FormState>();
  
  final sCtrl = TextEditingController();
  final oCtrl = TextEditingController();
  final aCtrl = TextEditingController();
  final pCtrl = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<HistorialProvider>(context, listen: false);
      final historial = await provider.getNotaPorCita(widget.idCita);

      if (historial != null) {
        sCtrl.text = historial.notasSubjetivo ?? '';
        oCtrl.text = historial.notasObjetivo ?? '';
        aCtrl.text = historial.ajustesRealizados ?? '';
        pCtrl.text = historial.planFuturo ?? '';
      }
      
      if (mounted) setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(child: Text("Historial: ${widget.pacienteNombre}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: "S - Subjetivo (Lo que dice el paciente)", color: Colors.blue),
                      _NoteInput(controller: sCtrl, hint: "Motivo de consulta, síntomas..."),
                      
                      const SizedBox(height: 15),
                      
                      _SectionHeader(title: "O - Objetivo (Lo que ves/palpas)", color: Colors.orange),
                      _NoteInput(controller: oCtrl, hint: "Inflamación, rango de movimiento..."),

                      const SizedBox(height: 15),
                      
                      _SectionHeader(title: "A - Análisis/Ajuste (Tratamiento)", color: Colors.green),
                      _NoteInput(controller: aCtrl, hint: "Ajuste dorsal, técnica usada..."),

                      const SizedBox(height: 15),
                      
                      _SectionHeader(title: "P - Plan (Futuro)", color: Colors.purple),
                      _NoteInput(controller: pCtrl, hint: "Hielo, ejercicios, próxima cita..."),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
        ElevatedButton.icon(
          onPressed: () async {
            final provider = Provider.of<HistorialProvider>(context, listen: false);
            final success = await provider.guardarNota(
              widget.idCita,
              sCtrl.text,
              oCtrl.text,
              aCtrl.text,
              pCtrl.text
            );

            if (context.mounted) {
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nota guardada correctamente"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar nota"), backgroundColor: Colors.red));
              }
            }
          },
          icon: const Icon(Icons.save),
          label: const Text("Guardar Historial"),
        )
      ],
    );
  }
}

// Widgets auxiliares para limpiar el código
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 4))
      ),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
    );
  }
}

class _NoteInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _NoteInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      minLines: 1,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(10),
      ),
    );
  }
}