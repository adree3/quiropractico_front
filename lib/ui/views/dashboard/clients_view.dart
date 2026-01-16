import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/paginated_table.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  Timer? _debounce;
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 15),
                // Buscador
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
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
                          contentPadding: const EdgeInsets.symmetric(
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
                  ),
                ),
                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 15),

                // Filtro estado
                _buildStatusDropdown(clientsProvider),

                const SizedBox(width: 10),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 10),

                // Nuevo cliente
                _HoverableActionButton(
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TABLA
          Expanded(
            child: PaginatedTable(
              isLoading: clientsProvider.isLoading,
              isEmpty: clientes.isEmpty,
              emptyMessage: "No hay pacientes registrados",
              totalElements: clientsProvider.totalElements,
              pageSize: clientsProvider.pageSize,
              currentPage: clientsProvider.currentPage,
              onPageChanged: (page) {
                if (clientsProvider.isSearching) {
                  clientsProvider.searchGlobal(
                    clientsProvider.currentSearchTerm,
                    page: page,
                  );
                } else {
                  clientsProvider.getPaginatedClients(page: page);
                }
              },
              columns: const [
                DataColumn(
                  label: Text(
                    "#",
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
                    final index = entry.key;
                    final realIndex =
                        (clientsProvider.currentPage *
                            clientsProvider.pageSize) +
                        index +
                        1;
                    final rowColor =
                        !clientsProvider.filterActive
                            ? Colors.grey.shade50
                            : null;

                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Text(
                            "$realIndex",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  cliente.nombre.isNotEmpty
                                      ? cliente.nombre[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${cliente.nombre} ${cliente.apellidos}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(cliente.telefono)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                tooltip: 'Detalles',
                                onPressed:
                                    () => context.go(
                                      '/pacientes/${cliente.idCliente}',
                                    ),
                              ),
                              IconButton(
                                icon: Icon(
                                  clientsProvider.filterActive
                                      ? Icons.delete_outline
                                      : Icons.restore_from_trash,
                                  color:
                                      clientsProvider.filterActive
                                          ? Colors.redAccent
                                          : Colors.green,
                                ),
                                tooltip:
                                    clientsProvider.filterActive
                                        ? 'Eliminar'
                                        : 'Reactivar',
                                onPressed: () async {
                                  _confirmarAccion(
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
    return DashboardDropdown<bool>(
      selectedValue: provider.filterActive,
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
      ],
    );
  }

  // Confirmacion de eliminar paciente
  Future<void> _confirmarAccion(
    BuildContext context,
    ClientsProvider provider,
    dynamic cliente,
  ) async {
    final isDeleting = provider.filterActive;
    final title = isDeleting ? "¿Eliminar paciente?" : "¿Reactivar paciente?";
    final content =
        isDeleting
            ? "Se moverá a la papelera."
            : "Volverá a aparecer en la lista de activos.";
    final actionColor = isDeleting ? Colors.red : Colors.green;

    final confirm = await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(isDeleting ? "Eliminar" : "Reactivar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      String? error;
      if (isDeleting) {
        error = await provider.deleteClient(cliente.idCliente);
      } else {
        error = await provider.recoverClient(cliente.idCliente);
      }

      if (context.mounted) {
        if (error == null) {
          _mostrarSnack(
            isDeleting ? "Paciente borrado" : "Paciente reactivado",
            Colors.green,
          );
        } else {
          _mostrarSnack(error, Colors.red);
        }
      }
    }
  }
}

// BOTÓN HOVERABLE (Igual que en Auditoría pero adaptado)
class _HoverableActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isPrimary;

  const _HoverableActionButton({
    required this.onTap,
    required this.label,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  State<_HoverableActionButton> createState() => _HoverableActionButtonState();
}

class _HoverableActionButtonState extends State<_HoverableActionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isPrimary
                    ? (_isHovering
                        ? AppTheme.primaryColor.withOpacity(0.9)
                        : AppTheme.primaryColor)
                    : (_isHovering ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            // Sombra suave si es primario
            boxShadow:
                widget.isPrimary
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
