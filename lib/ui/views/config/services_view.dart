import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/ui/modals/service_modal.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:quiropractico_front/ui/widgets/premium_data_table.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  final ScrollController _headerScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServicesProvider>(context, listen: false);
      if (provider.servicios.isEmpty && !provider.isLoading) {
        provider.loadServices();
      }
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServicesProvider>(context);
    String mensajeVacio;
    if (provider.filterActive == true) {
      mensajeVacio = "No hay servicios activos";
    } else if (provider.filterActive == false) {
      mensajeVacio = "No hay servicios inactivos";
    } else {
      mensajeVacio = "No hay servicios registrados";
    }

    // Ordenar lista
    final List<Servicio> serviciosOrdenados = List.from(provider.servicios);

    serviciosOrdenados.sort((a, b) {
      final esBonoA = a.tipo.toLowerCase() == 'bono';
      final esBonoB = b.tipo.toLowerCase() == 'bono';

      if (esBonoA && !esBonoB) {
        return -1;
      }
      if (!esBonoA && esBonoB) {
        return 1;
      }
      int comparacionPrecio = b.precio.compareTo(a.precio);
      if (comparacionPrecio != 0) {
        return comparacionPrecio;
      }
      return b.idServicio.compareTo(a.idServicio);
    });

    // Slicing local para client-side pagination
    final int start = provider.currentPage * provider.pageSize;
    final int end = (start + provider.pageSize < serviciosOrdenados.length) 
        ? start + provider.pageSize 
        : serviciosOrdenados.length;
        
    final List<Servicio> serviciosPaginados = serviciosOrdenados.length > provider.pageSize 
        ? serviciosOrdenados.sublist(start, end)
        : serviciosOrdenados;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: PremiumDataTable<Servicio>(
        items: serviciosPaginados,
        isLoading: provider.isLoading,
        wrapInCard: true,
        columnFlexes: const [1, 4, 2, 2, 1, 2],
        columnHeaders: [
          _buildHeaderCell("ID", alignment: Alignment.centerLeft),
          _buildHeaderCell("Nombre", alignment: Alignment.centerLeft),
          _buildHeaderCell("Tipo", alignment: Alignment.centerLeft),
          _buildHeaderCell("Precio", alignment: Alignment.center),
          _buildHeaderCell("Sesiones", alignment: Alignment.center),
          _buildHeaderCell("Acciones", alignment: Alignment.centerRight),
        ],
        topContent: _buildHeaderTopControls(context, provider),
        bottomContent: _buildPaginationControls(context, provider),
        emptyStateBuilder: (_) => _buildEmptyState(provider, mensajeVacio),
        rowBuilder: (context, servicio, index) {
          return _buildRowItem(context, provider, servicio);
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

  Widget _buildHeaderTopControls(BuildContext context, ServicesProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                padding: const EdgeInsets.only(bottom: 4),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // GRUPO IZQUIERDO: Título
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            Icons.price_change_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Gestionar Servicios",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),

                      // GRUPO DERECHO: Filtro + Botón
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DashboardDropdown<bool?>(
                            tooltip: "Estado",
                            selectedValue: provider.filterActive,
                            onSelected: (val) => provider.setFilter(val),
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
                          ),

                          const SizedBox(width: 15),
                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                          const SizedBox(width: 15),

                          // Botón Nuevo
                          HoverableActionButton(
                            icon: Icons.playlist_add,
                            label: "Servicio",
                            tooltip: "Crear servicio",
                            isPrimary: true,
                            onTap: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (_) => const ServiceModal(),
                              );
                              if (result != null && result is Map) {
                                _handleServiceFeedback(result);
                              }
                            },
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

  Widget _buildRowItem(
    BuildContext context,
    ServicesProvider provider,
    Servicio servicio,
  ) {
    final bool isInactive = !servicio.activo;
    final bool esBono = servicio.tipo.toLowerCase() == 'bono';
    final Color colorTipo = isInactive
        ? Colors.grey.shade400
        : (esBono ? Colors.blue.shade400 : Colors.purple.shade400);
    final Color textColor = isInactive ? Colors.grey : Colors.black87;
    final TextDecoration? textDecoration = isInactive ? TextDecoration.lineThrough : null;

    return Tooltip(
      message: "Editar ${servicio.nombreServicio}",
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: () async {
          final result = await showDialog(
            context: context,
            builder: (_) => ServiceModal(servicioExistente: servicio),
          );
          if (result != null && result is Map) {
            _handleServiceFeedback(result);
          }
        },
        hoverColor: Colors.grey.shade100.withValues(alpha: 0.5),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorTipo, width: 4.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.4),
          child: Row(
            children: [
              // 1. ID (Flex 1) - Alineado a la izquierda
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "#${servicio.idServicio}",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isInactive ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      decoration: textDecoration,
                    ),
                  ),
                ),
              ),

              // 2. Nombre (Flex 4) - Alineado a la izquierda con maxLines: 1 y TextOverflow.ellipsis
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    servicio.nombreServicio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                      decoration: textDecoration,
                    ),
                  ),
                ),
              ),

              // 3. Tipo (Flex 2) - Chip Píldora
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTypeChip(servicio),
                ),
              ),

              // 4. Precio (Flex 2) - Alineado al centro (Alignment.center)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "${servicio.precio.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} €",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                      decoration: textDecoration,
                    ),
                  ),
                ),
              ),

              // 5. Sesiones (Flex 1) - Alineado al centro (Alignment.center)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    esBono ? "${servicio.sesiones ?? '—'}" : "—",
                    style: TextStyle(
                      fontWeight: esBono ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 15,
                      color: isInactive
                          ? Colors.grey
                          : (esBono ? Colors.black87 : Colors.grey.shade400),
                      decoration: textDecoration,
                    ),
                  ),
                ),
              ),

              // 6. Acciones (Flex 2) - Row con MainAxisAlignment.end
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => ServiceModal(servicioExistente: servicio),
                        );
                        if (result != null && result is Map) {
                          _handleServiceFeedback(result);
                        }
                      },
                      tooltip: "Editar",
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      icon: Icon(
                        servicio.activo
                            ? Icons.delete_outline
                            : Icons.restore_from_trash,
                        color: servicio.activo ? Colors.redAccent : Colors.green,
                        size: 20,
                      ),
                      tooltip: servicio.activo ? 'Eliminar' : 'Reactivar',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () async {
                        final bool estabaActivo = servicio.activo;
                        final String nombreServicio = servicio.nombreServicio;

                        if (estabaActivo) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => DeleteConfirmDialog(
                                  title: '¿Eliminar Servicio?',
                                  content:
                                      '¿Estás seguro de que deseas eliminar el servicio "$nombreServicio"?',
                                ),
                          );
                          if (confirm != true) return;
                        }

                        final messenger = ScaffoldMessenger.of(context);

                        String? error;
                        if (estabaActivo) {
                          error = await provider.deleteService(servicio.idServicio);
                        } else {
                          error = await provider.recoverService(
                            servicio.idServicio,
                          );
                        }

                        if (context.mounted) {
                          if (error == null) {
                            CustomSnackBar.show(
                              context,
                              messenger: messenger,
                              message:
                                  estabaActivo
                                      ? "Servicio $nombreServicio eliminado"
                                      : "Servicio $nombreServicio reactivado",
                              type: SnackBarType.success,
                            );
                          } else {
                            CustomSnackBar.show(
                              context,
                              message: error,
                              type: SnackBarType.error,
                            );
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
      ),
    );
  }

  Widget _buildTypeChip(Servicio servicio) {
    final bool esBono = servicio.tipo.toLowerCase() == 'bono';
    final Color bgColor = esBono ? Colors.blue.shade50 : Colors.purple.shade50;
    final Color fgColor = esBono ? Colors.blue.shade600 : Colors.purple.shade600;
    final String textLabel = esBono ? 'Bono' : 'Sesión';

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fgColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              textLabel,
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ServicesProvider provider, String mensajeVacio) {
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
                Icons.price_change_outlined,
                size: 40,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensajeVacio,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, ServicesProvider provider) {
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
                    ? () => provider.loadServices(page: provider.currentPage - 1)
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
                    ? () => provider.loadServices(page: provider.currentPage + 1)
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

  void _handleServiceFeedback(Map result) {
    final action = result['action'];
    final nombre = result['nombre'];

    final messenger = ScaffoldMessenger.of(context);

    final String msg =
        action == 'create'
            ? "Servicio $nombre creado"
            : "Servicio $nombre actualizado";

    CustomSnackBar.show(
      context,
      messenger: messenger,
      message: msg,
      type: SnackBarType.success,
    );
  }
}
