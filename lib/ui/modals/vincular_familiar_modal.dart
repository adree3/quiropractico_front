import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class VincularFamiliarModal extends StatefulWidget {
  final ClientDetailProvider detailProvider;

  const VincularFamiliarModal({super.key, required this.detailProvider});

  @override
  State<VincularFamiliarModal> createState() => _VincularFamiliarModalState();
}

class _VincularFamiliarModalState extends State<VincularFamiliarModal> {
  final _formKey = GlobalKey<FormState>();
  final relacionCtrl = TextEditingController();
  
  Cliente? selectedBeneficiario;

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
    final detailProvider = widget.detailProvider;
    final idTitular = detailProvider.cliente?.idCliente;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Añadir Familiar", style: TextStyle(fontWeight: FontWeight.bold)),
      
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Busca por nombre, apellido o teléfono:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Autocomplete
              Autocomplete<Cliente>(
                displayStringForOption: (Cliente option) => "${option.nombre} ${option.apellidos} (${option.telefono})",
                
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text == '') {
                    return const Iterable<Cliente>.empty();
                  }
                  final resultados = await clientsProvider.searchClientesByName(textEditingValue.text);
                  
                  return resultados.where((c) => c.idCliente != idTitular);
                },

                onSelected: (Cliente selection) {
                  setState(() {
                    selectedBeneficiario = selection;
                  });
                },

                // Diseño del text field 
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Buscar Paciente (Nombre o Teléfono)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: selectedBeneficiario != null 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    validator: (value) {
                      if (selectedBeneficiario == null) {
                        return 'Debes seleccionar un paciente de la lista';
                      }
                      return null;
                    },
                  );
                },

                // Diseño de la Lista de Sugerencias
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 300,
                        constraints: const BoxConstraints(maxHeight: 200),
                        color: Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Cliente option = options.elementAt(index);
                            return ListTile(
                              leading: const CircleAvatar(
                                radius: 15, 
                                backgroundColor: AppTheme.primaryColor, 
                                child: Icon(Icons.person, size: 16, color: Colors.white)
                              ),
                              title: Text("${option.nombre} ${option.apellidos}"),
                              subtitle: Text(option.telefono),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 15),

              // RELACIÓN
              TextFormField(
                controller: relacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Relación (ej. Hijo, Pareja)',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancelar')
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && selectedBeneficiario != null) {
              final String? error = await detailProvider.vincularFamiliar(
                selectedBeneficiario!.idCliente,
                relacionCtrl.text.trim()
              );

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  CustomSnackBar.show(context, 
                    message: 'Familiar vinculado correctamente', 
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
          child: const Text('Guardar Relación'),
        ),
      ],
    );
  }
}