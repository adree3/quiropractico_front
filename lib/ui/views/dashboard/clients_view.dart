import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/premium_data_table.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  Timer? _debounce;
  final searchCtrl = TextEditingController();
  final ScrollController _headerScroll = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ClientsProvider>(context, listen: false);
      if (provider.clients.isEmpty && !provider.isLoading) {
        provider.loadClients();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    _headerScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ClientsProvider>(context, listen: false).searchGlobal(query);
    });
  }

  void _mostrarSnack(String mensaje, Color color) {
    CustomSnackBar.show(context, message: mensaje, type: SnackBarType.info);
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final clientes = clientsProvider.clients;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: PremiumDataTable<Cliente>(
        items: clientes,
        isLoading: clientsProvider.isLoading,
        wrapInCard: true,
        columnFlexes: const [1, 4, 3, 2, 2],
        columnHeaders: [
          _buildHeaderCell("ID", alignment: Alignment.centerLeft),
          _buildHeaderCell("Paciente", alignment: Alignment.centerLeft),
          _buildHeaderCell("Contacto", alignment: Alignment.centerLeft),
          _buildHeaderCell("Teléfono", alignment: Alignment.centerLeft),
          _buildHeaderCell("Acciones", alignment: Alignment.centerRight),
        ],
        topContent: _buildHeaderTopControls(context, clientsProvider),
        bottomContent: _buildPaginationControls(context, clientsProvider),
        emptyStateBuilder: (_) => _buildEmptyState(clientsProvider),
        rowBuilder: (context, cliente, index) {
          return _buildRowItem(context, clientsProvider, cliente);
        },
      ),
    );
  }

  Widget _buildHeaderCell(String title, {Alignment alignment = Alignment.centerLeft}) {
    return Align(
      alignment: alignment,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.blueGrey.shade800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildHeaderTopControls(BuildContext context, ClientsProvider clientsProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(4),
              radius: const Radius.circular(4),
              thumbColor: WidgetStateProperty.all(
                Colors.grey.withValues(alpha: 0.35),
              ),
              trackColor: WidgetStateProperty.all(Colors.transparent),
              trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              thumbVisibility: WidgetStateProperty.all(true),
            ),
            child: Scrollbar(
              controller: _headerScroll,
              child: SingleChildScrollView(
                controller: _headerScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 9),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // GRUPO IZQUIERDO: Título + Buscador
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            Icons.groups_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Pacientes',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 20),
                          // Buscador
                          SizedBox(
                            width: (constraints.maxWidth - 670).clamp(200.0, 400.0),
                            child: TextField(
                              controller: searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre, apellido o teléfono',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                suffixIcon: searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          searchCtrl.clear();
                                          _debounce?.cancel();
                                          Provider.of<ClientsProvider>(
                                            context,
                                            listen: false,
                                          ).searchGlobal('');
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ],
                      ),

                      // GRUPO DERECHO: Filtros + Botón
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: "Filtrar estado",
                            child: _buildStatusDropdown(clientsProvider),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: "Filtrar por actividad reciente",
                            child: _buildActivityDropdown(clientsProvider),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: "Crear paciente",
                            child: HoverableActionButton(
                              label: "Paciente",
                              icon: Icons.person_add,
                              isPrimary: true,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const ClientModal(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRowItem(BuildContext context, ClientsProvider clientsProvider, Cliente cliente) {
    final isDeleted = !cliente.activo;
    final textColor = isDeleted ? Colors.grey : Colors.black87;
    final textDecoration = isDeleted ? TextDecoration.lineThrough : null;

    return Tooltip(
      message: "Ver detalles de ${cliente.nombre}",
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: () => context.go('/pacientes/${cliente.idCliente}'),
        borderRadius: BorderRadius.circular(6),
        hoverColor: isDeleted
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.blue.shade50.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
          child: Row(
            children: [
              // 1. ID (Flex 1)
              Expanded(
                flex: 1,
                child: Text(
                  "#${cliente.idCliente}",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: isDeleted ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    decoration: textDecoration,
                  ),
                ),
              ),

              // 2. Paciente (Flex 4)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    AvatarWidget(
                      nombreCompleto: cliente.nombre,
                      id: cliente.idCliente,
                      radius: 20,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${cliente.nombre} ${cliente.apellidos}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textColor,
                                    decoration: textDecoration,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (cliente.citasPendientes != null &&
                                  cliente.citasPendientes! > 0)
                                _buildClickableInfoChip(
                                  context,
                                  "${cliente.citasPendientes}",
                                  Colors.blue,
                                  Icons.event,
                                  'Citas programadas',
                                  () => _navigateToCitasTab(
                                    context,
                                    cliente.idCliente,
                                  ),
                                ),
                              if (cliente.citasPendientes != null &&
                                  cliente.citasPendientes! > 0 &&
                                  cliente.bonosActivos != null &&
                                  cliente.bonosActivos! > 0)
                                const SizedBox(width: 4),
                              if (cliente.bonosActivos != null &&
                                  cliente.bonosActivos! > 0)
                                _buildClickableInfoChip(
                                  context,
                                  "${cliente.bonosActivos}",
                                  Colors.green,
                                  Icons.card_giftcard,
                                  'Bonos activos',
                                  () => _navigateToBonosTab(
                                    context,
                                    cliente.idCliente,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (cliente.ultimaCita != null)
                            Text(
                              _formatLastVisit(cliente.ultimaCita!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              "Sin citas",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Contacto / Email (Flex 3)
              Expanded(
                flex: 3,
                child: Text(
                  cliente.email ?? '-',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    decoration: textDecoration,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 4. Teléfono (Flex 2)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: "Ir a WhatsApp",
                    child: InkWell(
                      onTap: () => _lanzarWhatsApp(cliente.telefono),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.whatsapp,
                              size: 16,
                              color: isDeleted ? Colors.grey : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                cliente.telefono,
                                style: TextStyle(
                                  color: isDeleted ? Colors.grey : Colors.blueGrey.shade700,
                                  fontSize: 15,
                                  decoration: textDecoration,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Acciones (Flex 2)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.event_available,
                        color: Colors.blue,
                        size: 24,
                      ),
                      tooltip: "Crear cita para ${cliente.nombre}",
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => CitaModal(
                            preSelectedClient: cliente,
                          ),
                        );
                        if (result != null) {
                          clientsProvider.reloadClient(cliente.idCliente);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.orange,
                        size: 24,
                      ),
                      tooltip: "Editar",
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final changed = await showDialog<bool>(
                          context: context,
                          builder: (_) => ClientModal(
                            clienteExistente: cliente,
                          ),
                        );
                        if (changed == true) {
                          clientsProvider.reloadClient(cliente.idCliente);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        isDeleted ? Icons.restore_from_trash : Icons.delete_outline,
                        color: isDeleted ? Colors.green : Colors.redAccent,
                        size: 24,
                      ),
                      tooltip: isDeleted ? 'Reactivar' : 'Eliminar',
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        _ejecutarAccionDirecta(
                          context,
                          clientsProvider,
                          cliente,
                        );
                      },
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

  Widget _buildEmptyState(ClientsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 40,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.currentSearchTerm.isNotEmpty
                  ? "No se encontraron pacientes para '${provider.currentSearchTerm}'"
                  : "No hay pacientes registrados",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Intenta modificar los filtros de búsqueda o crea un nuevo paciente.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, ClientsProvider provider) {
    if (provider.totalElements <= provider.pageSize && provider.currentPage == 0) {
      return const SizedBox.shrink();
    }

    final int startRecord = (provider.currentPage * provider.pageSize) + 1;
    final int endRecord = min(
      (provider.currentPage + 1) * provider.pageSize,
      provider.totalElements,
    );
    final int totalPages = (provider.totalElements / provider.pageSize).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Mostrando $startRecord - $endRecord de ${provider.totalElements} registros",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: provider.currentPage > 0 && !provider.isLoading
                    ? () => provider.loadClients(page: provider.currentPage - 1)
                    : null,
                tooltip: "Anterior",
                splashRadius: 18,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Página ${provider.currentPage + 1} de ${totalPages == 0 ? 1 : totalPages}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: provider.currentPage < totalPages - 1 && !provider.isLoading
                    ? () => provider.loadClients(page: provider.currentPage + 1)
                    : null,
                tooltip: "Siguiente",
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(ClientsProvider provider) {
    return DashboardDropdown<bool?>(
      selectedValue: provider.filterActive,
      tooltip: "Filtrar estado",
      onSelected: (val) => provider.toggleFilter(val),
      options: const [
        DropdownOption(
          value: true,
          label: "Activos",
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        DropdownOption(
          value: false,
          label: "Eliminados",
          icon: Icons.delete_outline,
          color: Colors.redAccent,
        ),
        DropdownOption(
          value: null,
          label: "Todos",
          icon: Icons.list,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildActivityDropdown(ClientsProvider provider) {
    return DashboardDropdown<int?>(
      selectedValue: provider.lastActivityDays,
      tooltip: "Filtrar por última visita",
      onSelected: (val) => provider.setActivityFilter(val),
      options: const [
        DropdownOption(
          value: null,
          label: "Todos",
          icon: Icons.all_inclusive,
          color: Colors.grey,
        ),
        DropdownOption(
          value: 7,
          label: "7 días",
          icon: Icons.today,
          color: Colors.blue,
        ),
        DropdownOption(
          value: 30,
          label: "30 días",
          icon: Icons.calendar_month,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildClickableInfoChip(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCitasTab(BuildContext context, int clienteId) {
    context.go('/pacientes/$clienteId?tab=0&filtro=programada');
  }

  void _navigateToBonosTab(BuildContext context, int clienteId) {
    context.go('/pacientes/$clienteId?tab=1');
  }

  String _formatLastVisit(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit);

    if (difference.inDays == 0) return "Última visita: Hoy";
    if (difference.inDays == 1) return "Última visita: Hace 1 día";
    return "Última visita: Hace ${difference.inDays} días";
  }

  Future<void> _ejecutarAccionDirecta(
    BuildContext context,
    ClientsProvider provider,
    Cliente cliente,
  ) async {
    final isDeleting = cliente.activo;
    final nombreCompleto = "${cliente.nombre} ${cliente.apellidos}";

    if (isDeleting) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => DeleteConfirmDialog(
          title: 'Eliminar Paciente',
          content: '¿Estás seguro de que deseas eliminar a $nombreCompleto?',
          confirmText: 'Eliminar',
        ),
      );
      if (confirm != true) return;
    }

    String? error;
    if (isDeleting) {
      error = await provider.deleteClient(cliente.idCliente);
    } else {
      error = await provider.recoverClient(cliente.idCliente);
    }

    if (context.mounted) {
      if (error == null) {
        CustomSnackBar.show(
          context,
          message: isDeleting
              ? "Cliente $nombreCompleto eliminado"
              : "Cliente $nombreCompleto reactivado",
          type: SnackBarType.success,
        );
      } else {
        _mostrarSnack(error, Colors.red);
      }
    }
  }

  Future<void> _lanzarWhatsApp(String telefono) async {
    final num = telefono.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final uri = Uri.parse("https://wa.me/$num");

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'El sistema no pudo manejar la URL';
      }
    } catch (e) {
      if (mounted) _mostrarSnack("No se puede abrir WhatsApp", Colors.red);
    }
  }
}
