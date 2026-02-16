import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_bonos_tab.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_citas_tab.dart';
import 'package:quiropractico_front/ui/views/dashboard/tabs/cliente_familiares_tab.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClienteDetalleView extends StatelessWidget {
  final int idCliente;
  final int? initialTab;
  final String? initialFilter;

  const ClienteDetalleView({
    super.key,
    required this.idCliente,
    this.initialTab,
    this.initialFilter,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              ClientDetailProvider()
                ..loadFullData(idCliente)
                ..setFiltroEstado(initialFilter),
      child: _Content(initialTab: initialTab ?? 0),
    );
  }
}

class _Content extends StatefulWidget {
  final int initialTab;

  const _Content({required this.initialTab});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);

    // Solo mostramos pantalla de carga si no tenemos datos del cliente
    if (provider.isLoading && provider.cliente == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.cliente == null) {
      return const Center(child: Text("Cliente no encontrado"));
    }

    final cliente = provider.cliente!;
    final bonosActivos =
        provider.bonos.where((b) => b.sesionesRestantes > 0).length;
    final saldoSesiones = provider.bonos.fold(
      0,
      (sum, b) => sum + b.sesionesRestantes,
    );
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
              "Detalles del Paciente",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // Card info cliente
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 8, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(
                  nombreCompleto: cliente.nombre,
                  id: cliente.idCliente,
                  radius: 35,
                  fontSize: 28,
                ),
                const SizedBox(width: 25),

                // Datos del Cliente
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                decoration:
                                    isDeleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                color: isDeleted ? Colors.grey : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDeleted
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDeleted ? Colors.red : Colors.green,
                              ),
                            ),
                            child: Text(
                              isDeleted ? "BAJA" : "ACTIVO",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDeleted ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Tooltip(
                        message: "Abrir WhatsApp",
                        child: InkWell(
                          onTap:
                              () => _lanzarWhatsApp(context, cliente.telefono),
                          borderRadius: BorderRadius.circular(5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cliente.telefono,
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
                      const SizedBox(height: 15),
                      // Stats Chips Mejorados
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatChip(
                              label: "Citas del paciente",
                              value: provider.historialCitas.length.toString(),
                              icon: Icons.calendar_month,
                              color: Colors.blue,
                              tooltip:
                                  "Ver historial de citas de ${cliente.nombre}",
                              onTap:
                                  () => DefaultTabController.of(
                                    context,
                                  ).animateTo(0),
                            ),
                            const SizedBox(width: 15),
                            _StatChip(
                              label: "Bonos activos",
                              value: bonosActivos.toString(),
                              icon: Icons.card_membership,
                              color: Colors.orange,
                              tooltip: "Ver cartera de bonos activos",
                              onTap:
                                  () => DefaultTabController.of(
                                    context,
                                  ).animateTo(1),
                            ),
                            const SizedBox(width: 15),
                            _StatChip(
                              label: "Saldo de bonos",
                              value: saldoSesiones.toString(),
                              icon: Icons.account_balance_wallet,
                              color: Colors.green,
                              tooltip: "Total de sesiones disponibles en bonos",
                              onTap:
                                  () => DefaultTabController.of(
                                    context,
                                  ).animateTo(1),
                            ),
                            const SizedBox(width: 15),
                            // CHIP PRÓXIMA CITA
                            _StatChip(
                              label:
                                  provider.proximaCita != null
                                      ? "Próxima Cita"
                                      : "Crear Cita",
                              value:
                                  provider.proximaCita != null
                                      ? DateFormat(
                                        'd MMM - HH:mm',
                                        'es',
                                      ).format(
                                        provider.proximaCita!.fechaHoraInicio,
                                      )
                                      : "Sin agendar",
                              valueFontSize:
                                  provider.proximaCita != null ? 14 : 16,
                              icon:
                                  provider.proximaCita != null
                                      ? Icons.event_available
                                      : Icons.calendar_today,
                              color:
                                  provider.proximaCita != null
                                      ? Colors.purple
                                      : Colors.red.shade300,
                              tooltip:
                                  provider.proximaCita != null
                                      ? "Ver detalles de la próxima cita"
                                      : "Sin citas futuras. Pulsa para agendar.",
                              onTap: () async {
                                final proxima = provider.proximaCita;
                                if (proxima != null) {
                                  await showDialog(
                                    context: context,
                                    builder:
                                        (_) => CitaDetalleModal(cita: proxima),
                                  );
                                  provider.loadFullData(cliente.idCliente);
                                } else {
                                  final refresh = await showDialog(
                                    context: context,
                                    builder:
                                        (_) => CitaModal(
                                          preSelectedClient: cliente,
                                        ),
                                  );
                                  if (refresh == true) {
                                    provider.loadFullData(cliente.idCliente);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final clienteAnterior = cliente.copyWith();
                        final refresh = await showDialog(
                          context: context,
                          builder:
                              (_) => ClientModal(clienteExistente: cliente),
                        );

                        if (refresh == true) {
                          await provider.refreshClient();
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: "Paciente actualizado",
                              type: SnackBarType.success,
                              actionLabel: "DESHACER",
                              onAction: () async {
                                final clientsProvider =
                                    Provider.of<ClientsProvider>(
                                      context,
                                      listen: false,
                                    );
                                final err = await clientsProvider
                                    .undoUpdateClient(clienteAnterior);
                                if (err == null) {
                                  await provider.refreshClient();
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: "Edición deshecha",
                                      type: SnackBarType.info,
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: err,
                                      type: SnackBarType.error,
                                    );
                                  }
                                }
                              },
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 28,
                      ),
                      tooltip: "Editar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final nombreCompleto =
                            "${cliente.nombre} ${cliente.apellidos}";
                        final eraBorrado = !isDeleted;
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
                              message:
                                  eraBorrado
                                      ? "Paciente $nombreCompleto eliminado"
                                      : "Paciente $nombreCompleto reactivado",
                              type: SnackBarType.success,
                              actionLabel: "DESHACER",
                              onAction: () async {
                                if (eraBorrado) {
                                  await provider.recoverClient(
                                    cliente.idCliente,
                                    undo: true,
                                  );
                                } else {
                                  await provider.deleteClient(
                                    cliente.idCliente,
                                    undo: true,
                                  );
                                }
                                await provider.refreshClient();
                              },
                            );
                          }
                        } else {
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: err,
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                      icon: Icon(
                        isDeleted ? Icons.restore : Icons.delete,
                        color: isDeleted ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      tooltip: isDeleted ? "Reactivar Paciente" : "Eliminar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tabs
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Historial de Citas", icon: Icon(Icons.history)),
                  Tab(
                    text: "Cartera de Bonos",
                    icon: Icon(Icons.card_membership),
                  ),
                  Tab(text: "Familiares", icon: Icon(Icons.family_restroom)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ClienteCitasTab(cliente: cliente),
                    ClienteBonosTab(cliente: cliente),
                    ClienteFamiliaresTab(cliente: cliente),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _lanzarWhatsApp(BuildContext context, String telefono) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;

    final url = Uri.parse("https://wa.me/$cleanPhone");
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
