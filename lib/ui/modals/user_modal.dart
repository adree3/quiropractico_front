import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/users_provider.dart';

class UserModal extends StatefulWidget {
  final Usuario? usuarioExistente;
  const UserModal({super.key, this.usuarioExistente});

  @override
  State<UserModal> createState() => _UserModalState();
}

class _UserModalState extends State<UserModal> {
  final _formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  
  String rolSeleccionado = 'recepción';
  bool get isEditing => widget.usuarioExistente != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final u = widget.usuarioExistente!;
      nombreCtrl.text = u.nombreCompleto;
      usernameCtrl.text = u.username;
      rolSeleccionado = u.rol.toLowerCase(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UsersProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Empleado', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing && widget.usuarioExistente!.cuentaBloqueada) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_clock, color: Colors.orange),
                          SizedBox(width: 10),
                          Text("CUENTA BLOQUEADA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 34, top: 5, bottom: 10),
                        child: Text("Este usuario ha excedido los intentos de acceso.", style: TextStyle(fontSize: 12)),
                      ),
                      
                      // BOTONES DE ACCIÓN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // IGNORAR
                          TextButton.icon(
                            onPressed: () async{
                              final error = await provider.deleteUser(widget.usuarioExistente!.idUsuario);
                              if (context.mounted) {
                                 if (error == null) {
                                   Navigator.pop(context);
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Usuario eliminado'), backgroundColor: Colors.green)
                                   );
                                 } 
                               }
                            },
                            icon: const Icon(Icons.person_off, size: 16, color: Colors.red),
                            label: const Text("Eliminar usuario"),
                          ),
                          
                          const SizedBox(width: 10),

                          // DESBLOQUEAR 
                          ElevatedButton(
                            onPressed: () async {
                              final error = await provider.unlockUser(widget.usuarioExistente!.idUsuario);
                              if (context.mounted) {
                                if (error == null) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario desbloqueado'), backgroundColor: Colors.green));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                                }
                              }
                            }, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            child: const Text("DESBLOQUEAR")
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: usernameCtrl,
                readOnly: isEditing, 
                decoration: InputDecoration(
                  labelText: 'Usuario (Login)', 
                  prefixIcon: const Icon(Icons.person),
                  filled: !isEditing,
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña', 
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: isEditing ? 'Déjalo vacío para no cambiarla' : null
                ),
                validator: (v) {
                  if (!isEditing && (v == null || v.isEmpty)) return 'La contraseña es obligatoria';
                  if (v != null && v.isNotEmpty && v.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: rolSeleccionado,
                decoration: const InputDecoration(labelText: 'Rol / Permisos', prefixIcon: Icon(Icons.security)),
                items: const [
                  DropdownMenuItem(value: 'recepción', child: Text("Recepción (Básico)")),
                  DropdownMenuItem(value: 'quiropráctico', child: Text("Quiropráctico (Médico)")),
                  DropdownMenuItem(value: 'admin', child: Text("Administrador (Total)")),
                ],
                onChanged: (val) => setState(() => rolSeleccionado = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              String? error;
              if (isEditing) {
                error = await provider.updateUser(
                  widget.usuarioExistente!.idUsuario,
                  nombreCtrl.text.trim(),
                  passCtrl.text.isEmpty ? null : passCtrl.text.trim(),
                  rolSeleccionado
                );
              } else {
                error = await provider.createUser(
                  nombreCtrl.text.trim(),
                  usernameCtrl.text.trim(),
                  passCtrl.text.trim(),
                  rolSeleccionado
                );
              }

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado correctamente'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            }
          },
          child: Text(isEditing ? 'Guardar Cambios' : 'Crear Usuario'),
        ),
      ],
    );
  }
}