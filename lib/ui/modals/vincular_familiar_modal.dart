import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';

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
      title: const Text(
        "Añadir Familiar",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

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
              RawAutocomplete<Cliente>(
                displayStringForOption:
                    (Cliente option) =>
                        "${option.nombre} ${option.apellidos} (${option.telefono})",

                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Cliente>.empty();
                  }
                  final resultados = await clientsProvider.searchClientesByName(
                    textEditingValue.text,
                  );

                  return resultados.where((c) => c.idCliente != idTitular);
                },

                onSelected: (Cliente selection) {
                  setState(() {
                    selectedBeneficiario = selection;
                  });
                },

                // Diseño del text field
                fieldViewBuilder: (
                  context,
                  textEditingController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Buscar Paciente (Nombre o Teléfono)',
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon:
                          selectedBeneficiario != null
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  textEditingController.clear();
                                  setState(() {
                                    selectedBeneficiario = null;
                                  });
                                },
                              )
                              : null,
                    ),
                    onChanged: (text) {
                      // Si cambia el texto, invalidamos la selección anterior
                      if (selectedBeneficiario != null) {
                        setState(() {
                          selectedBeneficiario = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (selectedBeneficiario == null) {
                        return 'Debes buscar y seleccionar un paciente de la lista';
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
                              leading: AvatarWidget(
                                nombreCompleto: option.nombre,
                                id: option.idCliente,
                                radius: 15,
                                fontSize: 14,
                              ),
                              title: Text(
                                "${option.nombre} ${option.apellidos}",
                              ),
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Relación (ej. Hijo, Pareja)',
                  prefixIcon: Icon(Icons.link),
                ),
                validator:
                    (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() &&
                selectedBeneficiario != null) {
              final String? error = await detailProvider.vincularFamiliar(
                selectedBeneficiario!.idCliente,
                relacionCtrl.text.trim(),
              );

              if (context.mounted) {
                if (error == null) {
                  Navigator.pop(context, {
                    'familiar': selectedBeneficiario,
                    'relacion': relacionCtrl.text.trim(),
                  });
                } else {
                  CustomSnackBar.show(
                    context,
                    message: error,
                    type: SnackBarType.error,
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
