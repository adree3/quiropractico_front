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
                  
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
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
            
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ClientModal(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          ],
        ),
        
        const SizedBox(height: 20),

        // TABLA
        Expanded(
          child: Card(
            child: clientsProvider.isLoading
                ? const Center(child: CircularProgressIndicator()) 
                : clientes.isEmpty 
                    ? const Center(child: Text("No se encontraron pacientes"))
                    : SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Teléfono')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: clientes.map((cliente) {
                              return DataRow(cells: [
                                DataCell(Text('${cliente.nombre} ${cliente.apellidos}')),
                                DataCell(Text(cliente.telefono)),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                        tooltip: 'Editar',
                                        onPressed: () {
                                          context.go('/pacientes/${cliente.idCliente}');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: AppTheme.secondaryColor),
                                        tooltip: 'Ver Ficha',
                                        onPressed: () {
                                          context.go('/pacientes/${cliente.idCliente}');
                                        }, 
                                      ),
                                    ],
                                  )
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
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