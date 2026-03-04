import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/paginated_table.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';

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

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thickness: WidgetStateProperty.all(4),
                    radius: const Radius.circular(4),
                    thumbColor: WidgetStateProperty.all(
                      Colors.grey.withOpacity(0.35),
                    ),
                    trackColor: WidgetStateProperty.all(Colors.transparent),
                    trackBorderColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
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
                                  width: (constraints.maxWidth - 670).clamp(
                                    200.0,
                                    400.0,
                                  ),
                                  child: TextField(
                                    controller: searchCtrl,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Buscar por nombre, apellido o teléfono',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                      suffixIcon:
                                          searchCtrl.text.isNotEmpty
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
                                // Filtro estado
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

                                // Filtro actividad reciente
                                Tooltip(
                                  message: "Filtrar por actividad reciente",
                                  child: _buildActivityDropdown(
                                    clientsProvider,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 10),

                                // Nuevo cliente
                                Tooltip(
                                  message: "Crear paciente",
                                  child: HoverableActionButton(
                                    label: "Paciente",
                                    icon: Icons.person_add,
                                    isPrimary: true,
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => const ClientModal(),
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
          ),

          const SizedBox(height: 20),

          // TABLA
          Expanded(
            child: PaginatedTable(
              isLoading: clientsProvider.isLoading,
              isEmpty: clientes.isEmpty,
              emptyMessage: "No se encuentran pacientes",
              totalElements: clientsProvider.totalElements,
              pageSize: clientsProvider.pageSize,
              currentPage: clientsProvider.currentPage,
              rowSpacing: 8.0,
              hoverElevation: 0.0,
              enableSmoothTransitions: true,
              onPageChanged: (page) {
                clientsProvider.loadClients(page: page);
              },
              columns: const [
                DataColumn(
                  label: Text(
                    "Id",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Nombre Completo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Email",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Teléfono",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Acciones",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              rows:
                  clientes.asMap().entries.map((entry) {
                    final cliente = entry.value;

                    final isDeleted = !cliente.activo;
                    final textColor = isDeleted ? Colors.grey : Colors.black87;
                    final textDecoration = isDeleted ? TextDecoration.lineThrough : null;

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        // Hover effect más marcado
                        if (states.contains(WidgetState.hovered)) {
                          return isDeleted
                              ? Colors.red.withOpacity(0.12)
                              : Colors.blue.shade50.withOpacity(0.5);
                        }
                        // Default colors - white para filas normales
                        return isDeleted
                            ? Colors.red.withOpacity(0.05)
                            : Colors.white;
                      }),
                      onSelectChanged: (_) {
                        context.go('/pacientes/${cliente.idCliente}');
                      },
                      cells: [
                        DataCell(
                          Text(
                            "#${cliente.idCliente}",
                            style: TextStyle(
                              color:
                                  isDeleted
                                      ? Colors.grey[300]
                                      : Colors.grey[400],
                              fontWeight: FontWeight.w400,
                              decoration: textDecoration,
                            ),
                          ),
                        ),
                        // Nombre + Avatar + Última Visita
                        DataCell(
                          Tooltip(
                            message: "Ver detalles de ${cliente.nombre}",
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  AvatarWidget(
                                    nombreCompleto: cliente.nombre,
                                    id: cliente.idCliente,
                                    radius: 16,
                                    fontSize: 14,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Nombre + Chips en la misma fila
                                      Row(
                                        children: [
                                          Text(
                                            '${cliente.nombre} ${cliente.apellidos}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                              decoration: textDecoration,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Chips al lado del nombre
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
                                      // Última visita debajo
                                      if (cliente.ultimaCita != null)
                                        Text(
                                          _formatLastVisit(cliente.ultimaCita!),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        )
                                      else
                                        Text(
                                          "Sin citas",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Email
                        DataCell(
                          Text(
                            cliente.email ?? '-',
                            style: TextStyle(
                              color: textColor,
                              decoration: textDecoration,
                            ),
                          ),
                        ),
                        // Telefono (WhatsApp)
                        DataCell(
                          Tooltip(
                            message: "Ir a WhatsApp",
                            child: InkWell(
                              onTap: () => _lanzarWhatsApp(cliente.telefono),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      size: 16,
                                      color:
                                          isDeleted
                                              ? Colors.grey
                                              : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cliente.telefono,
                                      style: TextStyle(
                                        color:
                                            isDeleted
                                                ? Colors.grey
                                                : Colors.blueGrey,
                                        decoration: textDecoration,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Acciones
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón Crear Cita
                              IconButton(
                                icon: const Icon(
                                  Icons.event_available,
                                  color: Colors.blue,
                                ),
                                tooltip: "Crear cita para ${cliente.nombre}",
                                onPressed: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder:
                                        (_) => CitaModal(
                                          preSelectedClient: cliente,
                                        ),
                                  );
                                  // Si se creó cita (result != null), recargar solo este cliente
                                  if (result != null) {
                                    clientsProvider.reloadClient(
                                      cliente.idCliente,
                                    );
                                  }
                                },
                              ),
                              // Botón Editar
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                tooltip: "Editar",
                                onPressed: () async {
                                  final changed = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => ClientModal(
                                          clienteExistente: cliente,
                                        ),
                                  );
                                  // Si hubo cambios, recargar solo este cliente
                                  if (changed == true) {
                                    clientsProvider.reloadClient(
                                      cliente.idCliente,
                                    );
                                  }
                                },
                              ),
                              // Botón Eliminar/Reactivar
                              IconButton(
                                icon: Icon(
                                  isDeleted
                                      ? Icons.restore_from_trash
                                      : Icons.delete_outline,
                                  color:
                                      isDeleted
                                          ? Colors.green
                                          : Colors.redAccent,
                                ),
                                tooltip: isDeleted ? 'Reactivar' : 'Eliminar',
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
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown estilizado como en PaymentsView
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
        hoverColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
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
    // Navegar a cliente detalle con tab de citas (índice 0) y filtro programada
    context.go('/pacientes/$clienteId?tab=0&filtro=programada');
  }

  void _navigateToBonosTab(BuildContext context, int clienteId) {
    // Navegar a cliente detalle con tab de bonos (índice 1)
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
    dynamic cliente,
  ) async {
    final isDeleting = cliente.activo;
    final nombreCompleto = "${cliente.nombre} ${cliente.apellidos}";

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
          message:
              isDeleting
                  ? "Cliente $nombreCompleto eliminado"
                  : "Cliente $nombreCompleto reactivado",
          type: SnackBarType.success,
          actionLabel: isDeleting ? "DESHACER" : null,
          onAction:
              isDeleting
                  ? () async {
                    await provider.recoverClient(cliente.idCliente);
                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        message: "Borrado deshecho",
                        type: SnackBarType.info,
                      );
                    }
                  }
                  : null,
        );
      } else {
        _mostrarSnack(error, Colors.red);
      }
    }
  }

  Future<void> _lanzarWhatsApp(String telefono) async {
    // Normalizar telefono (quitar espacios, guiones, etc)
    final num = telefono.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final uri = Uri.parse("https://wa.me/$num");

    try {
      // Intentar primero con externalApplication
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'El sistema no pudo manejar la URL';
      }
    } catch (e) {
      if (mounted) _mostrarSnack("No se puede abrir WhatsApp", Colors.red);
    }
  }
}
