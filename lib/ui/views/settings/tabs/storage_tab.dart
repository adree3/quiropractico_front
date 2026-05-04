import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';

/// Pestaña "Almacenamiento" del módulo de configuración.
///
/// Muestra el uso de cuota de Cloud Storage (R2) de la clínica:
/// - Barra de progreso visual (GB usados / GB totales)
/// - Porcentaje de uso con indicador de alerta al superar el 90%
class StorageTab extends StatelessWidget {
  const StorageTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    final double usedGb =
        provider.almacenamientoUsadoBytes / (1024 * 1024 * 1024);
    final double totalGb =
        provider.limiteAlmacenamientoBytes / (1024 * 1024 * 1024);
    final double percentage = provider.limiteAlmacenamientoBytes > 0
        ? provider.almacenamientoUsadoBytes / provider.limiteAlmacenamientoBytes
        : 0;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uso de Cuota',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Controla el espacio utilizado por los documentos médicos de tus pacientes.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 40),

          // Card de uso
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${usedGb.toStringAsFixed(2)} GB usados de ${totalGb.toStringAsFixed(2)} GB',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 0.9
                          ? Colors.red
                          : const Color(0xFF0EA5E9),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Si superas el límite, no podrás subir nuevas resonancias o documentos.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
