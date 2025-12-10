import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/horario_modal.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HorariosProvider>(context);

    return Column(
      children: [
        // CABECERA
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/configuracion')),
            const SizedBox(width: 10),
            const Text("Gestión de Horarios", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            
            // SELECTOR DE DOCTOR
            if (provider.doctores.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: DropdownButton<Usuario>(
                  value: provider.selectedDoctor,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.medical_services_outlined, color: AppTheme.primaryColor),
                  items: provider.doctores.map((u) => DropdownMenuItem(value: u, child: Text(u.nombreCompleto))).toList(),
                  onChanged: (val) => provider.selectDoctor(val!),
                ),
              ),
              
            const SizedBox(width: 20),
            
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const HorarioModal()),
              icon: const Icon(Icons.add_alarm),
              label: const Text("Añadir Turno"),
            )
          ],
        ),
        const SizedBox(height: 20),

        // CUERPO (DÍAS DE LA SEMANA)
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 50),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final diaNum = index + 1; // 1=Lunes
                    final nombreDia = _getDiaNombre(diaNum);
                    
                    final turnosDelDia = provider.horarios.where((h) => h.diaSemana == diaNum).toList();
                    turnosDelDia.sort((a, b) => (a.horaInicio.hour * 60 + a.horaInicio.minute).compareTo(b.horaInicio.hour * 60 + b.horaInicio.minute));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NOMBRE DEL DÍA
                            SizedBox(
                              width: 120,
                              child: Text(nombreDia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                            ),
                            
                            // LISTA DE TURNOS (CHIPS)
                            Expanded(
                              child: turnosDelDia.isEmpty 
                                  ? const Text("Sin turnos asignados", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                                  : Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: turnosDelDia.map((turno) => Chip(
                                        label: Text(turno.formattedRange, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.blue[50],
                                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                                        onDeleted: () async {
                                          final String? error = await provider.deleteHorario(turno.idHorario);
                                          if (context.mounted && error != null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(error), backgroundColor: Colors.red)
                                            );
                                          }
                                        },
                                      )).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getDiaNombre(int dia) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[dia - 1];
  }
}