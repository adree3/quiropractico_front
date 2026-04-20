import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class KioskView extends StatefulWidget {
  const KioskView({super.key});

  @override
  State<KioskView> createState() => _KioskViewState();
}

class _KioskViewState extends State<KioskView> {
  StompClient? _stompClient;
  bool _isSignatureMode = false;
  int? _currentCitaId;
  String? _pacienteNombre;
  String? _pdfUrl;
  String? _fecha;
  String? _horaInicio;
  String? _horaFin;
  bool _esBono = false;
  String? _infoBono;
  String? _idBono;
  bool _isSending = false;
  bool _hasSignature = false;
  bool _isSuccessState = false;
  String _pdfViewType = 'pdf-viewer-html';

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  late final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(_onSignatureChanged);
    _registerPdfFactory();
    _connectWebSocket();
    _startClock();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _onSignatureChanged() {
    if (_signatureController.isNotEmpty != _hasSignature) {
      setState(() {
        _hasSignature = _signatureController.isNotEmpty;
      });
    }
  }

  void _registerPdfFactory() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _pdfViewType,
      (int viewId) =>
          html.IFrameElement()
            ..src = _pdfUrl ?? ''
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
    );
  }

  void _connectWebSocket() {
    final String wsUrl = ApiConfig.baseUrl
        .replaceFirst('http', 'ws')
        .replaceAll('/api', '/ws-kiosk');

    final String? token = LocalStorage.getToken();

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onWebSocketError: (error) => print('WS Error: $error'),
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onDisconnect: (frame) => print('WS Disconnected'),
      ),
    );
    _stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    print('WebSocket Connected');
    _stompClient?.subscribe(
      destination: '/topic/kiosk',
      callback: (frame) {
        if (frame.body != null) {
          final data = json.decode(frame.body!);
          final action = data['action'];

          if (action == 'OPEN_SIGNATURE') {
            setState(() {
              _isSignatureMode = true;
              _currentCitaId = data['idCita'];
              _pacienteNombre = data['nombrePaciente'];
              _pdfUrl = data['urlPdf'];
              _fecha = data['fecha'];
              _horaInicio = data['horaInicio'];
              _horaFin = data['horaFin'];
              _esBono = data['esBono'] ?? false;
              _infoBono = data['infoBono'];
              _idBono = data['idBono'];
              _signatureController.clear();
              _hasSignature = false;
            });
            _registerPdfFactory();
          } else if (action == 'CLOSE_SIGNATURE') {
            // Si ya estamos enviando la firma o mostrando el éxito localmente, ignoramos el mensaje global de cierre
            if (!_isSuccessState && !_isSending) {
              setState(() {
                _isSignatureMode = false;
                _currentCitaId = null;
                _pdfUrl = null;
                _hasSignature = false;
              });
            }
          }
        }
      },
    );
  }

  Future<void> _enviarFirma() async {
    if (!_hasSignature) return;
    setState(() => _isSending = true);

    try {
      final Uint8List? signatureData = await _signatureController.toPngBytes();
      if (signatureData == null) return;

      final String base64Firma = base64Encode(signatureData);
      final response = await ApiService.dio.post(
        '/citas/$_currentCitaId/firmar',
        data: {'firmaBase64': base64Firma},
      );

      // Extraer la URL del PDF ya firmado
      final String? signedPdfUrl = response.data['signedPdfUrl'];

      if (mounted) {
        setState(() {
          _isSuccessState = true;
          if (signedPdfUrl != null) {
            _pdfUrl = signedPdfUrl;
          }
        });
        
        // Refrescar el iFrame con el PDF firmado (Usando un nuevo ID de vista para forzar recarga)
        _pdfViewType = 'pdf-viewer-html-${DateTime.now().millisecondsSinceEpoch}';
        _registerPdfFactory();

        // Esperar 5 segundos para que el paciente vea su firma estampada
        await Future.delayed(const Duration(seconds: 5));

        if (mounted) {
          setState(() {
            _isSignatureMode = false;
            _isSuccessState = false;
            _currentCitaId = null;
            _pdfUrl = null;
            _hasSignature = false;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: ErrorHandler.extractMessage(e),
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _signatureController.removeListener(_onSignatureChanged);
    _timer.cancel();
    _stompClient?.deactivate();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _isSignatureMode ? _buildInteractiveLayout() : _buildWelcome(),
      ),
    );
  }

  Widget _buildWelcome() {
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final hour = _currentTime.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 20) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Center(
      key: const ValueKey('welcome'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.spa_rounded,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            greeting,
            style: TextStyle(
              fontSize: 28,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bienvenido a Clínica Quiropráctica',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 40),
          // Reloj Digital
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w100,
                color: Color(0xFF2C3E50),
                fontFamily: 'Courier',
                letterSpacing: 8,
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            'Listo para atenderle. Por favor, espere su turno...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveLayout() {
    return Row(
      key: const ValueKey('interactive'),
      children: [
        // Lado Izquierdo: Visor de PDF
        Expanded(
          flex: 6,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: HtmlElementView(
                key: ValueKey(_pdfViewType),
                viewType: _pdfViewType,
              ),
            ),
          ),
        ),

        // Lado Derecho: Panel de Firma e Info
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSuccessState ? _buildSuccessPanel() : Column(
                key: const ValueKey('signing-panel'),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildSignatureCard()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessPanel() {
    return Center(
      key: const ValueKey('success-panel'),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '¡Gracias!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Documento firmado con éxito.\nYa puede cerrar la sesión.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'Resumen de la Sesión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.person_outline,
            'Paciente',
            _pacienteNombre ?? '---',
          ),
          _buildInfoRow(
            Icons.tag,
            'ID Cita',
            _currentCitaId?.toString() ?? '---',
          ),
          _buildInfoRow(Icons.event_available, 'Fecha', _fecha ?? '---'),
          _buildInfoRow(
            Icons.access_time,
            'Horario',
            '$_horaInicio - $_horaFin',
          ),
          if (_esBono)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _infoBono ?? 'Bono Activo',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_idBono != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 30),
                      child: Text(
                        'Ref: #$_idBono',
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF34495E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Firma de Conformidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Al firmar debajo, confirmo mi asistencia a la cita #$_currentCitaId el día $_fecha y acepto el cargo del servicio.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _hasSignature
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey.shade200,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFF9FAFB),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isSending ? null : () => _signatureController.clear(),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSending || !_hasSignature) ? null : _enviarFirma,
                  icon:
                      _isSending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.draw_outlined),
                  label: const Text(
                    'CONFIRMAR ASISTENCIA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: _hasSignature ? 5 : 0,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Documento con validez legal vinculada al historial clínico',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
