import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/modals/user_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/paginated_table.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  // Metodo para ordenar los usuarios
  int _getRolPriority(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return 1;
      case 'quiropráctico':
        return 2;
      case 'recepción':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UsersProvider>(context);

    String mensajeVacio;
    if (provider.filterActive == true) {
      mensajeVacio = "No hay usuarios activos";
    } else if (provider.filterActive == false) {
      mensajeVacio = "No hay usuarios eliminados";
    } else {
      mensajeVacio = "No hay usuarios registrados";
    }

    final List<Usuario> usuariosOrdenados = List.from(provider.usuarios);

    usuariosOrdenados.sort((a, b) {
      final priorityA = _getRolPriority(a.rol);
      final priorityB = _getRolPriority(b.rol);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      return b.idUsuario.compareTo(a.idUsuario);
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        children: [
          // Cabecera
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
                  Icons.people_alt_outlined,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestionar Equipo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(),

                // FILTRO ESTADO
                DashboardDropdown<bool?>(
                  tooltip: "Filtrar estado",
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

                // Boton
                HoverableActionButton(
                  label: "Empleado",
                  icon: Icons.person_add,
                  tooltip: "Crear empleado",
                  isPrimary: true,
                  onTap: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => const UserModal(),
                    );
                    if (result != null && result is Map) {
                      _handleUserFeedback(result);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tabla
          Expanded(
            child: PaginatedTable(
              isLoading: provider.isLoading,
              isEmpty: usuariosOrdenados.isEmpty,
              emptyMessage: mensajeVacio,
              totalElements: provider.totalElements,
              pageSize: provider.pageSize,
              currentPage: provider.currentPage,
              onPageChanged: (page) => provider.getUsers(page: page),
              columns: const [
                DataColumn(
                  label: Flexible(
                    child: Text(
                      "id",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Flexible(
                    child: Text(
                      "Nombre",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Flexible(
                    child: Text(
                      "Usuario",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Flexible(
                    child: Text(
                      "Rol",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Flexible(
                    child: Text(
                      "Acciones",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
              rows: _generateRows(usuariosOrdenados, provider),
              rowSpacing: 8.0,
              hoverElevation: 0.0,
              enableSmoothTransitions: true,
            ),
          ),
        ],
      ),
    );
  }

  // Generar filas (ya vienen paginadas del backend)
  List<DataRow> _generateRows(List<Usuario> usuarios, UsersProvider provider) {
    if (usuarios.isEmpty) return [];

    return usuarios.map((usuario) {
      final colorTexto = usuario.activo ? Colors.black87 : Colors.grey;
      final textDecoration = usuario.activo ? null : TextDecoration.lineThrough;

      Color baseColor;
      switch (usuario.rol.toLowerCase()) {
        case 'admin':
          baseColor = Colors.purple;
          break;
        case 'quiropráctico':
          baseColor = Colors.blue;
          break;
        default:
          baseColor = Colors.orange;
      }

      final rowColor =
          !usuario.activo ? Colors.grey.shade50 : baseColor.withOpacity(0.04);

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return usuario.activo
                ? baseColor.withOpacity(0.10)
                : Colors.grey.withOpacity(0.12);
          }
          return rowColor;
        }),
        onSelectChanged: (_) {
          // TODO: navegar al perfil del usuario cuando exista
        },
        cells: [
          DataCell(
            Text(
              "#${usuario.idUsuario}",
              style: TextStyle(
                color: usuario.activo ? Colors.grey[400] : Colors.grey[300],
                fontWeight: FontWeight.w400,
                decoration: textDecoration,
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: baseColor.withOpacity(0.1),
                  child: Text(
                    usuario.nombreCompleto.isNotEmpty
                        ? usuario.nombreCompleto[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      color: baseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: TextStyle(
                        color: colorTexto,
                        fontWeight: FontWeight.w600,
                        decoration: textDecoration,
                      ),
                    ),
                    Text(
                      _tiempoDesde(usuario.ultimaConexion),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
                if (usuario.cuentaBloqueada) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Cuenta bloqueada',
                    child: InkWell(
                      onTap: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => UserModal(usuarioExistente: usuario),
                        );
                        if (result != null && result is Map) {
                          _handleUserFeedback(result);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Chip(
                        label: const Text(
                          'BLOQUEADA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.08),
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          DataCell(
            Text(
              usuario.username,
              style: TextStyle(color: colorTexto, decoration: textDecoration),
            ),
          ),
          DataCell(
            Chip(
              backgroundColor: baseColor.withOpacity(0.1),
              side: BorderSide(color: baseColor),
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              label: Text(
                usuario.rol.toUpperCase(),
                style: TextStyle(
                  color: baseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Editar",
                  splashRadius: 20,
                  icon: Badge(
                    isLabelVisible: usuario.cuentaBloqueada,
                    smallSize: 8,
                    backgroundColor: Colors.red,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => UserModal(usuarioExistente: usuario),
                    );
                    if (result != null && result is Map) {
                      _handleUserFeedback(result);
                    }
                  },
                ),
                const SizedBox(width: 10),
                IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    usuario.activo
                        ? Icons.delete_outline
                        : Icons.restore_from_trash,
                    color: usuario.activo ? Colors.redAccent : Colors.green,
                    size: 20,
                  ),
                  tooltip: usuario.activo ? 'Eliminar' : 'Reactivar',
                  onPressed: () async {
                    final isDeleting = usuario.activo;
                    String? error;
                    if (isDeleting) {
                      error = await provider.deleteUser(usuario.idUsuario);
                    } else {
                      error = await provider.recoverUser(usuario.idUsuario);
                    }

                    if (context.mounted) {
                      if (error == null) {
                        _handleUserFeedback({
                          'action': isDeleting ? 'delete' : 'recover',
                          'nombre': usuario.nombreCompleto,
                          'username': usuario.username,
                          'oldData': usuario,
                        });
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

  // Formatea el tiempo desde la última conexión
  String _tiempoDesde(DateTime? dt) {
    if (dt == null) return 'Sin conexiones registradas';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'hace 1 día';
    return 'hace ${diff.inDays} días';
  }

  void _handleUserFeedback(Map result) {
    final action = result['action'];
    final nombre = result['nombre'];
    final username = result['username'];
    final Usuario? oldData = result['oldData'];

    final provider = Provider.of<UsersProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    String msg = "";
    String undoMsg = "";

    switch (action) {
      case 'create':
        msg = "Usuario $nombre creado";
        undoMsg = "Creación deshecha";
        break;
      case 'update':
        msg = "Usuario $nombre actualizado";
        undoMsg = "Edición deshecha";
        break;
      case 'delete':
        msg = "Usuario $nombre eliminado";
        undoMsg = "Eliminación deshecha";
        break;
      case 'recover':
        msg = "Usuario $nombre reactivado";
        undoMsg = "Reactivación deshecha";
        break;
      case 'unlock':
        msg = "Usuario $nombre desbloqueado";
        undoMsg = "Desbloqueo deshecho";
        break;
    }

    CustomSnackBar.show(
      context,
      messenger: messenger,
      message: msg,
      type: SnackBarType.success,
      actionLabel: undoMsg.isNotEmpty ? "DESHACER" : null,
      onAction:
          undoMsg.isNotEmpty
              ? () async {
                messenger.hideCurrentSnackBar();
                String? errorUndo;

                try {
                  if (action == 'create') {
                    final userToDelete = provider.usuarios.firstWhere(
                      (u) => u.username == username,
                      orElse: () => throw "Usuario no encontrado",
                    );
                    errorUndo = await provider.deleteUser(
                      userToDelete.idUsuario,
                    );
                  } else if (action == 'update' && oldData != null) {
                    errorUndo = await provider.updateUser(
                      oldData.idUsuario,
                      oldData.nombreCompleto,
                      null,
                      oldData.rol,
                    );
                  } else if (action == 'delete' && oldData != null) {
                    errorUndo = await provider.recoverUser(oldData.idUsuario);
                  } else if (action == 'recover' && oldData != null) {
                    errorUndo = await provider.deleteUser(oldData.idUsuario);
                  } else if (action == 'unlock' && oldData != null) {
                    errorUndo = await provider.blockUser(oldData.idUsuario);
                  }
                } catch (e) {
                  errorUndo = "No se pudo deshacer: $e";
                }

                if (context.mounted) {
                  if (errorUndo == null) {
                    CustomSnackBar.show(
                      context,
                      message: undoMsg,
                      type: SnackBarType.info,
                    );
                  } else {
                    CustomSnackBar.show(
                      context,
                      message: errorUndo,
                      type: SnackBarType.error,
                    );
                  }
                }
              }
              : null,
    );
  }
}
