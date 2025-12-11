import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/modals/user_modal.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {

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

    return Column(
      children: [
        Row(
          children: [
            
            const Text("Gestión de Equipo", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            
            const Spacer(),

            // FILTRO
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
                  DropdownMenuItem(value: false, child: Text("Papelera")),
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
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.usuarios.isEmpty 
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
                            columns: const [
                              DataColumn(label: Text("Nombre")),
                              DataColumn(label: Text("Usuario")),
                              DataColumn(label: Text("Rol")),
                              DataColumn(label: Text("Acciones", textAlign: TextAlign.end)),
                            ],
                            rows: provider.usuarios.map((usuario) {
                              final colorTexto = usuario.activo ? Colors.black87 : Colors.grey;
                              Color colorRol;
                              switch(usuario.rol.toLowerCase()) {
                                case 'admin': colorRol = Colors.purple; break;
                                case 'quiropráctico': colorRol = Colors.blue; break;
                                default: colorRol = Colors.orange;
                              }
                              return DataRow(
                                color: MaterialStateProperty.resolveWith<Color?>((states) {
                                  return usuario.cuentaBloqueada ? Colors.red.withOpacity(0.05) : null; 
                                }),
                                cells: [
                                  DataCell(Text(usuario.nombreCompleto, style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold))),
                                  DataCell(Text(usuario.username, style: TextStyle(color: colorTexto))),
                                  // CHIP
                                  DataCell(
                                    Center(
                                      child: Chip(
                                        backgroundColor: colorRol.withOpacity(0.1),
                                        side: BorderSide(color: colorRol),
                                        padding: const EdgeInsets.all(0), 
                                        label: SizedBox(
                                          width: 85, 
                                          child: Text(
                                            usuario.rol.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colorRol, 
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
                                          tooltip: usuario.activo ? 'Desactivar' : 'Reactivar',
                                          onPressed: () async {
                                            // DIÁLOGO DE CONFIRMACIÓN
                                            final isDeleting = usuario.activo;
                                            final confirm = await showDialog(
                                                context: context, 
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(isDeleting ? "¿Desactivar usuario?" : "¿Reactivar usuario?"),
                                                  content: Text("Vas a ${isDeleting ? 'quitar' : 'devolver'} el acceso a ${usuario.username}."),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      style: ElevatedButton.styleFrom(backgroundColor: isDeleting ? Colors.red : Colors.green, foregroundColor: Colors.white), 
                                                      child: Text(isDeleting ? "Desactivar" : "Reactivar")
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
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isDeleting ? 'Usuario eliminado' : 'Usuario reactivado'), backgroundColor: Colors.green));
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
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