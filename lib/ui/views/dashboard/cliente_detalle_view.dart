import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/models/tipo_documento.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/download_helper.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:quiropractico_front/ui/modals/lopd_firma_waiting_dialog.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
import 'package:quiropractico_front/ui/widgets/bono_detalle_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_bonos_tab.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_citas_tab.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_archivos_tab.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_familiares_tab.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class ClienteDetalleView extends StatelessWidget {
  final int idCliente;
  final int? initialTab;
  final String? initialFilter;
  final bool showBono;
  final int? resaltarCitaId;

  const ClienteDetalleView({
    super.key,
    required this.idCliente,
    this.initialTab,
    this.initialFilter,
    this.showBono = false,
    this.resaltarCitaId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              ClientDetailProvider()
                ..loadFullData(idCliente)
                ..setFiltroEstado(initialFilter),
      child: _Content(
        initialTab: initialTab ?? 0,
        showBono: showBono,
        resaltarCitaId: resaltarCitaId,
      ),
    );
  }
}

class _Content extends StatefulWidget {
  final int initialTab;
  final bool showBono;
  final int? resaltarCitaId;

  const _Content({
    required this.initialTab,
    this.showBono = false,
    this.resaltarCitaId,
  });

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StompClient? _stompClient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _initWebSocket();
  }

  void _initWebSocket() {
    final token = LocalStorage.getToken();
    if (token == null) return;
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
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onWebSocketError: (error) => debugPrint('WS Error en ClienteDetalleView: $error'),
      ),
    );
    _stompClient?.activate();
  }

  void _handleWsMessage(StompFrame frame) {
    if (frame.body == null || !mounted) return;
    try {
      final data = json.decode(frame.body!);
      final action = data['action'];

      if (action == 'LOPD_FIRMADA' || action == 'CLIENTE_LOPD_FIRMADA' || action == 'FIRMA_LOPD_EXITOSA') {
        final dynamic rawId = data['idCliente'] ?? data['clienteId'] ?? data['id'];
        final int? idClienteFirmado = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

        final detailProvider = Provider.of<ClientDetailProvider>(context, listen: false);
        final currentClienteId = detailProvider.cliente?.idCliente;

        if (currentClienteId != null && (idClienteFirmado == null || idClienteFirmado == currentClienteId)) {
          // 1. Inmediatamente marcar como firmada y refrescar el cliente
          detailProvider.marcarLopdFirmada();
          detailProvider.refreshCliente(silent: true);

          // 2. Refrescar silenciosamente los documentos en memoria
          final docProvider = Provider.of<DocumentosProvider>(context, listen: false);
          docProvider.loadDocumentos(currentClienteId, silent: true);

          // 3. Feedback visual para la recepcionista
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: '¡El paciente ha firmado el documento LOPD!',
              type: SnackBarType.success,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error procesando WS en ClienteDetalleView: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);

    // Solo mostramos pantalla de carga si no tenemos datos del cliente
    if (provider.isLoading && provider.cliente == null) {
      return const _SkeletonClienteDetalle();
    }

    if (provider.cliente == null) {
      return const Center(child: Text("Cliente no encontrado"));
    }

    final cliente = provider.cliente!;
    final bonosActivos = provider.bonos.where((b) => b.sesionesRestantes > 0).length;
    final saldoSesiones = provider.bonos.fold(0, (sum, b) => sum + b.sesionesRestantes);
    final bool isDeleted = !cliente.activo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navegación
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/pacientes');
                }
              },
              tooltip: 'Volver',
            ),
            const SizedBox(width: 10),
            const Text(
              "Expediente del Paciente",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Flat Desktop Header
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila Superior (Identidad + Acciones)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarWidget(
                      nombreCompleto: cliente.nombre,
                      id: cliente.idCliente,
                      radius: 35,
                      fontSize: 28,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "${cliente.nombre} ${cliente.apellidos}",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDeleted ? Colors.grey : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDeleted) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Text(
                                    "BAJA",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Text(
                                '#${cliente.idCliente}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (cliente.dniNie != null && cliente.dniNie!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'DNI: ${cliente.dniNie}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              _buildLopdChip(context, cliente),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Tooltip(
                                message: "Abrir WhatsApp",
                                child: InkWell(
                                  onTap: () => _lanzarWhatsApp(context, cliente.prefijoTelefono, cliente.telefono),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${cliente.prefijoTelefono} ${cliente.telefono}',
                                          style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (cliente.email != null && cliente.email!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                _EmailCopyRow(email: cliente.email!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botones Sutiles
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final refresh = await showDialog(
                              context: context,
                              builder: (_) => ClientModal(clienteExistente: cliente),
                            );
                            if (refresh == true) {
                              await provider.refreshCliente(silent: false);
                              if (context.mounted) {
                                CustomSnackBar.show(context, message: "Paciente actualizado", type: SnackBarType.success);
                              }
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          tooltip: "Editar",
                        ),
                        IconButton(
                          onPressed: () async {
                            final nombreCompleto = "${cliente.nombre} ${cliente.apellidos}";
                            if (!isDeleted) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => DeleteConfirmDialog(
                                  title: '¿Eliminar Paciente?',
                                  content: '¿Estás seguro de que deseas eliminar al paciente "$nombreCompleto"?',
                                ),
                              );
                              if (confirm != true) return;
                            }
                            String? err;
                            if (isDeleted) {
                              err = await provider.recoverClient(cliente.idCliente);
                            } else {
                              err = await provider.deleteClient(cliente.idCliente);
                            }
                            if (err == null) {
                              if (context.mounted) {
                                CustomSnackBar.show(
                                  context,
                                  message: !isDeleted ? "Paciente $nombreCompleto eliminado" : "Paciente $nombreCompleto reactivado",
                                  type: SnackBarType.success,
                                );
                              }
                            } else {
                              if (context.mounted) {
                                CustomSnackBar.show(context, message: err, type: SnackBarType.error);
                              }
                            }
                          },
                          icon: Icon(isDeleted ? Icons.restore : Icons.delete, color: isDeleted ? Colors.green : Colors.red),
                          tooltip: isDeleted ? "Reactivar Paciente" : "Eliminar",
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Acciones Principales
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final refresh = await showDialog(
                              context: context,
                              builder: (_) => CitaModal(preSelectedClient: cliente),
                            );
                            if (refresh == true) {
                              provider.refreshCitas(silent: true);
                              provider.refreshBonos(silent: true);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text("Agendar Cita"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final refresh = await showDialog(
                              context: context,
                              builder: (_) => VentaBonoModal(cliente: cliente),
                            );
                            if (refresh == true) {
                              provider.refreshBonos(silent: true);
                            }
                          },
                          icon: const Icon(Icons.card_membership, size: 16),
                          label: const Text("Vender Bono"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Fila Inferior (Resumen Clínico-Financiero)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (cliente.proximaCita != null) {
                              await showDialog(
                                context: context,
                                builder: (_) => CitaDetalleModal(cita: cliente.proximaCita!),
                              );
                              if (context.mounted) {
                                provider.refreshCliente(silent: true);
                                provider.refreshCitas(silent: true);
                              }
                            } else {
                              final refresh = await showDialog(
                                context: context,
                                builder: (_) => CitaModal(preSelectedClient: cliente),
                              );
                              if (refresh == true && context.mounted) {
                                provider.refreshCliente(silent: true);
                                provider.refreshCitas(silent: true);
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cliente.proximaCita != null ? Colors.purple.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    cliente.proximaCita != null ? Icons.event_available : Icons.event_busy,
                                    color: cliente.proximaCita != null ? Colors.purple : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Próxima Cita", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      Text(
                                        cliente.proximaCita != null ? DateFormat('d MMM - HH:mm', 'es').format(cliente.proximaCita!.fechaHoraInicio) : "Sin cita programada",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: cliente.proximaCita != null ? Colors.purple.shade700 : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.card_membership, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Bonos / Sesiones", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      Text(
                                        "$bonosActivos activos · $saldoSesiones disp.",
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _tabController.animateTo(0);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.history, color: Colors.green, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${cliente.citasCompletadas} completadas", style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                                      Text(
                                        "${cliente.citasAusentes} ausencias · ${cliente.citasCanceladas} canceladas",
                                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (cliente.deudaPendiente > 0) {
                              final impagados = provider.bonos.where((b) => !(b.pagado)).toList();
                              if (impagados.length == 1 && cliente.pagosPendientesCount <= 1) {
                                BonoDetalleModal.show(context, bono: impagados.first).then((_) {
                                  provider.refreshCliente(silent: true);
                                  provider.refreshBonos(silent: true);
                                });
                              } else {
                                _tabController.animateTo(1);
                                CustomSnackBar.show(
                                  context,
                                  message: 'Selecciona el bono que deseas cobrar',
                                  type: SnackBarType.info,
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cliente.deudaPendiente > 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: cliente.deudaPendiente > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.deudaPendiente > 0 ? "Pendiente: ${cliente.deudaPendiente.toStringAsFixed(2)} €" : "Al día",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cliente.deudaPendiente > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (cliente.deudaPendiente > 0)
                                        Text(
                                          "(${cliente.pagosPendientesCount} ${cliente.pagosPendientesCount == 1 ? 'pago' : 'pagos'})",
                                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.red.shade400),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tabs Monolíticos
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: "Citas (${provider.historialCitas.length})"),
                      Tab(text: "Bonos y Sesiones (${provider.bonos.length})"),
                      Tab(text: "Familiares (${provider.familiares.length})"),
                      const Tab(text: "Archivos"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ClienteCitasTab(cliente: cliente),
                      ClienteBonosTab(
                        cliente: cliente,
                        showBono: widget.showBono,
                        resaltarCitaId: widget.resaltarCitaId,
                      ),
                      ClienteFamiliaresTab(cliente: cliente),
                      ClienteArchivosTab(cliente: cliente),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _lanzarWhatsApp(BuildContext context, String prefijo, String telefono) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPrefijo = prefijo.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;

    final url = Uri.parse("https://wa.me/$cleanPrefijo$cleanPhone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: "No se pudo abrir WhatsApp",
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: "Error al abrir WhatsApp",
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildLopdChip(BuildContext context, Cliente cliente) {
    if (cliente.lopdFirmada) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarOpcionesLopdFirmada(context, cliente),
          borderRadius: BorderRadius.circular(20),
          hoverColor: Colors.green.withValues(alpha: 0.12),
          child: Tooltip(
            message: 'LOPD Firmada · Clic para previsualizar o gestionar',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, size: 14, color: Colors.green),
                  SizedBox(width: 5),
                  Text(
                    'LOPD Firmada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _solicitarFirmaLopd(context, cliente.idCliente, '${cliente.nombre} ${cliente.apellidos}'),
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.deepOrange.withValues(alpha: 0.08),
        child: Tooltip(
          message: 'Pulsar para solicitar firma LOPD en el Kiosco',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepOrange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_actions_rounded, size: 14, color: Colors.deepOrange.shade700),
                const SizedBox(width: 5),
                Text(
                  'LOPD Pendiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.touch_app_rounded, size: 12, color: Colors.deepOrange.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _solicitarFirmaLopd(BuildContext context, int idCliente, [String? nombreCliente]) async {
    final bool? firmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LopdFirmaWaitingDialog(
        idCliente: idCliente,
        nombreCliente: nombreCliente,
      ),
    );

    if (context.mounted && firmado == true) {
      final detailProvider = Provider.of<ClientDetailProvider>(context, listen: false);
      detailProvider.marcarLopdFirmada();
      detailProvider.refreshCliente(silent: true);
      final docProvider = Provider.of<DocumentosProvider>(context, listen: false);
      docProvider.loadDocumentos(idCliente, silent: true);
    }
  }

  Future<void> _mostrarOpcionesLopdFirmada(BuildContext context, Cliente cliente) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consentimiento LOPD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Documento legal firmado y en vigor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Previsualizar / Descargar PDF', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Abrir el documento firmado'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _abrirDocumentoLopd(context, cliente.idCliente);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_open_outlined, color: Colors.blue),
              ),
              title: const Text('Ver en pestaña Archivos', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ir a carpeta Consentimiento LOPD'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.of(ctx).pop();
                _tabController.animateTo(3); // Tab 3: Archivos
                final docProvider = Provider.of<DocumentosProvider>(context, listen: false);
                docProvider.entrarCarpeta(TipoDocumento.consentimientoLopd);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tablet_mac_rounded, color: Colors.deepOrange),
              ),
              title: const Text('Re-enviar a la Tablet', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepOrange)),
              subtitle: const Text('Solicitar una nueva firma en el Kiosco'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.of(ctx).pop();
                _mostrarAdvertenciaRenovarLopd(context, cliente);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarAdvertenciaRenovarLopd(BuildContext context, Cliente cliente) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 10,
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header superior sutil con tono naranja/rojo y warning icon grande
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.deepOrange.shade100, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.deepOrange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Renovar Consentimiento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Acción legal importante',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepOrange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cuerpo con advertencia detallada
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Este paciente ya cuenta con un documento LOPD firmado y en vigor.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.archive_outlined, size: 20, color: Colors.amber.shade900),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Si procedes, el documento anterior se archivará en el histórico y se solicitará una nueva firma en la tablet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¿Deseas continuar y abrir el Kiosco ahora?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones corporativas
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.tablet_mac_rounded, size: 16),
                      label: const Text(
                        'Continuar y Renovar',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

    if (confirmar == true && context.mounted) {
      _solicitarFirmaLopd(context, cliente.idCliente, '${cliente.nombre} ${cliente.apellidos}');
    }
  }

  Future<void> _abrirDocumentoLopd(BuildContext context, int idCliente) async {
    final docProvider = Provider.of<DocumentosProvider>(context, listen: false);
    CustomSnackBar.show(context, message: 'Localizando documento LOPD firmado...', type: SnackBarType.info);

    if (docProvider.documentos.isEmpty) {
      await docProvider.loadDocumentos(idCliente, silent: true);
    }

    Documento? lopdDoc;
    try {
      lopdDoc = docProvider.documentos.firstWhere(
        (d) => d.tipo == TipoDocumento.consentimientoLopd,
      );
    } catch (_) {
      lopdDoc = null;
    }

    if (lopdDoc != null) {
      final url = await docProvider.obtenerUrlTemporal(lopdDoc.idDocumento, download: false);
      if (url != null) {
        DownloadHelper.viewFile(url);
        return;
      }
    }

    if (context.mounted) {
      CustomSnackBar.show(
        context,
        message: 'No se encontró el archivo firmado en la lista de documentos.',
        type: SnackBarType.info,
      );
    }
  }
}

/// Widget que imita el layout de la pantalla de detalles mientras carga
class _SkeletonClienteDetalle extends StatelessWidget {
  const _SkeletonClienteDetalle();

  Widget _box(double w, double h, {double radius = 8}) {
    return Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)));
  }

  Widget _boxFaded(double w, double h, {double radius = 8, double opacity = 0.45}) {
    return Opacity(
      opacity: opacity,
      child: Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navegación
          Row(
            children: [
              _boxFaded(36, 36, radius: 18),
              const SizedBox(width: 12),
              _box(200, 24),
            ],
          ),
          const SizedBox(height: 16),
          // Flat Desktop Header
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(70, 70, radius: 35),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _box(240, 26),
                            const SizedBox(height: 12),
                            _boxFaded(140, 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      _box(130, 40, radius: 8),
                      const SizedBox(width: 10),
                      _box(130, 40, radius: 8),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: List.generate(4, (index) => Expanded(
                      child: Row(
                        children: [
                          _box(36, 36, radius: 8),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _boxFaded(80, 12),
                                const SizedBox(height: 6),
                                _box(120, 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tabs
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _box(120, 30), const SizedBox(width: 20),
                        _boxFaded(120, 30), const SizedBox(width: 20),
                        _boxFaded(120, 30), const SizedBox(width: 20),
                        _boxFaded(120, 30),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _boxFaded(double.infinity, 80, radius: 10),
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  final double? valueFontSize;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? "",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 26,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: valueFontSize ?? 18,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Email con copia al portapapeles
class _EmailCopyRow extends StatefulWidget {
  final String email;
  const _EmailCopyRow({required this.email});

  @override
  State<_EmailCopyRow> createState() => _EmailCopyRowState();
}

class _EmailCopyRowState extends State<_EmailCopyRow> {
  bool _copiado = false;
  Timer? _timer;

  void _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.email));
    setState(() => _copiado = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copiar correo',
      child: InkWell(
        onTap: _copiar,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child:
                _copiado
                    ? Row(
                      key: const ValueKey('copiado'),
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 5),
                        Text(
                          'Correo copiado',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      key: const ValueKey('email'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
