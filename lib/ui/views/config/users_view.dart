import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/modals/user_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {

  // Metodo para ordenar los usuarios
  int _getRolPriority(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin': return 1;
      case 'quiropráctico': return 2;
      case 'recepción': return 3;
      default: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UsersProvider>(context);

    String mensajeVacio;
    if (provider.filterActive == true) {
      mensajeVacio = "No hay usuarios activos";
    } else if (provider.filterActive == false) {
      mensajeVacio = "No hay usuarios inactivos (papelera vacía)";
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

    return Column(
      children: [
        // Cabecera
        Row(
          children: [
            const Text("Gestión de Equipo", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: DropdownButton<bool?>(
                value: provider.filterActive, 
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: Colors.grey),
                items: const [
                  DropdownMenuItem(value: true, child: Text("Activos")),
                  DropdownMenuItem(value: false, child: Text("Eliminados")),
                  DropdownMenuItem(value: null, child: Text("Todos")),
                ],
                onChanged: (val) => provider.setFilter(val),
              ),
            ),

            const SizedBox(width: 15),

            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const UserModal()),
              icon: const Icon(Icons.person_add),
              label: const Text("Nuevo Empleado"),
            )
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usuariosOrdenados.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 50, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(mensajeVacio, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                            columnSpacing: 30,
                            dataRowMinHeight: 60,
                            dataRowMaxHeight: 60,
                            columns: const [
                              DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                              DataColumn(label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Usuario", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(
                                label: Expanded( 
                                  child: Center( 
                                    child: Text("Rol", style: TextStyle(fontWeight: FontWeight.bold))
                                  )
                                )
                              ),
                              DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                            ],
                            rows: usuariosOrdenados.asMap().entries.map((entry) {
                              final int index = entry.key + 1;
                              final Usuario usuario = entry.value;
                              final colorTexto = usuario.activo ? Colors.black87 : Colors.grey;
                              Color baseColor;
                              switch(usuario.rol.toLowerCase()) {
                                case 'admin': baseColor = Colors.purple; break;
                                case 'quiropráctico': baseColor = Colors.blue; break;
                                default: baseColor = Colors.orange;
                              }

                              Color rowColor;
                              if (!usuario.activo) {
                                rowColor = Colors.grey.shade50;
                              } else {
                                rowColor = baseColor.withOpacity(0.04);
                              }
                              
                              return DataRow(
                                color: MaterialStateProperty.all(rowColor),
                                cells: [
                                  // Indice
                                  DataCell(Text("$index", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
                                  // Nombre
                                  DataCell(Text(usuario.nombreCompleto, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600))),
                                  // Username
                                  DataCell(Text(usuario.username, style: TextStyle(color: colorTexto))),
                                  // CHIP
                                  DataCell(
                                    Center(
                                      child: Chip(
                                        backgroundColor: baseColor.withOpacity(0.1),
                                        side: BorderSide(color: baseColor),
                                        padding: const EdgeInsets.all(0), 
                                        label: SizedBox(
                                          width: 85, 
                                          child: Text(
                                            usuario.rol.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: baseColor, 
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis, 
                                          ),
                                        ),
                                      ),
                                    )
                                  ),
                                  
                                  // ACCIONES 
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // BOTÓN EDITAR
                                        Badge(
                                          isLabelVisible: usuario.cuentaBloqueada,
                                          smallSize: 10,
                                          backgroundColor: Colors.red,
                                          child: IconButton(
                                            tooltip: "Editar",
                                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                            onPressed: () => showDialog(context: context, builder: (_) => UserModal(usuarioExistente: usuario)),
                                          ),
                                        ),
                                        
                                        // BOTÓN ELIMINAR/REACTIVAR
                                        IconButton(
                                          icon: Icon(
                                            usuario.activo ? Icons.delete_outline : Icons.restore_from_trash,
                                            color: usuario.activo ? Colors.redAccent : Colors.green
                                          ),
                                          tooltip: usuario.activo ? 'Eliminar' : 'Reactivar',
                                          onPressed: () async {
                                            // DIÁLOGO DE CONFIRMACIÓN
                                            final isDeleting = usuario.activo;
                                            final confirm = await showDialog(
                                                context: context, 
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(isDeleting ? "¿Eliminar usuario?" : "¿Reactivar usuario?"),
                                                  content: Text("Vas a ${isDeleting ? 'eliminar' : 'reactivar'} a ${usuario.username}."),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      style: ElevatedButton.styleFrom(backgroundColor: isDeleting ? Colors.red : Colors.green, foregroundColor: Colors.white), 
                                                      child: Text(isDeleting ? "Eliminar" : "Reactivar")
                                                    ),
                                                  ],
                                                )
                                            );

                                            if (confirm == true) {
                                                String? error;
                                                if (isDeleting) {
                                                  error = await provider.deleteUser(usuario.idUsuario);
                                                } else {
                                                  error = await provider.recoverUser(usuario.idUsuario);
                                                }

                                                if (context.mounted) {
                                                  if (error == null) {
                                                    CustomSnackBar.show(context, 
                                                      message: isDeleting ? 'Usuario eliminado' : 'Usuario reactivado', 
                                                      type: SnackBarType.success
                                                    );
                                                  } else {
                                                    CustomSnackBar.show(context, 
                                                      message: error, 
                                                      type: SnackBarType.error
                                                    );
                                                  }
                                                }
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}