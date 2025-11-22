import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';

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
                // Abrir modal de crear cliente (Próximo paso)
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
      ],
    );
  }
}