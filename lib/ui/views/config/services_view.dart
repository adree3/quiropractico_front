import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/ui/modals/service_modal.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServicesProvider>(context);
    String mensajeVacio;
    if (provider.filterActive == true) {
      mensajeVacio = "No hay servicios activos";
    } else if (provider.filterActive == false){
      mensajeVacio = "No hay servicios inactivos (Papelera vacía)";

    } else {
      mensajeVacio = "No hay servicios registrados";
    }
    return Column(
      children: [
        // CABECERA
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => context.go('/configuracion'),
              tooltip: 'Volver',
            ),
            const SizedBox(width: 10),
            const Text("Gestión de Servicios", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: DropdownButton<bool?>(
                value: provider.filterActive,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: Colors.grey),
                items: const [
                  DropdownMenuItem(value: true, child: Text("Activos")),
                  DropdownMenuItem(value: false, child: Text("Papelera")),
                  DropdownMenuItem(value: null, child: Text("Todos")),
                ],
                onChanged: (val) {
                  provider.setFilter(val);
                },
              ),
            ),
            const SizedBox(width: 15),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const ServiceModal()),
              icon: const Icon(Icons.add),
              label: const Text("Nueva Tarifa"),
            )
          ],
        ),
        const SizedBox(height: 20),
        
        // TABLA
        Expanded(
          child: Card(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.servicios.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apps_outage_sharp, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(mensajeVacio, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                  : SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text("Nombre")),
                            DataColumn(label: Text("Tipo")),
                            DataColumn(label: Text("Precio")),
                            DataColumn(label: Text("Sesiones")),
                            DataColumn(label: Text("Acciones", textAlign: TextAlign.end)),
                          ],
                          rows: provider.servicios.map((servicio) {
                            // Estilo visual para inactivos
                            final colorTexto = servicio.activo ? Colors.black87 : Colors.grey;
                            
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 180, 
                                    child: Text(
                                      servicio.nombreServicio, 
                                      style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: servicio.sesiones != null ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Text(
                                      servicio.sesiones != null ? "BONO" : "SESIÓN",
                                      style: TextStyle(
                                        color: servicio.sesiones != null ? Colors.purple : Colors.blue,
                                        fontSize: 10, fontWeight: FontWeight.bold
                                      )
                                    ),
                                  )
                                ),
                                DataCell(Text("${servicio.precio} €", style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold))),
                                DataCell(Text(servicio.sesiones?.toString() ?? "-", style: TextStyle(color: colorTexto))),
                                
                                // ACCIONES
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Editar 
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                        onPressed: () => showDialog(context: context, builder: (_) => ServiceModal(servicioExistente: servicio)),
                                      ),
                                      
                                      // Eliminar / Recuperar
                                      IconButton(
                                        icon: Icon(
                                          servicio.activo ? Icons.delete_outline : Icons.restore_from_trash,
                                          color: servicio.activo ? Colors.redAccent : Colors.green
                                        ),
                                        tooltip: servicio.activo ? 'Desactivar' : 'Reactivar',
                                        onPressed: () async {
                                          String? error;
                                          if (servicio.activo) {
                                            error = await provider.deleteService(servicio.idServicio);
                                          } else {
                                            error = await provider.recoverService(servicio.idServicio);
                                          }
                                          if (context.mounted) {
                                            if (error == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(servicio.activo ? 'Servicio eliminado' : 'Servicio reactivado'), 
                                                  backgroundColor: Colors.green
                                                )
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(error), 
                                                  backgroundColor: Colors.red
                                                )
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                ),
                              ],
                            );
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