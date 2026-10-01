import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/consumo_bono.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/providers/bonos_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class BonoDetalleModal extends StatefulWidget {
  final BonoHistorico bono;
  final int? resaltarCitaId;

  const BonoDetalleModal({
    super.key,
    required this.bono,
    this.resaltarCitaId,
  });

  /// Abre el Slide-over Panel lateral derecho
  static Future<void> show(
    BuildContext context, {
    required BonoHistorico bono,
    int? resaltarCitaId,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar panel de bono',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: SizedBox(
              width: 500,
              height: double.infinity,
              child: BonoDetalleModal(
                bono: bono,
                resaltarCitaId: resaltarCitaId,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        );
      },
    );
  }

  @override
  State<BonoDetalleModal> createState() => _BonoDetalleModalState();
}

class _BonoDetalleModalState extends State<BonoDetalleModal> {
  bool _isLoading = true;
  List<ConsumoBono> _consumos = [];
  String? _errorMessage;
  late BonoHistorico _bono;
  bool _isConfirmingPayment = false;
  bool _isLoadingCita = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bono = widget.bono;
    _loadConsumos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConsumos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.dio.get(
        '${ApiConfig.baseUrl}/bonos/${_bono.idBonoActivo}/consumos',
      );

      if (response.data is List && mounted) {
        setState(() {
          _consumos = (response.data as List)
              .map((e) => ConsumoBono.fromJson(e))
              .toList();
          
          _bono = _bono.copyWith(sesionesRestantes: _bono.sesionesTotales - _consumos.length);
          _isLoading = false;
        });

        if (widget.resaltarCitaId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToResaltado();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al cargar el historial: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _abrirDetalleCita(int idCita) async {
    if (_isLoadingCita) return;
    setState(() => _isLoadingCita = true);
    
    try {
      final response = await ApiService.dio.get('${ApiConfig.baseUrl}/citas/$idCita');
      final cita = Cita.fromJson(response.data);
      if (mounted) {
        setState(() => _isLoadingCita = false);
        final result = await showDialog(
          context: context,
          builder: (ctx) => CitaDetalleModal(cita: cita),
        );
        if (result == true && mounted) {
          _loadConsumos();
          Provider.of<BonosProvider>(context, listen: false).getHistorial(refresh: true, silent: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCita = false);
        CustomSnackBar.show(context, message: 'Error cargando cita', type: SnackBarType.error);
      }
    }
  }

  void _scrollToResaltado() {
    final targetIndex = _consumos.indexWhere(
      (c) => c.idCita == widget.resaltarCitaId,
    );

    if (targetIndex != -1 && _scrollController.hasClients) {
      final double estimatedItemHeight = 120.0;
      double targetScroll = (targetIndex * estimatedItemHeight) - 20.0;
      if (targetScroll < 0) targetScroll = 0;

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmarCobro() async {
    if (_bono.idPago == null) return;
    
    setState(() => _isConfirmingPayment = true);

    try {
      final paymentsProvider = Provider.of<PaymentsProvider>(context, listen: false);
      await paymentsProvider.confirmarPago(_bono.idPago!);
      
      if (mounted) {
        setState(() {
          _bono = _bono.copyWith(pagado: true);
          _isConfirmingPayment = false;
        });
        
        CustomSnackBar.show(
          context, 
          message: 'Pago confirmado correctamente.', 
          type: SnackBarType.success,
        );
        
        // Refrescar lista de bonos principal
        Provider.of<BonosProvider>(context, listen: false).getHistorial(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirmingPayment = false);
        CustomSnackBar.show(
          context, 
          message: 'Error al confirmar el cobro.', 
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _agendarCita() async {
    final partes = _bono.nombreCliente.trim().split(' ');
    final nombre = partes.isNotEmpty ? partes.first : _bono.nombreCliente;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    final clienteDummy = Cliente(
      idCliente: _bono.idCliente,
      nombre: nombre,
      apellidos: apellidos,
      telefono: '',
      activo: true,
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => CitaModal(preSelectedClient: clienteDummy),
    );

    if (resultado == true && mounted) {
      _loadConsumos(); // Recargar historial local
      Provider.of<BonosProvider>(context, listen: false).getHistorial(refresh: true);
    }
  }

  Future<void> _renovarBono() async {
    final partes = _bono.nombreCliente.trim().split(' ');
    final nombre = partes.isNotEmpty ? partes.first : _bono.nombreCliente;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    final clienteDummy = Cliente(
      idCliente: _bono.idCliente,
      nombre: nombre,
      apellidos: apellidos,
      telefono: '',
      activo: true,
    );

    final ventaExitosa = await showDialog<bool>(
      context: context,
      builder: (ctx) => VentaBonoModal(cliente: clienteDummy),
    );

    if (ventaExitosa == true && mounted) {
      Provider.of<BonosProvider>(context, listen: false).getHistorial(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ZONA 1: Header Fijo
          _buildZone1Header(),
          
          const Divider(height: 1, thickness: 1),
          
          // ZONA 2: Resumen y Caja
          _buildZone2Summary(),
          
          const Divider(height: 1, thickness: 1),
          
          // ZONA 3: Timeline de Consumos
          Expanded(
            child: _buildZone3Timeline(),
          ),
          
          const Divider(height: 1, thickness: 1),
          
          // ZONA 4: Footer Fijo Operativo
          _buildZone4Footer(),
        ],
      ),
    );
  }

  Widget _buildZone1Header() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.grey.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _bono.nombreServicio,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${_bono.idBonoActivo}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: "Ver detalles de ${_bono.nombreCliente}",
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/pacientes/${_bono.idCliente}');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarWidget(
                            nombreCompleto: _bono.nombreCliente,
                            id: _bono.idCliente,
                            radius: 16,
                            fontSize: 13,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _bono.nombreCliente,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.grey.shade600,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildZone2Summary() {
    final double progreso = _bono.sesionesTotales > 0 
        ? (_bono.sesionesTotales - _bono.sesionesRestantes) / _bono.sesionesTotales 
        : 0.0;
        
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saldo de Sesiones",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${_bono.sesionesTotales - _bono.sesionesRestantes}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: " consumidas / ${_bono.sesionesTotales} total",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bono.sesionesRestantes > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _bono.sesionesRestantes > 0 ? Colors.green.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  "${_bono.sesionesRestantes} Disponibles",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _bono.sesionesRestantes > 0 ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _bono.sesionesRestantes > 0 ? Colors.blue.shade500 : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Comprado", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_bono.fechaCompra),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ],
              ),
              if (_bono.fechaCaducidad != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Caducidad", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_bono.fechaCaducidad!),
                      style: TextStyle(
                        fontWeight: FontWeight.w500, 
                        fontSize: 13,
                        color: _bono.caducado ? Colors.red.shade700 : Colors.black87,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (_bono.monto != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bono.pagado ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _bono.pagado ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bono.pagado ? "Importe Abonado" : "Pendiente de Pago",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _bono.pagado ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_bono.monto!.toStringAsFixed(2)} €",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _bono.pagado ? Colors.green.shade800 : Colors.orange.shade900,
                        ),
                      ),
                      if (_bono.metodoPago != null && _bono.pagado)
                        Text(
                          "Método: ${_bono.metodoPago}",
                          style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                        ),
                    ],
                  ),
                  if (!_bono.pagado && _bono.idPago != null)
                    ElevatedButton.icon(
                      onPressed: _isConfirmingPayment ? null : _confirmarCobro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      icon: _isConfirmingPayment 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Confirmar Cobro"),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZone3Timeline() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 4,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade100,
                child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(width: 120, height: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_consumos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No hay consumos registrados",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: _consumos.length,
      itemBuilder: (context, index) {
        final consumo = _consumos[index];
        final isLast = index == _consumos.length - 1;
        final isResaltado = consumo.idCita == widget.resaltarCitaId;
        
        // Determinar el estado visual
        final isCompletada = consumo.estadoCita?.toLowerCase() == 'completada';
        
        Color iconColor = isCompletada ? Colors.green.shade600 : Colors.blue.shade600;
        IconData iconData = isCompletada ? Icons.check_circle_rounded : Icons.event_repeat_rounded;
        Color badgeColor = isCompletada ? Colors.green.shade50 : Colors.blue.shade50;
        Color badgeTextColor = isCompletada ? Colors.green.shade700 : Colors.blue.shade700;
        String badgeText = isCompletada ? 'Completada' : 'Programada';

        String horarioText = DateFormat('dd/MM/yyyy').format(consumo.fechaCita ?? consumo.fechaConsumo);
        if (consumo.fechaCita != null && consumo.fechaHoraFin != null) {
          horarioText += " • ${DateFormat('HH:mm').format(consumo.fechaCita!)} - ${DateFormat('HH:mm').format(consumo.fechaHoraFin!)}";
        } else if (consumo.fechaCita != null) {
          horarioText += " • ${DateFormat('HH:mm').format(consumo.fechaCita!)}";
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Line & Icon
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        boxShadow: isResaltado ? [
                          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                        ] : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Tooltip(
                      message: "Ver detalles de la cita",
                      waitDuration: const Duration(milliseconds: 400),
                      child: InkWell(
                        onTap: consumo.idCita != null ? () => _abrirDetalleCita(consumo.idCita!) : null,
                        borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isResaltado ? Colors.orange.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isResaltado ? Colors.orange.shade300 : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  horarioText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (consumo.idCita != null)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: badgeTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          "#${consumo.idCita}",
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Quiropráctico & Estado firma
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (consumo.nombreQuiropractico != null)
                                  Row(
                                    children: [
                                      Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Dr. ${consumo.nombreQuiropractico}",
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                // Firma (solo si está completada)
                                if (isCompletada)
                                  Row(
                                    children: [
                                      Icon(
                                        consumo.firmada ? Icons.draw : Icons.edit_off,
                                        size: 14,
                                        color: consumo.firmada ? Colors.green.shade600 : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        consumo.firmada ? "Firmada" : "Sin firmar",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: consumo.firmada ? Colors.green.shade700 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),

                            // Paciente (Familiar Check)
                            if (consumo.nombrePaciente != null)
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    consumo.nombrePaciente!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                  if (consumo.idPaciente != null && consumo.idPaciente != _bono.idCliente) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.purple.shade100),
                                      ),
                                      child: Text(
                                        "Familiar",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            
                            if (consumo.notasRecepcion != null && consumo.notasRecepcion!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  consumo.notasRecepcion!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (consumo.idCita != null)
                                  Row(
                                    children: [
                                      Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Ver cita",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox(),
                                Text(
                                  "Saldo tras uso: ${consumo.sesionesRestantesSnapshot}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildZone4Footer() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _agendarCita,
              icon: const Icon(Icons.calendar_month),
              label: const Text("Agendar Cita"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _renovarBono,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Renovar Bono"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
