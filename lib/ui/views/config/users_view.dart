import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/modals/user_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:quiropractico_front/ui/widgets/user_avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';
import 'package:quiropractico_front/ui/widgets/premium_data_table.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final ScrollController _headerScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UsersProvider>(context, listen: false);
      if (provider.usuarios.isEmpty && !provider.isLoading) {
        provider.getUsers();
      }
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    super.dispose();
  }

  // Metodo para ordenar los usuarios
  int _getRolPriority(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return 1;
      case 'quiropráctico':
      case 'quiropractico':
        return 2;
      case 'recepción':
      case 'recepcion':
        return 3;
      default:
        return 4;
    }
  }

  Color _getRoleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return Colors.purple.shade400;
      case 'quiropráctico':
      case 'quiropractico':
        return Colors.blue.shade400;
      case 'recepción':
      case 'recepcion':
      default:
        return Colors.amber.shade500;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: PremiumDataTable<Usuario>(
        items: usuariosOrdenados,
        isLoading: provider.isLoading,
        wrapInCard: true,
        columnFlexes: const [1, 4, 3, 2, 2],
        columnHeaders: [
          _buildHeaderCell("ID", alignment: Alignment.centerLeft),
          _buildHeaderCell("Usuario", alignment: Alignment.centerLeft),
          _buildHeaderCell("Credencial", alignment: Alignment.centerLeft),
          _buildHeaderCell("Rol", alignment: Alignment.centerLeft),
          _buildHeaderCell("Acciones", alignment: Alignment.centerRight),
        ],
        topContent: _buildHeaderTopControls(context, provider),
        bottomContent: _buildPaginationControls(context, provider),
        emptyStateBuilder: (_) => _buildEmptyState(provider, mensajeVacio),
        rowBuilder: (context, usuario, index) {
          return _buildRowItem(context, provider, usuario);
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

  Widget _buildHeaderTopControls(BuildContext context, UsersProvider provider) {
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
                            Icons.people_alt_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Gestionar Equipo',
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
    UsersProvider provider,
    Usuario usuario,
  ) {
    final bool isBlocked = !usuario.activo || usuario.cuentaBloqueada;
    final Color roleColor = _getRoleColor(usuario.rol);
    final Color accentBorderColor = isBlocked ? Colors.red.shade500 : roleColor;
    final colorTexto = isBlocked ? Colors.grey : Colors.black87;
    final textDecoration = isBlocked ? TextDecoration.lineThrough : null;

    return Tooltip(
      message: "Ver perfil de ${usuario.nombreCompleto}",
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: () {
          context.push('/perfil/${usuario.idUsuario}');
        },
        hoverColor: Colors.grey.shade100.withValues(alpha: 0.5),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentBorderColor, width: 4.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.45),
          child: Row(
            children: [
              // 1. ID (Flex 1)
              Expanded(
                flex: 1,
                child: Text(
                  "#${usuario.idUsuario}",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: isBlocked ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    decoration: textDecoration,
                  ),
                ),
              ),

              // 2. Usuario (Flex 4)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _buildUserAvatar(usuario, roleColor, isBlocked),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  usuario.nombreCompleto,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorTexto,
                                    decoration: textDecoration,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBlocked) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: "Cuenta bloqueada",
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (_) => UserModal(usuarioExistente: usuario),
                                        );
                                        if (result != null && result is Map) {
                                          _handleUserFeedback(result);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "Bloq.",
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tiempoDesde(usuario.ultimaConexion),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Credencial (Flex 3)
              Expanded(
                flex: 3,
                child: Text(
                  usuario.username,
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 15,
                    decoration: textDecoration,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 4. Rol (Flex 2)
              Expanded(
                flex: 2,
                child: _buildRoleCell(usuario, roleColor),
              ),

              // 5. Acciones (Flex 2)
              Expanded(
                flex: 2,
                child: _buildActionsCell(context, provider, usuario, isBlocked),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Usuario usuario, Color roleColor, bool isBlocked) {
    Widget avatar = UserAvatarWidget(
      usuario: usuario,
      backgroundColor: roleColor,
      radius: 18,
      fontSize: 14,
    );

    if (isBlocked) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildRoleCell(Usuario usuario, Color roleColor) {
    final String formattedRole = usuario.rol.isNotEmpty
        ? usuario.rol[0].toUpperCase() + usuario.rol.substring(1).toLowerCase()
        : usuario.rol;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: roleColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              formattedRole,
              style: TextStyle(
                color: roleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(
    BuildContext context,
    UsersProvider provider,
    Usuario usuario,
    bool isBlocked,
  ) {
    Widget editButton = IconButton(
      tooltip: "Editar",
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.edit_outlined,
        color: AppTheme.primaryColor,
        size: 20,
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
    );

    if (isBlocked) {
      editButton = Badge(
        backgroundColor: Colors.red,
        smallSize: 10,
        child: editButton,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        editButton,
        const SizedBox(width: 8),
        IconButton(
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
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

            if (isDeleting) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteConfirmDialog(
                  title: 'Eliminar Empleado',
                  content:
                      '¿Estás seguro de eliminar a ${usuario.nombreCompleto}?',
                  confirmText: 'Eliminar',
                ),
              );
              if (confirm != true) return;
            }

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
    );
  }

  Widget _buildEmptyState(UsersProvider provider, String mensajeVacio) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_outlined,
                size: 40,
                color: Colors.purple.shade400,
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

  Widget _buildPaginationControls(BuildContext context, UsersProvider provider) {
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
                    ? () => provider.getUsers(page: provider.currentPage - 1)
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
                    ? () => provider.getUsers(page: provider.currentPage + 1)
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
        undoMsg = "";
        break;
      case 'recover':
        msg = "Usuario $nombre reactivado";
        undoMsg = "";
        break;
      case 'unlock':
        msg = "Usuario $nombre desbloqueado";
        undoMsg = "";
        break;
    }

    CustomSnackBar.show(
      context,
      messenger: messenger,
      message: msg,
      type: SnackBarType.success,
      actionLabel: undoMsg.isNotEmpty ? "DESHACER" : null,
      onAction: undoMsg.isNotEmpty
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

