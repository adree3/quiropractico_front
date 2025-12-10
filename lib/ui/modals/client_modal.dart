import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';

class ClientModal extends StatefulWidget {
  final Cliente? clienteExistente;
  
  const ClientModal({super.key, this.clienteExistente});
  
  @override
  State<ClientModal> createState() => _ClientModalState();
}

class _ClientModalState extends State<ClientModal> {
  final _formKey = GlobalKey<FormState>();
  
  final nombreCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  
  bool get isEditing => widget.clienteExistente != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final c = widget.clienteExistente!;
      nombreCtrl.text = c.nombre;
      apellidosCtrl.text = c.apellidos;
      telefonoCtrl.text = c.telefono;
      emailCtrl.text = c.email ?? '';
      direccionCtrl.text = c.direccion ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);

    return AlertDialog(
      title: Text(
        isEditing ? 'Editar Paciente' : 'Nuevo Paciente', 
        style: const TextStyle(fontWeight: FontWeight.bold)
      ),
      content: SizedBox(
        width: AppTheme.dialogWidth,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Nombre
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                // Apellidos
                TextFormField(
                  controller: apellidosCtrl,
                  decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                // Teléfono 
                TextFormField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *', 
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'ej. 600123456'
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'El teléfono es obligatorio';
                    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
                    
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Formato inválido (Mínimo 9 dígitos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Email 
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email', 
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'ej. usuario@dominio.com'
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Dirección 
                TextFormField(
                  controller: direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección (Opcional)', prefixIcon: Icon(Icons.map_outlined)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Botón Cancelar
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
          child: const Text('Cancelar'),
        ),
        
        // Botón Guardar
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              
              FocusScope.of(context).unfocus(); 
              String? error;

              if (isEditing) {
                error = await clientsProvider.updateClient(
                  widget.clienteExistente!.idCliente,
                  nombreCtrl.text.trim(),
                  apellidosCtrl.text.trim(),
                  telefonoCtrl.text.trim(),
                  emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(), 
                  direccionCtrl.text.isEmpty ? null : direccionCtrl.text.trim(),
                );
              } else {
                // CREAR
                error = await clientsProvider.createClient(
                  nombreCtrl.text.trim(),
                  apellidosCtrl.text.trim(),
                  telefonoCtrl.text.trim(),
                  emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(), 
                  direccionCtrl.text.isEmpty ? null : direccionCtrl.text.trim(),
                );
              }

              if (context.mounted) {
                if (error == null) {
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Paciente actualizado' : 'Paciente creado'),
                      backgroundColor: Colors.green
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error), 
                      backgroundColor: Colors.red
                    ),
                  );
                }
              }
            }
          },
          child: Text(isEditing ? 'Guardar Cambios' : 'Guardar Paciente'),
        ),
      ],
    );
  }
}