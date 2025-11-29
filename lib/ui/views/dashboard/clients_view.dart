import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:go_router/go_router.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  Timer? _debounce;
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ClientsProvider>(context, listen: false).searchGlobal(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final clientes = clientsProvider.clients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABECERA
        Row(
          children: [
            Text(
              'Pacientes', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            const Spacer(),
            
            // BUSCADOR
            SizedBox(
              width: 300,
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Nombre, Apellido o Teléfono...',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18,color: Colors.grey),
                    onPressed: () {
                      searchCtrl.clear();
                      _debounce?.cancel(); 
                      Provider.of<ClientsProvider>(context, listen: false).searchGlobal('');
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: DropdownButton<bool>(
                value: clientsProvider.filterActive,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, size: 18),
                items: const [
                  DropdownMenuItem(value: true, child: Text("Activos")),
                  DropdownMenuItem(value: false, child: Text("Papelera")),
                ],
                onChanged: (val) {
                  if (val != null) clientsProvider.toggleFilter(val);
                },
              ),
            ),
            
            const SizedBox(width: 10),
            
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ClientModal(),
                );
              },
              icon: const Icon(Icons.add , size: 20),
              label: const Text('Nuevo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            )
          ],
        ),
        
        const SizedBox(height: 20),

        // TABLA
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: clientsProvider.isLoading
                        ? const SizedBox(
                            height: 400,
                            child: Center(child: CircularProgressIndicator())
                          )
                        : clientes.isEmpty
                            ? const SizedBox(
                                height: 200,
                                child: Center(child: Text("No hay pacientes registrados"))
                              )
                            : SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 60,
                                  headingRowHeight: 50,
                                  dividerThickness: 0.5,
                                  columnSpacing: 20,
                                  
                                  columns: const [
                                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nombre Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Expanded(child: Text('Acciones', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold)))), 
                                  ],
                                  
                                  rows: List.generate(clientes.length, (index) {
                                    final cliente = clientes[index];
                                    
                                    final realIndex = (clientsProvider.currentPage * clientsProvider.pageSize) + index + 1;

                                    return DataRow(
                                      cells: [
                                        // ÍNDICE VISUAL
                                        DataCell(Text(
                                          "$realIndex", 
                                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)
                                        )),
                                        
                                        // NOMBRE
                                        DataCell(Text(
                                          '${cliente.nombre} ${cliente.apellidos}',
                                          style: const TextStyle(fontWeight: FontWeight.w500)
                                        )),
                                        
                                        // TELÉFONO
                                        DataCell(Text(cliente.telefono)),
                                        
                                        // ACCIONES 
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Ver/Editar
                                                IconButton(
                                                  icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor),
                                                  tooltip: 'Ver Ficha',
                                                  onPressed: () => context.go('/pacientes/${cliente.idCliente}'),
                                                ),
                                                // Eliminar
                                                IconButton(
                                                  icon: Icon(
                                                    clientsProvider.filterActive 
                                                        ? Icons.delete_outline 
                                                        : Icons.restore_from_trash,
                                                    color: clientsProvider.filterActive 
                                                        ? Colors.redAccent 
                                                        : Colors.green,
                                                  ),
                                                  tooltip: clientsProvider.filterActive ? 'Eliminar' : 'Reactivar',
                                                  onPressed: () async {
                                                    final isDeleting = clientsProvider.filterActive;
                                                    final title = isDeleting ? "¿Eliminar paciente?" : "¿Reactivar paciente?";
                                                    final content = isDeleting 
                                                        ? "Se moverá a la papelera." 
                                                        : "Volverá a aparecer en la lista de activos y agenda.";
                                                    final actionBtn = isDeleting ? "Eliminar" : "Reactivar";
                                                    final actionColor = isDeleting ? Colors.red : Colors.green;
                                                    final confirm = await showDialog(
                                                      
                                                      context: context, 
                                                      builder: (ctx) => AlertDialog(
                                                        title: Text(title),
                                                        content: Text(content),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(ctx, true), 
                                                            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
                                                            child: Text(actionBtn)
                                                          ),
                                                        ],
                                                      )
                                                    );

                                                    if (confirm == true) {
                                                      if (isDeleting) {
                                                        await clientsProvider.deleteClient(cliente.idCliente);
                                                      } else {
                                                        await clientsProvider.recoverClient(cliente.idCliente);
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // PAGINACIÓN

        Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), 
                blurRadius: 5, 
                offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Mostrando ${clientsProvider.clients.length} de ${clientsProvider.totalElements} registros',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  onPressed: clientsProvider.currentPage > 0 
                      ? () => clientsProvider.prevPage() 
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Anterior',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Página ${clientsProvider.currentPage + 1} de ${clientsProvider.totalPages > 0 ? clientsProvider.totalPages : 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: clientsProvider.currentPage < clientsProvider.totalPages - 1
                      ? () => clientsProvider.nextPage()
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Siguiente',
                ),
              ],
            ),
          ),  
          
        const SizedBox(height: 20),
      ],
    );
  }
}