import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final clientes = clientsProvider.clients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador y titulo
        Row(
          children: [
            Text(
              'Pacientes', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            const Spacer(),
            // Buscador pequeño
            SizedBox(
              width: 250,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (value) {
                  // Aquí implementaríamos el filtrado visual luego
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
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          ],
        ),
        
        const SizedBox(height: 20),

        // TABLA DE DATOS
        Expanded(
          child: Card(
            child: clientsProvider.isLoading
                ? const Center(child: CircularProgressIndicator()) 
                : SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Acciones')),
                          
                        ],
                        
                        rows: clientes.map((cliente) {
                          return DataRow(cells: [
                            DataCell(Text('${cliente.nombre} ${cliente.apellidos}')),
                            DataCell(Text(cliente.telefono)),
                            DataCell(Text(cliente.email ?? '-')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.history, color: AppTheme.secondaryColor),
                                    tooltip: 'Ver Historial',
                                    onPressed: () {}, 
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
        //Paginación
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
              // Información de registros
              Text(
                'Total: ${clientsProvider.totalElements} pacientes',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              
              // Botón Anterior
              IconButton(
                onPressed: clientsProvider.currentPage > 0 
                    ? () => clientsProvider.prevPage() 
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Anterior',
              ),

              // Indicador de Página
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Página ${clientsProvider.currentPage + 1} de ${clientsProvider.totalPages > 0 ? clientsProvider.totalPages : 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Botón Siguiente
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