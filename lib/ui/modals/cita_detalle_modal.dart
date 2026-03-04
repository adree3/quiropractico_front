import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

// ──────────────────────────────────────────────────────────
// Helpers de estado
// ──────────────────────────────────────────────────────────
Color _colorForEstado(String estado) {
  switch (estado) {
    case 'completada':
      return const Color(0xFF4CAF50);
    case 'cancelada':
      return const Color(0xFFE57373);
    case 'ausente':
      return const Color(0xFF9E9E9E);
    default:
      return AppTheme.primaryColor;
  }
}

IconData _iconForEstado(String estado) {
  switch (estado) {
    case 'completada':
      return Icons.check_circle_outline;
    case 'cancelada':
      return Icons.cancel_outlined;
    case 'ausente':
      return Icons.person_off_outlined;
    default:
      return Icons.event_available_outlined;
  }
}

String _labelForEstado(String estado) {
  switch (estado) {
    case 'completada':
      return 'Completada';
    case 'cancelada':
      return 'Cancelada';
    case 'ausente':
      return 'Ausente';
    default:
      return 'Programada';
  }
}

// ──────────────────────────────────────────────────────────
// Modal principal
// ──────────────────────────────────────────────────────────
class CitaDetalleModal extends StatelessWidget {
  final Cita cita;

  const CitaDetalleModal({super.key, required this.cita});

  void _mostrarError(BuildContext context, String mensaje) {
    CustomSnackBar.show(context, message: mensaje, type: SnackBarType.error);
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    AgendaProvider provider,
    String nuevoEstado,
  ) async {
    final error = await provider.cambiarEstadoCita(cita.idCita, nuevoEstado);
    if (context.mounted) {
      if (error == null) {
        Navigator.pop(context, true);
      } else {
        _mostrarError(context, error);
      }
    }
  }

  Future<void> _cancelarCita(
    BuildContext context,
    AgendaProvider provider,
  ) async {
    final error = await provider.cancelarCita(cita.idCita);
    if (context.mounted) {
      if (error == null) {
        Navigator.pop(context, true);
      } else {
        _mostrarError(context, error);
      }
    }
  }

  Future<void> _restaurarCita(
    BuildContext context,
    AgendaProvider provider,
  ) async {
    final confirm = await _mostrarDialogRestaurar(context);
    if (confirm == true && context.mounted) {
      await _cambiarEstado(context, provider, 'programada');
    }
  }

  Future<bool?> _mostrarDialogRestaurar(BuildContext context) {
    final color = _colorForEstado('programada');
    final dateFormat = DateFormat("d 'de' MMMM, HH:mm", 'es');

    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent bar izquierda simulado con un contenedor superior
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: color.withOpacity(0.06),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restore_outlined,
                            color: color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Restaurar cita',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateFormat.format(cita.fechaHoraInicio),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'La cita volverá al estado\u00a0"Programada"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Restaurar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgendaProvider>(context, listen: false);
    final color = _colorForEstado(cita.estado);
    final dateFormat = DateFormat("EEEE, d 'de' MMMM · HH:mm", 'es');
    final timeFormat = DateFormat('HH:mm');

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 560, maxWidth: 560),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Accent bar IZQUIERDA ────────────────────────────
              Container(
                width: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.35)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Contenido principal ────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalle de Cita',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateFormat.format(cita.fechaHoraInicio)} – ${timeFormat.format(cita.fechaHoraFin)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Badge estado
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _iconForEstado(cita.estado),
                                  color: color,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _labelForEstado(cita.estado),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Divider(height: 26),
                    ),

                    // Info rows
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Paciente',
                              value: cita.nombreClienteCompleto,
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Teléfono',
                              value: cita.telefonoCliente,
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.medical_services_outlined,
                              label: 'Doctor',
                              value: cita.nombreQuiropractico,
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.payment_outlined,
                              label: 'Método de pago',
                              value: cita.infoPago,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notas',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (cita.notas != null && cita.notas!.isNotEmpty)
                                  ? cita.notas!
                                  : 'Sin notas adicionales.',
                              style: TextStyle(
                                color:
                                    (cita.notas != null &&
                                            cita.notas!.isNotEmpty)
                                        ? Colors.black87
                                        : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Acciones
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                      child: _buildActions(context, provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AgendaProvider provider) {
    final closeBtn = TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
    );

    switch (cita.estado) {
      // ── PROGRAMADA ───────────────────────────────────────
      case 'programada':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            IconButton(
              tooltip: 'Editar cita',
              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
            const SizedBox(width: 4),
            _ActionButton(
              label: 'Ausente',
              icon: Icons.person_off_outlined,
              color: Colors.grey,
              onPressed: () => _cambiarEstado(context, provider, 'ausente'),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Cancelar',
              icon: Icons.cancel_outlined,
              color: AppTheme.errorColor,
              onPressed: () => _cancelarCita(context, provider),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Completar',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF4CAF50),
              onPressed: () => _cambiarEstado(context, provider, 'completada'),
            ),
          ],
        );

      // ── COMPLETADA ───────────────────────────────────────
      case 'completada':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _ActionButton(
              label: 'Editar / Reabrir',
              icon: Icons.edit_outlined,
              color: Colors.orange,
              outlined: true,
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
          ],
        );

      // ── AUSENTE ──────────────────────────────────────────
      case 'ausente':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _ActionButton(
              label: 'Editar / Justificar',
              icon: Icons.edit_outlined,
              color: Colors.orange,
              outlined: true,
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
          ],
        );

      // ── CANCELADA ────────────────────────────────────────
      case 'cancelada':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _ActionButton(
              label: 'Restaurar',
              icon: Icons.restore_outlined,
              color: AppTheme.primaryColor,
              outlined: true,
              onPressed: () => _restaurarCita(context, provider),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Reutilizar hueco',
              icon: Icons.event_available,
              color: AppTheme.primaryColor,
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder:
                      (context) =>
                          CitaModal(selectedDate: cita.fechaHoraInicio),
                );
              },
            ),
          ],
        );

      default:
        return Row(children: [closeBtn]);
    }
  }
}

// ──────────────────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.grey[200]);
  }
}

/// Botón de acción estandarizado para las acciones del modal
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );

    const vPad = EdgeInsets.symmetric(horizontal: 14, vertical: 11);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: vPad,
        ),
        child: content,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: vPad,
        elevation: 0,
      ),
      child: content,
    );
  }
}
