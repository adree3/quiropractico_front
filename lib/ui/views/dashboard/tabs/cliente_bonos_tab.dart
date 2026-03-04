import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/ui/widgets/bono_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
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
    // La apertura del modal se evaluará en el build después de cargar datos
  }

  Future<void> _abrirPrimerBono(ClientDetailProvider provider) async {
    if (provider.bonos.isEmpty) return;

    if (widget.resaltarCitaId != null) {
      // Búsqueda silenciosa
    }

    Bono? targetBono;

    if (widget.resaltarCitaId != null) {
      // Buscar el bono dueño de la cita consultando sus consumos
      for (final bono in provider.bonos) {
        try {
          final res = await ApiService.dio.get(
            '${ApiConfig.baseUrl}/bonos/${bono.idBonoActivo}/consumos',
          );

          if (res.data is List) {
            final list = res.data as List;
            final hasCita = list.any(
              (item) =>
                  item['idCita']?.toString() ==
                  widget.resaltarCitaId.toString(),
            );

            if (hasCita) {
              targetBono = bono;
              break;
            }
          }
        } catch (_) {}
      }
    }

    if (targetBono == null) {
      final activeBonos =
          provider.bonos.where((b) => b.sesionesRestantes > 0).toList();
      targetBono =
          activeBonos.isNotEmpty ? activeBonos.first : provider.bonos.first;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => BonoDetalleModal(
            bono: targetBono!,
            nombreCliente:
                "${widget.cliente.nombre} ${widget.cliente.apellidos}",
            idCliente: widget.cliente.idCliente,
            resaltarCitaId: widget.resaltarCitaId,
          ),
    );
  }

  void _mostrarVentaBono(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => VentaBonoModal(cliente: widget.cliente),
    ).then((val) {
      if (val == true) {
        Provider.of<ClientDetailProvider>(
          context,
          listen: false,
        ).loadFullData(widget.cliente.idCliente);
      }
    });
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

  Widget _buildBonoCard(BuildContext context, Bono bono) {
    // Calcular porcentaje de uso
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
      if (bono.sesionesRestantes == 1) {
        textoSesiones = "Sesión única disponible";
      } else {
        textoSesiones = "Sesión única consumida";
      }
    } else {
      textoSesiones =
          "${bono.sesionesRestantes} de ${bono.sesionesTotales} sesiones disponibles";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Tooltip(
        message: "Toca para ver historial del bono",
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (ctx) => BonoDetalleModal(
                    bono: bono,
                    nombreCliente:
                        "${widget.cliente.nombre} ${widget.cliente.apellidos}",
                    idCliente: widget.cliente.idCliente,
                    resaltarCitaId: widget.resaltarCitaId,
                  ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_membership,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: bono.nombreServicio,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: "  Ref: #${bono.idBonoActivo}",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textoSesiones,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Comprado el ${DateFormat('dd/MM/yyyy').format(bono.fechaCompra)}",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chip de pagado
                if (!bono.esPagado)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      "PENDIENTE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  )
                else
                  // Opcional: Mostrar "PAGADO" o solo mostrar si es pendiente para no ensuciar
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      "PAGADO",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
    final bonosActivos =
        provider.bonos.where((b) => b.sesionesRestantes > 0).toList();
    final bonosConsumidos =
        provider.bonos.where((b) => b.sesionesRestantes == 0).toList();

    // Auto-abrir modal de bono si se solicita
    if (widget.showBono &&
        !_dialogShown &&
        !provider.isLoading &&
        provider.bonos.isNotEmpty) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirPrimerBono(provider);
      });
    }

    return Stack(
      children: [
        if (provider.bonos.isEmpty)
          EmptyStateWidget(
            icon: Icons.card_membership,
            title: "Sin bonos contratados",
            subtitle: "El paciente no tiene bonos activos ni historial.",
            action: ElevatedButton.icon(
              onPressed: () => _mostrarVentaBono(context),
              icon: const Icon(Icons.add_card),
              label: const Text("Vender Nuevo Bono"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: () async {
              await provider.loadFullData(widget.cliente.idCliente);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (bonosActivos.isNotEmpty) ...[
                  _buildSectionHeader("Bonos Activos"),
                  ...bonosActivos.map((bono) => _buildBonoCard(context, bono)),
                ],
                if (bonosConsumidos.isNotEmpty) ...[
                  if (bonosActivos.isNotEmpty)
                    const Divider(height: 30, thickness: 1),
                  _buildSectionHeader("Historial de Bonos"),
                  ...bonosConsumidos.map(
                    (bono) => _buildBonoCard(context, bono),
                  ),
                ],
              ],
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _mostrarVentaBono(context),
            icon: const Icon(Icons.add_card),
            label: const Text("Vender Bono"),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
