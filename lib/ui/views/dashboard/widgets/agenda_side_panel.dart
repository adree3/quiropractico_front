import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';

class AgendaSidePanel extends StatelessWidget {
  const AgendaSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context);
    final citas = provider.citas;

    // CÁLCULOS
    final totalCitas = citas.length;
    final completadas = citas.where((c) => c.estado == 'completada').length;
    final pendientes = citas.where((c) => c.estado == 'programada').length;
    final now = DateTime.now();
    final proximasCitas = citas.where((c) {
      final esHoy = c.fechaHoraInicio.day == now.day && c.fechaHoraInicio.month == now.month;
      return esHoy && c.fechaHoraFin.isAfter(now) && c.estado == 'programada';
    }).toList();
    
    // Ordenar por hora
    proximasCitas.sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO 
          const Text("Resumen del Día", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),

          // KPIS MINIATURA 
          Row(
            children: [
              Expanded(child: _MiniKpi(label: "Total", value: "$totalCitas", color: Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _MiniKpi(label: "Hechas", value: "$completadas", color: Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _MiniKpi(label: "Pendientes", value: "$pendientes", color: Colors.orange)),
            ],
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // PRÓXIMO PACIENTE 
          const Text("Siguiente en entrar:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          if (proximasCitas.isNotEmpty)
            _NextPatientCard(cita: proximasCitas.first)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No hay más citas programadas hoy", style: TextStyle(color: Colors.grey))),
            ),

          const SizedBox(height: 20),
          
          // COMING UP 
          if (proximasCitas.length > 1) ...[
            const Text("A continuación:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: proximasCitas.length - 1,
                separatorBuilder: (ctx, i) => const Divider(height: 15, color: Colors.black12), // Separador
                itemBuilder: (context, index) {
                  final cita = proximasCitas[index + 1];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(cita.fechaHoraInicio),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12),
                      ),
                    ),
                    title: Text(cita.nombreClienteCompleto, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text("Dr. ${cita.nombreQuiropractico}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// WIDGETS 

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniKpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _NextPatientCard extends StatelessWidget {
  final Cita cita;
  const _NextPatientCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.access_time_filled, color: Colors.white, size: 18),
              Text(
                "${DateFormat('HH:mm').format(cita.fechaHoraInicio)} - ${DateFormat('HH:mm').format(cita.fechaHoraFin)}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cita.nombreClienteCompleto,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Dr. ${cita.nombreQuiropractico}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}