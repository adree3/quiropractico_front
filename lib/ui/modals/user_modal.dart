import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
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
              bool success;
              if (isEditing) {
                success = await provider.updateUser(
                  widget.usuarioExistente!.idUsuario,
                  nombreCtrl.text.trim(),
                  passCtrl.text.isEmpty ? null : passCtrl.text.trim(),
                  rolSeleccionado
                );
              } else {
                success = await provider.createUser(
                  nombreCtrl.text.trim(),
                  usernameCtrl.text.trim(),
                  passCtrl.text.trim(),
                  rolSeleccionado
                );
              }

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado correctamente'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
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