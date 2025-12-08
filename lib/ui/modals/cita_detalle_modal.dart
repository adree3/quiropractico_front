import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas bonitas
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/modals/clinica_note_modal.dart';

class CitaDetalleModal extends StatelessWidget {
  final Cita cita;

  const CitaDetalleModal({super.key, required this.cita});

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
    final dateFormat = DateFormat('HH:mm');

    Color colorEstado;
    switch (cita.estado) {
      case 'completada': colorEstado = Colors.green; break;
      case 'cancelada': colorEstado = Colors.red; break;
      case 'ausente': colorEstado = Colors.grey; break;
      default: colorEstado = Colors.blue;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colorEstado, width: 2), 
      ),
      title: Row(
        children: [
          const Text('Detalle de Cita'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: colorEstado)
            ),
            child: Text(cita.estado.toUpperCase(), style: TextStyle(color: colorEstado, fontSize: 12)),
          )
        ],
      ),
      content: SizedBox(
        width: AppTheme.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de información
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!)
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person, label: "Paciente", value: cita.nombreClienteCompleto),
                  const Divider(height: 20),
                  _InfoRow(icon: Icons.phone, label: "Telefono", value: cita.telefonoCliente),
                  const Divider(height: 20),
                  _InfoRow(icon: Icons.payment, label: "Método de Pago", value: cita.infoPago),
                  const Divider(height: 20),
                  _InfoRow(icon: Icons.medical_services, label: "Doctor", value: cita.nombreQuiropractico),
                  const Divider(height: 20),
                  _InfoRow(icon: Icons.access_time, label: "Horario", value: "${dateFormat.format(cita.fechaHoraInicio)} - ${dateFormat.format(cita.fechaHoraFin)}"),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Notas:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                (cita.notas != null && cita.notas!.isNotEmpty) ? cita.notas! : "Sin notas adicionales.",
                style: const TextStyle(color: Colors.black87),
              ),
            )
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cerrar', style: TextStyle(color: Colors.grey))
        ),

        if (cita.estado == 'programada') ...[
          IconButton(
            tooltip: 'Editar detalles',
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => CitaModal(citaExistente: cita), // Abrir edición
              );
            },
          ),

          /*if (cita.estado != 'cancelada')
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); 
              showDialog(
                context: context,
                builder: (_) => ClinicalNoteModal(
                  idCita: cita.idCita,
                  pacienteNombre: cita.nombreClienteCompleto,
                )
              );
            },
            icon: const Icon(Icons.description, size: 18),
            label: const Text("Notas S.O.A.P."),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          ),
          */
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: const Text("¿Cancelar cita?"),
                  content: const Text("Esta acción liberará el hueco en la agenda."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Volver")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true), 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Sí, cancelar")
                    ),
                  ],
                )
              );

              if (confirm == true) {
                await agendaProvider.cancelarCita(cita.idCita);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await agendaProvider.cambiarEstadoCita(cita.idCita, 'ausente');
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.person_off_outlined, size: 18),
            label: const Text('Ausente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await agendaProvider.cambiarEstadoCita(cita.idCita, 'completada');
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        if (cita.estado == 'ausente')
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => CitaModal(citaExistente: cita),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar / Justificar'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
          ),
        if (cita.estado == 'cancelada') 
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                builder: (context) => CitaModal(selectedDate: cita.fechaHoraInicio),
              );
            },
            icon: const Icon(Icons.event_available, size: 18),
            label: const Text('Reutilizar Hueco'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),

        if (cita.estado == 'completada')
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                builder: (context) => CitaModal(citaExistente: cita),
              );
            },
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Editar / Reabrir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!)
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        )
      ],
    );
  }
}