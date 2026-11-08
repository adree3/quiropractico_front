import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/arqueo_caja_dto.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/ui/widgets/fecha_picker_dialog.dart';

class ArqueoCajaDialog extends StatefulWidget {
  final DateTime? fecha;

  const ArqueoCajaDialog({
    super.key,
    this.fecha,
  });

  @override
  State<ArqueoCajaDialog> createState() => _ArqueoCajaDialogState();
}

class _ArqueoCajaDialogState extends State<ArqueoCajaDialog>
    with SingleTickerProviderStateMixin {
  static final NumberFormat _euroFormatter = NumberFormat('#,##0.00', 'es_ES');

  late AnimationController _pulseController;
  late Animation<Color?> _pulseColor;

  bool _isLoading = true;
  String? _error;
  ArqueoCajaDto? _arqueo;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _pulseColor = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _currentDate = widget.fecha ?? DateTime.now();
    _cargarArqueo();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cargarArqueo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    try {
      final data = await ApiService.obtenerArqueoDiario(fecha: _currentDate);
      if (mounted) {
        setState(() {
          _arqueo = data;
          _isLoading = false;
        });
        _pulseController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
        _pulseController.stop();
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => FechaPickerDialog(
        initialDate: _currentDate,
        colorTema: AppTheme.primaryColor,
        diasActivosSemana: const [1, 2, 3, 4, 5, 6, 7],
        bloqueos: const [],
      ),
    );

    if (picked != null) {
      setState(() {
        _currentDate = picked;
        _isLoading = true;
      });
      _cargarArqueo();
    }
  }

  bool get _esHoy {
    final now = DateTime.now();
    return _currentDate.year == now.year &&
        _currentDate.month == now.month &&
        _currentDate.day == now.day;
  }

  String get _titulo {
    if (_esHoy) {
      return "Arqueo de Caja - Hoy";
    }
    return "Arqueo de Caja - ${DateFormat('dd/MM/yyyy').format(_currentDate)}";
  }

  String _formatEuro(double valor) {
    return '${_euroFormatter.format(valor)} €';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera interactiva con selector de fecha
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _titulo,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pulsa para cambiar fecha',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Contenido dinámico envuelto en transición fluida
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBody(),
            ),

            // Botón de acción inferior (Únicamente "Cerrar")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    Widget content;
    if (_isLoading) {
      content = KeyedSubtree(
        key: const ValueKey('skeleton'),
        child: _buildSkeletonBody(),
      );
    } else if (_error != null) {
      content = KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildErrorBody(),
      );
    } else {
      content = KeyedSubtree(
        key: const ValueKey('content'),
        child: _buildContentBody(),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: content,
    );
  }

  Widget _skeletonBox({
    double? width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _pulseColor,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _pulseColor.value,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contenedor superior Skeleton: TOTAL RECAUDADO
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _skeletonBox(width: 120, height: 14, radius: 4),
              const SizedBox(height: 8),
              _skeletonBox(width: 170, height: 34, radius: 6),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Título de sección Skeleton
        _skeletonBox(width: 130, height: 12, radius: 4),
        const SizedBox(height: 10),

        // Fila 1: Efectivo
        _buildSkeletonRow(isDestacado: true),
        const SizedBox(height: 8),

        // Fila 2: Tarjeta
        _buildSkeletonRow(),
        const SizedBox(height: 8),

        // Fila 3: Transferencia
        _buildSkeletonRow(),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Línea inferior de operaciones Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _skeletonBox(width: 16, height: 16, radius: 4),
            const SizedBox(width: 8),
            _skeletonBox(width: 140, height: 12, radius: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonRow({bool isDestacado = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDestacado ? Colors.grey.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDestacado ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _skeletonBox(width: 32, height: 32, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: _skeletonBox(width: 120, height: 14, radius: 4),
          ),
          const SizedBox(width: 12),
          _skeletonBox(width: 65, height: 16, radius: 4),
        ],
      ),
    );
  }

  Widget _buildErrorBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            'No se pudo obtener el arqueo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _cargarArqueo,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    final arqueo = _arqueo ?? const ArqueoCajaDto(
      efectivo: 0,
      tarjeta: 0,
      transferencia: 0,
      total: 0,
      cantidadOperaciones: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contenedor superior destacado con el TOTAL
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              Text(
                'TOTAL RECAUDADO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatEuro(arqueo.total),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Desglose por método de cobro
        Text(
          'DESGLOSE POR MÉTODO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),

        // Fila 1: Efectivo (Dinero físico destacado)
        _buildMetodoRow(
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          label: 'Efectivo (Dinero Físico)',
          valor: arqueo.efectivo,
          isDestacado: true,
        ),

        const SizedBox(height: 8),

        // Fila 2: Tarjeta
        _buildMetodoRow(
          icon: Icons.credit_card_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          label: 'Tarjeta / TPV',
          valor: arqueo.tarjeta,
        ),

        const SizedBox(height: 8),

        // Fila 3: Transferencia
        _buildMetodoRow(
          icon: Icons.account_balance_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          label: 'Transferencia Bancaria',
          valor: arqueo.transferencia,
        ),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Texto sutil con la cantidad de operaciones
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              '${arqueo.cantidadOperaciones} ${arqueo.cantidadOperaciones == 1 ? "operación registrada" : "operaciones registradas"}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetodoRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required double valor,
    bool isDestacado = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDestacado ? const Color(0xFFF9FAFB) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isDestacado
            ? Border.all(color: Colors.green.shade200)
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isDestacado ? FontWeight.w700 : FontWeight.w500,
                color: isDestacado ? Colors.green.shade900 : const Color(0xFF334155),
              ),
            ),
          ),
          Text(
            _formatEuro(valor),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDestacado ? Colors.green.shade800 : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
