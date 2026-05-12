import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:quiropractico_front/utils/format_utils.dart';

/// Pestaña "Almacenamiento" del módulo de configuración.
///
/// Muestra el uso de cuota de Cloud Storage (R2) de la clínica de forma dinámica.
class StorageTab extends StatelessWidget {
  const StorageTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int usado = context
        .select<SettingsProvider, int>((p) => p.almacenamientoUsadoBytes);
    final int limite = context
        .select<SettingsProvider, int>((p) => p.limiteAlmacenamientoBytes);

    // Cálculo de porcentaje con protección contra división por cero
    final double porcentaje =
        (limite > 0) ? (usado / limite).clamp(0.0, 1.0) : 0.0;

    // Tarea 2: Lógica de colores basada en reglas de negocio
    Color colorProgreso;
    if (porcentaje >= 0.95) {
      colorProgreso = Colors.red;
    } else if (porcentaje >= 0.80) {
      colorProgreso = Colors.orange;
    } else {
      colorProgreso = const Color(0xFF0EA5E9);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Almacenamiento y Cuotas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestiona el espacio utilizado por los documentos médicos de tus pacientes.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Tarea 3: Tarjeta de consumo con diseño Premium
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: Resumen y Porcentaje
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Has usado ${FormatUtils.formatBytes(usado)} de ${FormatUtils.formatBytes(limite)} disponibles',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${(porcentaje * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorProgreso,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barra de progreso refactorizada
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: porcentaje,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorProgreso,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: colorProgreso.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Mensaje de Alerta (Fuera de la Row superior)
                if (porcentaje >= 0.8) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorProgreso.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colorProgreso,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            porcentaje >= 0.95
                                ? 'Crítico: Has alcanzado casi el límite de tu plan. Contacta con soporte para ampliar tu cuota.'
                                : 'Atención: Tu almacenamiento está próximo a llenarse.',
                            style: TextStyle(
                              color: colorProgreso,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Pie de tarjeta: Info adicional
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
