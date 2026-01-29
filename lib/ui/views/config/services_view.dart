import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/ui/modals/service_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';

import 'package:quiropractico_front/ui/widgets/paginated_table.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
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

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(height: 40, width: 10),
                Icon(
                  Icons.price_change_outlined,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  "Gestionar Servicios",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const Spacer(),

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
          ),

          const SizedBox(height: 20),

          // TABLA
          Expanded(
            child: PaginatedTable(
              isLoading: provider.isLoading,
              isEmpty: serviciosOrdenados.isEmpty,
              emptyMessage: mensajeVacio,
              totalElements: provider.totalElements,
              pageSize: provider.pageSize,
              currentPage: provider.currentPage,
              onPageChanged: (page) => provider.loadServices(page: page),
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
                    "Nombre",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Tipo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Precio",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Sesiones",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Acciones",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              rows: _generateRows(serviciosOrdenados, provider, context),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _generateRows(
    List<Servicio> serviciosOrdenados,
    ServicesProvider provider,
    BuildContext context,
  ) {
    if (serviciosOrdenados.isEmpty) return [];

    final int start = provider.currentPage * provider.pageSize;

    return serviciosOrdenados.asMap().entries.map((entry) {
      final int index = start + entry.key + 1;
      final Servicio servicio = entry.value;
      final bool esBono = servicio.tipo.toLowerCase() == 'bono';

      // Colores
      final Color baseColor = esBono ? Colors.blue : Colors.purple;
      final Color rowColor =
          servicio.activo ? baseColor.withOpacity(0.04) : Colors.grey.shade50;
      final Color textColor = servicio.activo ? Colors.black87 : Colors.grey;

      return DataRow(
        color: WidgetStateProperty.all(rowColor),
        cells: [
          // Indice
          DataCell(
            Text(
              "$index",
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Nombre
          DataCell(
            Text(
              servicio.nombreServicio,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: servicio.activo ? null : TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Tipo (Chip)
          DataCell(
            Chip(
              backgroundColor: baseColor.withOpacity(0.1),
              side: BorderSide(color: baseColor),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              label: Text(
                esBono ? 'BONO' : 'SESIÓN',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Precio
          DataCell(
            Text(
              "${servicio.precio} €",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),

          // Sesiones
          DataCell(
            esBono
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    "${servicio.sesiones}",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                : Text(
                  "-",
                  style: TextStyle(color: textColor.withOpacity(0.5)),
                ),
          ),

          // Acciones
          DataCell(
            Row(
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
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 15),

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
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final bool estabaActivo = servicio.activo;
                    final String nombreServicio = servicio.nombreServicio;
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
                          actionLabel: "DESHACER",
                          onAction: () async {
                            messenger.hideCurrentSnackBar();
                            if (estabaActivo) {
                              // Estaba activo, se eliminó -> Recuperar
                              await provider.recoverService(
                                servicio.idServicio,
                              );
                            } else {
                              // Estaba inactivo, se recuperó -> Eliminar
                              await provider.deleteService(servicio.idServicio);
                            }

                            if (context.mounted) {
                              CustomSnackBar.show(
                                context,
                                message:
                                    estabaActivo
                                        ? "Eliminación deshecha"
                                        : "Reactivación deshecha",
                                type: SnackBarType.info,
                              );
                            }
                          },
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
      );
    }).toList();
  }

  void _handleServiceFeedback(Map result) {
    final action = result['action'];
    final nombre = result['nombre'];
    final Servicio? oldData = result['oldData'];

    final provider = Provider.of<ServicesProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Mensaje inicial
    final String msg =
        action == 'create'
            ? "Servicio $nombre creado"
            : "Servicio $nombre actualizado";

    CustomSnackBar.show(
      context,
      messenger: messenger,
      message: msg,
      type: SnackBarType.success,
      actionLabel: "DESHACER",
      onAction: () async {
        messenger.hideCurrentSnackBar();

        String? errorUndo;
        if (action == 'create') {
          // Deshacer creación = Borrar
          try {
            // Fallback: buscar por nombre si no tenemos ID (aunque idealmente deberiamos tenerlo)
            final servicioCreado = provider.servicios.firstWhere(
              (s) => s.nombreServicio == nombre && s.activo,
              orElse: () => provider.servicios.first,
            );
            errorUndo = await provider.deleteService(servicioCreado.idServicio);
          } catch (e) {
            errorUndo = "No se pudo localizar el servicio para deshacer";
          }
        } else {
          // Deshacer edición = Restaurar oldData
          if (oldData != null) {
            errorUndo = await provider.updateService(
              oldData.idServicio,
              oldData.nombreServicio,
              oldData.precio,
              oldData.tipo,
              oldData.sesiones,
            );
          }
        }

        if (context.mounted) {
          if (errorUndo == null) {
            CustomSnackBar.show(
              context,
              message:
                  action == 'create' ? "Creación deshecha" : "Edición deshecha",
              type: SnackBarType.info,
            );
          } else {
            CustomSnackBar.show(
              context,
              message: "Error al deshacer: $errorUndo",
              type: SnackBarType.error,
            );
          }
        }
      },
    );
  }
}
