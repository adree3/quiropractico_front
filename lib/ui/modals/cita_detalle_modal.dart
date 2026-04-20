import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/modals/cita_completar_dialog.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/config/api_config.dart';

// ──────────────────────────────────────────────────────────
// Helpers de estado
// ──────────────────────────────────────────────────────────
Color _colorForEstado(String estado) {
  switch (estado.toLowerCase()) {
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
  switch (estado.toLowerCase()) {
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
  switch (estado.toLowerCase()) {
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
class CitaDetalleModal extends StatefulWidget {
  final Cita cita;

  const CitaDetalleModal({super.key, required this.cita});

  @override
  State<CitaDetalleModal> createState() => _CitaDetalleModalState();
}

class _CitaDetalleModalState extends State<CitaDetalleModal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _mostrarError(BuildContext context, String mensaje) {
    CustomSnackBar.show(context, message: mensaje, type: SnackBarType.error);
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    AgendaProvider provider,
    String nuevoEstado,
  ) async {
    final error = await provider.cambiarEstadoCita(widget.cita.idCita, nuevoEstado);
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
    final error = await provider.cancelarCita(widget.cita.idCita);
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
                          dateFormat.format(widget.cita.fechaHoraInicio),
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
    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final currentUser = usersProvider.currentUser;
    final isAuthorized = currentUser?.rol == 'admin' || currentUser?.rol == 'quiropractico';

    final color = _colorForEstado(widget.cita.estado);
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

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                  '${dateFormat.format(widget.cita.fechaHoraInicio)} – ${timeFormat.format(widget.cita.fechaHoraFin)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  _iconForEstado(widget.cita.estado),
                                  color: color,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _labelForEstado(widget.cita.estado),
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
                              value: widget.cita.nombreClienteCompleto,
                              tooltip: 'Ver detalles del paciente',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/pacientes/${widget.cita.idCliente}');
                              },
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Teléfono',
                              value: widget.cita.telefonoCliente,
                              tooltip: 'Abrir Whatsapp',
                              onTap: () {
                                final url = 'https://wa.me/34${widget.cita.telefonoCliente.replaceAll(RegExp(r'[^\d]'), '')}';
                                launchUrl(Uri.parse(url));
                              },
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.medical_services_outlined,
                              label: 'Doctor',
                              value: widget.cita.nombreQuiropractico,
                              tooltip: isAuthorized ? 'Ver perfil doctor' : null,
                              onTap: isAuthorized 
                                ? () {
                                    context.push('/perfil/${widget.cita.idQuiropractico}');
                                  }
                                : null,
                            ),
                            _RowDivider(),
                            _InfoRow(
                              icon: Icons.payment_outlined,
                              label: 'Método de pago',
                              value: widget.cita.infoPago,
                              tooltip: 'Ver pago',
                              onTap: () {
                                Navigator.pop(context);
                                context.push(
                                  '/pacientes/${widget.cita.idBonoCliente ?? widget.cita.idCliente}?tabIndex=1&showBono=true&resaltarCitaId=${widget.cita.idCita}',
                                );
                              },
                            ),
                            if (widget.cita.estado.toLowerCase() == 'completada') ...[
                                _RowDivider(),
                                _InfoRow(
                                  icon: widget.cita.firmada ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
                                  label: 'Justificante firma',
                                  value: widget.cita.firmada ? 'Firmado' : 'Pendiente de firma',
                                  colorValue: widget.cita.firmada ? Colors.green : Colors.orange,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                              (widget.cita.notas != null && widget.cita.notas!.isNotEmpty)
                                  ? widget.cita.notas!
                                  : 'Sin notas adicionales.',
                              style: TextStyle(
                                color:
                                    (widget.cita.notas != null &&
                                            widget.cita.notas!.isNotEmpty)
                                        ? Colors.black87
                                        : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildImageGallery(context),

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
    final closeBtn = OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: const Text('Cerrar'),
    );

    switch (widget.cita.estado.toLowerCase()) {
      case 'programada':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _buildActionIconButton(
              tooltip: 'Cancelar',
              iconOutlined: Icons.cancel_outlined,
              color: Colors.red,
              onPressed: () => _cancelarCita(context, provider),
            ),
            const SizedBox(width: 8),
            _buildActionIconButton(
              tooltip: 'Ausente',
              iconOutlined: Icons.person_off_outlined,
              color: Colors.orange,
              onPressed: () => _cambiarEstado(context, provider, 'ausente'),
            ),
            const SizedBox(width: 8),
            _buildActionIconButton(
              tooltip: 'Completar Sesión',
              iconOutlined: Icons.check_circle_outline,
              color: Colors.green,
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => CitaCompletarDialog(cita: widget.cita),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            const Spacer(),
            _buildPrimaryButton(
              context: context,
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
          ],
        );

      case 'completada':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _buildPrimaryButton(
              context: context,
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
            if (!widget.cita.firmada) ...[
              const SizedBox(width: 8),
              _buildPrimaryButton(
                context: context,
                label: 'Solicitar Firma',
                icon: Icons.draw_outlined,
                backgroundColor: Colors.indigo,
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => CitaCompletarDialog(cita: widget.cita),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
            if (widget.cita.firmada && widget.cita.rutaJustificante != null) ...[
               const SizedBox(width: 8),
               _buildPrimaryButton(
                context: context,
                label: 'Ver PDF',
                icon: Icons.picture_as_pdf_outlined,
                backgroundColor: Colors.red.shade700,
                onPressed: () {
                   debugPrint('Abriendo PDF: ${widget.cita.rutaJustificante}');
                },
              ),
            ]
          ],
        );

      case 'ausente':
        return Row(
          children: [
            closeBtn,
            const Spacer(),
            _buildPrimaryButton(
              context: context,
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
          ],
        );

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
            const SizedBox(width: 12),
            _buildPrimaryButton(
              context: context,
              label: 'Reutilizar hueco',
              icon: Icons.event_available,
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder:
                      (context) =>
                          CitaModal(selectedDate: widget.cita.fechaHoraInicio),
                );
              },
            ),
          ],
        );

      default:
        return Row(children: [closeBtn]);
    }
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final docsProv = Provider.of<DocumentosProvider>(context, listen: false);

    return FutureBuilder<List<Documento>>(
      future: docsProv.getDocumentosCita(widget.cita.idCita),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data ?? [];
        final images = docs.where((d) => d.mimeType?.startsWith('image/') ?? false).toList();

        if (images.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Imágenes vinculadas (${images.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
               SizedBox(
                height: 112, // Un poco más para el scrollbar discreto
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.3)),
                      thickness: WidgetStateProperty.all(3),
                      radius: const Radius.circular(10),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: false,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.purple,
                            Colors.purple.withOpacity(0.1),
                          ],
                          stops: const [0.9, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12), // Espacio para el scrollbar
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final img = images[index];
                          final thumbnailUrl = '${ApiConfig.baseUrl}/documentos/${img.idDocumento}/thumbnail';
                          
                          return Tooltip(
                            message: 'Ver imagen',
                            child: InkWell(
                              onTap: () => _showFullScreenImage(context, img),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      thumbnailUrl,
                                      headers: ApiService.getAuthHeaders(),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, Documento doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                Provider.of<DocumentosProvider>(context, listen: false).getViewUrl(doc.idDocumento),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Error al cargar imagen', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required String tooltip,
    required IconData iconOutlined,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(iconOutlined, color: color, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────────────────
class _InfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? colorValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.tooltip,
    this.colorValue,
  });

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(widget.icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Tooltip(
                    message: widget.tooltip ?? '',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isHovering && widget.onTap != null
                            ? Colors.blue.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.colorValue ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
