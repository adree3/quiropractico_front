import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quiropractico_front/models/cita.dart';

class WhatsappStatusBadge extends StatelessWidget {
  final Cita cita;
  final bool showText;

  const WhatsappStatusBadge({
    super.key,
    required this.cita,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (cita.confirmadaWhatsapp) {
      return Tooltip(
        message: "Confirmada por el paciente vía WhatsApp",
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showText ? 8 : 4,
            vertical: showText ? 4 : 2,
          ),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
                size: 14,
              ),
              if (showText) ...[
                const SizedBox(width: 6),
                const Text(
                  'Confirmada WA',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (cita.recordatorioEnviado) {
      return Tooltip(
        message: "Recordatorio 24h enviado por WhatsApp (pendiente de confirmar)",
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showText ? 8 : 4,
            vertical: showText ? 4 : 2,
          ),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_filled,
                color: Colors.blueGrey.shade400,
                size: 14,
              ),
              if (showText) ...[
                const SizedBox(width: 6),
                Text(
                  'Pendiente WA',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
