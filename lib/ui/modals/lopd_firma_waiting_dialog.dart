import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/services/local_storage.dart';

/// Modal reactivo de espera de firma LOPD con la misma estética y layout que CitaCompletarDialog
class LopdFirmaWaitingDialog extends StatefulWidget {
  final int idCliente;
  final String? nombreCliente;

  const LopdFirmaWaitingDialog({
    super.key,
    required this.idCliente,
    this.nombreCliente,
  });

  @override
  State<LopdFirmaWaitingDialog> createState() => _LopdFirmaWaitingDialogState();
}

class _LopdFirmaWaitingDialogState extends State<LopdFirmaWaitingDialog> {
  bool _isSigned = false;
  bool _showReloadFeedback = false;
  String? _errorMessage;

  StompClient? _stompClient;
  Timer? _closeTimer;
  Timer? _pollingTimer;

  ClientDetailProvider? _detailProvider;
  VoidCallback? _detailListener;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _iniciarPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _conectarClientDetailProvider();
      _solicitarFirmaTablet();
    });
  }

  void _initWebSocket() {
    final token = LocalStorage.getToken();
    final String wsUrl = ApiConfig.wsUrl;

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          _stompClient?.subscribe(
            destination: '/topic/clientes',
            callback: _handleWsMessage,
          );
          _stompClient?.subscribe(
            destination: '/topic/kiosk',
            callback: _handleWsMessage,
          );
        },
        reconnectDelay: const Duration(seconds: 3),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        onWebSocketError: (error) => debugPrint('WS Error en LopdWaitingDialog: $error'),
      ),
    );
    _stompClient?.activate();
  }

  void _handleWsMessage(StompFrame frame) {
    if (frame.body == null || !mounted || _isSigned) return;
    try {
      final data = json.decode(frame.body!);
      final action = data['action'];

      if (action == 'LOPD_FIRMADA' ||
          action == 'CLIENTE_LOPD_FIRMADA' ||
          action == 'FIRMA_LOPD_EXITOSA') {
        final dynamic rawId = data['idCliente'] ?? data['clienteId'] ?? data['id'];
        final int? idClienteFirmado = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

        if (idClienteFirmado == null || idClienteFirmado == widget.idCliente) {
          _completarFirma();
        }
      }
    } catch (e) {
      debugPrint('Error procesando WS en LopdFirmaWaitingDialog: $e');
    }
  }

  void _conectarClientDetailProvider() {
    try {
      _detailProvider = Provider.of<ClientDetailProvider>(context, listen: false);
      _detailListener = () {
        if (!mounted || _isSigned) return;
        if (_detailProvider?.cliente?.idCliente == widget.idCliente &&
            _detailProvider?.cliente?.lopdFirmada == true) {
          _completarFirma();
        }
      };
      _detailProvider?.addListener(_detailListener!);
    } catch (_) {
      _detailProvider = null;
    }
  }

  void _iniciarPolling() {
    // Red de seguridad por si el WebSocket tiene cortes temporales
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isSigned) {
        timer.cancel();
        return;
      }
      try {
        final response = await ApiService.dio.get('/clientes/${widget.idCliente}');
        if (response.data != null && response.data['lopdFirmada'] == true) {
          timer.cancel();
          _completarFirma();
        }
      } catch (_) {}
    });
  }

  Future<void> _solicitarFirmaTablet() async {
    if (!mounted) return;
    setState(() {
      _showReloadFeedback = true;
      _errorMessage = null;
    });

    String? error;
    try {
      if (_detailProvider != null) {
        error = await _detailProvider!.solicitarFirmaLopd(widget.idCliente);
      } else {
        final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
        error = await clientsProvider.solicitarFirmaLopd(widget.idCliente);
      }
    } catch (e) {
      error = e.toString();
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _showReloadFeedback = false;
      _errorMessage = error;
    });
  }

  void _completarFirma() {
    if (!mounted || _isSigned) return;
    _pollingTimer?.cancel();

    setState(() {
      _isSigned = true;
      _errorMessage = null;
    });

    // Actualizar datos locales en los providers
    try {
      final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
      clientsProvider.reloadClient(widget.idCliente);
    } catch (_) {}

    try {
      if (_detailProvider != null) {
        _detailProvider!.marcarLopdFirmada();
        _detailProvider!.refreshCliente(silent: true);
      }
    } catch (_) {}

    // Auto-cierre con true tras 2 segundos
    _closeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _pollingTimer?.cancel();
    if (_detailProvider != null && _detailListener != null) {
      try {
        _detailProvider!.removeListener(_detailListener!);
      } catch (_) {}
    }
    _stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _isSigned ? Icons.check_circle_outline : Icons.assignment_turned_in_rounded,
            color: _isSigned ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Consentimiento LOPD #${widget.idCliente}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.nombreCliente != null && widget.nombreCliente!.trim().isNotEmpty) ...[
                Text(
                  'Paciente: ${widget.nombreCliente}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(height: 30),
              ],

              // SECCIÓN TABLET / FIRMA (estilo exacto de CitaCompletarDialog)
              _buildTabletStatus(),

              const SizedBox(height: 20),

              // SECCIÓN INFORMACIÓN DEL DOCUMENTO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 22,
                      color: Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documento de Protección de Datos (RGPD / LOPD)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSigned
                                ? 'Firma digital capturada con éxito en el Kiosco. El documento oficial ha sido generado y archivado.'
                                : 'El borrador del documento LOPD ha sido enviado al Kiosco/Tablet para su lectura y firma.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            const Spacer(),
            if (_isSigned)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Listo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
              )
            else
              TextButton.icon(
                icon: Icon(
                  _showReloadFeedback ? Icons.check_circle : Icons.refresh,
                  size: 18,
                  color: _showReloadFeedback ? Colors.green : AppTheme.primaryColor,
                ),
                label: Text(
                  _showReloadFeedback ? 'Señal enviada' : 'Reenviar señal',
                  style: TextStyle(
                    color: _showReloadFeedback ? Colors.green : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showReloadFeedback ? null : _solicitarFirmaTablet,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSigned ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isSigned ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isSigned
                  ? Icons.verified_rounded
                  : (_showReloadFeedback ? Icons.sync : Icons.tablet_android_rounded),
              key: ValueKey(_isSigned ? 'signed' : (_showReloadFeedback ? 'sync' : 'tablet')),
              color: _isSigned ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSigned ? '¡Firma del paciente recibida!' : 'Esperando firma en Tablet...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isSigned ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                if (!_isSigned)
                  const Text(
                    'El paciente verá el documento automáticamente en el Kiosco.',
                    style: TextStyle(fontSize: 12),
                  )
                else
                  const Text(
                    'Cerrando automáticamente en breve...',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
          ),
          if (!_isSigned)
            IconButton(
              tooltip: 'Reenviar señal',
              icon: Icon(
                _showReloadFeedback ? Icons.check_circle : Icons.refresh,
                size: 20,
                color: _showReloadFeedback ? Colors.green : Colors.blueGrey,
              ),
              onPressed: _showReloadFeedback ? null : _solicitarFirmaTablet,
            ),
        ],
      ),
    );
  }
}
