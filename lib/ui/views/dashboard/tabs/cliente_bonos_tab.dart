import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/ui/widgets/bono_detalle_modal.dart';
import 'package:quiropractico_front/ui/widgets/empty_state.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/config/api_config.dart';

class ClienteBonosTab extends StatefulWidget {
  final Cliente cliente;
  final bool showBono;
  final int? resaltarCitaId;

  const ClienteBonosTab({
    super.key,
    required this.cliente,
    this.showBono = false,
    this.resaltarCitaId,
  });

  @override
  State<ClienteBonosTab> createState() => _ClienteBonosTabState();
}

class _ClienteBonosTabState extends State<ClienteBonosTab> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _abrirPrimerBono(ClientDetailProvider provider) async {
    if (provider.bonos.isEmpty) return;

    BonoHistorico? targetBono;

    if (widget.resaltarCitaId != null) {
      for (final bono in provider.bonos) {
        try {
          final res = await ApiService.dio.get('${ApiConfig.baseUrl}/bonos/${bono.idBonoActivo}/consumos');
          if (res.data is List) {
            final hasCita = (res.data as List).any((item) => item['idCita']?.toString() == widget.resaltarCitaId.toString());
            if (hasCita) {
              targetBono = bono;
              break;
            }
          }
        } catch (_) {}
      }
    }

    if (targetBono == null) {
      final activeBonos = provider.bonos.where((b) => b.sesionesRestantes > 0).toList();
      targetBono = activeBonos.isNotEmpty ? activeBonos.first : provider.bonos.first;
    }

    if (!mounted) return;

    await BonoDetalleModal.show(
      context,
      bono: targetBono,
      resaltarCitaId: widget.resaltarCitaId,
    );
    
    if (mounted) {
      provider.refreshBonos(silent: true);
      provider.refreshCitas(silent: true);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBonoCard(BuildContext context, BonoHistorico bono) {
    double porcentaje = 0.0;
    if (bono.sesionesTotales > 0) {
      porcentaje = bono.sesionesRestantes / bono.sesionesTotales;
    }

    final isActive = bono.sesionesRestantes > 0;
    Color statusColor = isActive ? Colors.green : Colors.grey;
    if (isActive && porcentaje <= 0.2) {
      statusColor = Colors.orange;
    }

    String textoSesiones;
    if (bono.sesionesTotales == 1) {
      textoSesiones = bono.sesionesRestantes == 1 ? "Sesión única disponible" : "Sesión única consumida";
    } else {
      textoSesiones = "${bono.sesionesRestantes} de ${bono.sesionesTotales} sesiones disponibles";
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: "Toca para ver historial del bono",
        child: InkWell(
          onTap: () async {
            await BonoDetalleModal.show(
              context,
              bono: bono,
              resaltarCitaId: widget.resaltarCitaId,
            );
            if (context.mounted) {
              final provider = Provider.of<ClientDetailProvider>(context, listen: false);
              provider.refreshBonos(silent: true);
              provider.refreshCitas(silent: true);
            }
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.card_membership, color: statusColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: bono.nombreServicio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                    TextSpan(text: "  Ref: #${bono.idBonoActivo}", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(textoSesiones, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text("Comprado el ${DateFormat('dd/MM/yyyy').format(bono.fechaCompra)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  if (bono.monto != null) ...[
                                    const SizedBox(width: 8),
                                    Text("•", style: TextStyle(color: Colors.grey.shade400)),
                                    const SizedBox(width: 8),
                                    Text("${bono.monto!.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                  ]
                                ]
                              ),
                            ],
                          ),
                        ),
                        if (!(bono.pagado))
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                            child: Text("PENDIENTE DE PAGO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
                            child: Text(isActive ? "ACTIVO" : "AGOTADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);
    final bonosActivos = provider.bonos.where((b) => b.sesionesRestantes > 0).toList();
    final bonosConsumidos = provider.bonos.where((b) => b.sesionesRestantes == 0).toList();

    if (widget.showBono && !_dialogShown && !provider.isLoading && provider.bonos.isNotEmpty) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirPrimerBono(provider);
      });
    }

    if (provider.bonos.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.card_membership,
        title: "Sin bonos contratados",
        subtitle: "El paciente no tiene bonos activos ni historial.",
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadFullData(widget.cliente.idCliente);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          if (bonosActivos.isNotEmpty) ...[
            _buildSectionHeader("Bonos Activos"),
            ...bonosActivos.map((bono) => _buildBonoCard(context, bono)),
          ],
          if (bonosConsumidos.isNotEmpty) ...[
            if (bonosActivos.isNotEmpty)
              const Divider(height: 30, thickness: 1),
            _buildSectionHeader("Historial de Bonos"),
            ...bonosConsumidos.map((bono) => _buildBonoCard(context, bono)),
          ],
        ],
      ),
    );
  }
}
