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
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_outlined, size: 24, color: Colors.grey.shade700),
                const SizedBox(width: 10),
                Text(
                  'Gestión de Equipo', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                
                const Spacer(),

                // FILTRO ESTADO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool?>(
                      value: provider.filterActive, 
                      hint: const Text("Estado"),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      items: [
                        DropdownMenuItem(
                          value: true, 
                          child: Row(children: const [
                            Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Activos", style: TextStyle(fontWeight: FontWeight.w500))
                          ])
                        ),
                        DropdownMenuItem(
                          value: false, 
                          child: Row(children: const [
                            Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text("Eliminados", style: TextStyle(fontWeight: FontWeight.w500))
                          ])
                        ),
                        DropdownMenuItem(
                          value: null, 
                          child: Row(children: const [
                            Icon(Icons.list, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text("Todos", style: TextStyle(fontWeight: FontWeight.w500))
                          ])
                        ),
                      ],
                      onChanged: (val) => provider.setFilter(val),
                    ),
                  ),
                ),

                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300), // Separador
                const SizedBox(width: 15),

                // Boton 
                _HoverableActionButton(
                  label: "Nuevo Empleado",
                  icon: Icons.person_add,
                  isPrimary: true,
                  onTap: () => showDialog(context: context, builder: (_) => const UserModal()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Tabla
          Expanded(
            child: Container(
              width: double.infinity, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))] // Misma sombra
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                      columnSpacing: 20,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,

                                      border: const TableBorder(bottom: BorderSide(color: Colors.transparent)),
                                      
                                      columns: const [
                                        DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                        DataColumn(label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Usuario", style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Rol", style: TextStyle(fontWeight: FontWeight.bold))),
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
      
                                        final rowColor = !usuario.activo 
                                            ? Colors.grey.shade50 
                                            : baseColor.withOpacity(0.04);
                                        
                                        return DataRow(
                                          color: MaterialStateProperty.all(rowColor),
                                          cells: [
                                            DataCell(Text("$index", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
                                            
                                            DataCell(Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: baseColor.withOpacity(0.1),
                                                  child: Text(
                                                    usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : "?",
                                                    style: TextStyle(color: baseColor, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(usuario.nombreCompleto, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600)),
                                              ],
                                            )),
                                            
                                            DataCell(Text(usuario.username, style: TextStyle(color: colorTexto))),
                                            
                                            // CHIP
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
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            // ACCIONES
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
                                                      child: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                                    ),
                                                    onPressed: () => showDialog(context: context, builder: (_) => UserModal(usuarioExistente: usuario)),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  IconButton(
                                                    splashRadius: 20,
                                                    icon: Icon(
                                                      usuario.activo ? Icons.delete_outline : Icons.restore_from_trash,
                                                      color: usuario.activo ? Colors.redAccent : Colors.green,
                                                      size: 20,
                                                    ),
                                                    tooltip: usuario.activo ? 'Eliminar' : 'Reactivar',
                                                    onPressed: () async {
                                                      _confirmarAccion(context, provider, usuario);
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
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lógica de confirmación
  Future<void> _confirmarAccion(BuildContext context, UsersProvider provider, Usuario usuario) async {
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
        if (isDeleting) error = await provider.deleteUser(usuario.idUsuario);
        else error = await provider.recoverUser(usuario.idUsuario);

        if (context.mounted) {
          CustomSnackBar.show(context, 
            message: error == null ? (isDeleting ? 'Eliminado' : 'Reactivado') : error, 
            type: error == null ? SnackBarType.success : SnackBarType.error
          );
        }
    }
  }
}
class _HoverableActionButton extends StatefulWidget {
  final VoidCallback onTap; final String label; final IconData icon; final bool isPrimary;
  const _HoverableActionButton({required this.onTap, required this.label, required this.icon, this.isPrimary = false});
  @override State<_HoverableActionButton> createState() => _HoverableActionButtonState();
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isPrimary ? (_isHovering ? AppTheme.primaryColor.withOpacity(0.9) : AppTheme.primaryColor) : (_isHovering ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.isPrimary ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null
          ),
          child: Row(children: [Icon(widget.icon, size: 18, color: widget.isPrimary ? Colors.white : Colors.grey), const SizedBox(width: 8), Text(widget.label, style: TextStyle(color: widget.isPrimary ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600))]),
        ),
      ),
    );
  }
}