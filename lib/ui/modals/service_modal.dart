import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class ServiceModal extends StatefulWidget {
  final Servicio? servicioExistente;

  const ServiceModal({super.key, this.servicioExistente});

  @override
  State<ServiceModal> createState() => _ServiceModalState();
}

class _ServiceModalState extends State<ServiceModal> {
  final _formKey = GlobalKey<FormState>();
  
  final nombreCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final sesionesCtrl = TextEditingController();
  
  String tipoSeleccionado = 'bono';

  bool get isEditing => widget.servicioExistente != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final s = widget.servicioExistente!;
      nombreCtrl.text = s.nombreServicio;
      precioCtrl.text = s.precio.toString();
      if (s.tipo.toLowerCase() == 'bono') {
        tipoSeleccionado = 'bono';
        if (s.sesiones != null) {
          sesionesCtrl.text = s.sesiones.toString();
        }
      } else {
        tipoSeleccionado = 'sesion_unica';
        sesionesCtrl.text = ''; 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServicesProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(isEditing ? 'Editar Tarifa' : 'Nueva Tarifa', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NOMBRE
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Servicio', prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),

              // PRECIO
              TextFormField(
                controller: precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], // Solo números y punto
                decoration: const InputDecoration(labelText: 'Precio (€)', prefixIcon: Icon(Icons.euro)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),

              // TIPO
              DropdownButtonFormField<String>(
                value: tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Servicio', prefixIcon: Icon(Icons.category_outlined)),
                items: const [
                  DropdownMenuItem(value: 'sesion_unica', child: Text("Sesión Suelta / Visita")),
                  DropdownMenuItem(value: 'bono', child: Text("Bono de Sesiones")),
                ],
                onChanged: (val) {
                  setState(() {
                    tipoSeleccionado = val!;
                  });
                },
              ),
              
              // SESIONES (Solo si es bono)
              if (tipoSeleccionado == 'bono') ...[
                const SizedBox(height: 15),
                TextFormField(
                  controller: sesionesCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Número de Sesiones', 
                    prefixIcon: Icon(Icons.repeat),
                    hintText: 'Ej: 10'
                  ),
                  validator: (v) {
                    if (tipoSeleccionado == 'bono' && (v == null || v.isEmpty)) return 'Requerido para bonos';
                    if (int.tryParse(v!) == null || int.parse(v) < 1) return 'Mínimo 1 sesión';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final nombre = nombreCtrl.text.trim();
              final precio = double.parse(precioCtrl.text.trim());
              final sesiones = tipoSeleccionado == 'bono' ? int.parse(sesionesCtrl.text.trim()) : null;

              String? error;
              if (isEditing) {
                error = await provider.updateService(widget.servicioExistente!.idServicio, nombre, precio, tipoSeleccionado, sesiones);
              } else {
                error = await provider.createService(nombre, precio, tipoSeleccionado, sesiones);
              }

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  CustomSnackBar.show(context, 
                    message: 'Guardado correctamente', 
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
          child: Text(isEditing ? 'Guardar Cambios' : 'Crear Tarifa'),
        ),
      ],
    );
  }
}