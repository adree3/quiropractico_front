import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/ui/modals/service_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

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
    // Ordenar lista
    final List<Servicio> serviciosOrdenados = List.from(provider.servicios);
    
    serviciosOrdenados.sort((a, b) {
      final esBonoA = a.tipo.toLowerCase() == 'bono';
      final esBonoB = b.tipo.toLowerCase() == 'bono';

      if (esBonoA && !esBonoB){
        return -1;
      }
      if (!esBonoA && esBonoB){
        return 1;
      }
      int comparacionPrecio = b.precio.compareTo(a.precio);
      if (comparacionPrecio != 0) {
        return comparacionPrecio; 
      }
      return b.idServicio.compareTo(a.idServicio);
    });
    return Column(
      children: [
        // Cabecera
        Row(
          children: [
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
                  DropdownMenuItem(value: false, child: Text("Eliminados")),
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
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : serviciosOrdenados.isEmpty
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
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 60,
                          columns: const [
                            DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            DataColumn(label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                              label: Expanded( 
                                child: Center(
                                  child: Text("Tipo", style: TextStyle(fontWeight: FontWeight.bold))
                                )
                              )
                            ),
                            DataColumn(label: Text("Precio", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Sesiones", style: TextStyle(fontWeight: FontWeight.bold))),
                            
                            DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                          ],
                          rows: serviciosOrdenados.asMap().entries.map((entry) {
                            final int index = entry.key + 1;
                            final Servicio servicio = entry.value;
                            final bool esBono = servicio.tipo.toLowerCase() == 'bono';
                            final bool activo = servicio.activo;
                            
                            final Color baseColor = esBono ? Colors.blue : Colors.purple;
                            final Color rowColor = activo 
                              ? baseColor.withOpacity(0.03)
                              : Colors.grey.shade50;
                            final Color textColor = activo ? Colors.black87 : Colors.grey;

                            return DataRow(
                              color: MaterialStateProperty.all(rowColor),
                              cells: [
                                // Indice
                                DataCell(Text("$index", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
                                // Nombre
                                DataCell(
                                  SizedBox(
                                    width: 180, 
                                    child: Text(
                                      servicio.nombreServicio, 
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ),
                                // Tipo
                                DataCell(
                                  Center(
                                    child: Chip(
                                      backgroundColor: baseColor.withOpacity(0.1),
                                      side: BorderSide(color: baseColor),
                                      padding: const EdgeInsets.all(0), 
                                      label: SizedBox(
                                        width: 45, 
                                        child: Text(
                                          esBono ? 'BONO' : 'SESIÓN',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: baseColor, 
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis, 
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                                
                                // PRECIO
                                DataCell(
                                  Text(
                                    "${servicio.precio} €", 
                                    style: TextStyle(color: textColor, fontSize: 15)
                                  )
                                ),

                                // SESIONES
                                DataCell(
                                  esBono 
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: Colors.grey.shade300)
                                      ),
                                      child: Text(
                                        "${servicio.sesiones}", 
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                                      )
                                    )
                                  : Text("-", style: TextStyle(color: textColor.withOpacity(0.5)))
                                ),
                                // ACCIONES
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Editar 
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryColor),
                                        onPressed: () => showDialog(context: context, builder: (_) => ServiceModal(servicioExistente: servicio)),
                                        tooltip: "Editar",
                                        splashRadius: 20,
                                      ),
                                      
                                      // Eliminar / Recuperar
                                      IconButton(
                                        icon: Icon(
                                          servicio.activo ? Icons.delete_outline : Icons.restore_from_trash,
                                          color: servicio.activo ? Colors.redAccent : Colors.green,
                                          size: 20,
                                        ),
                                        tooltip: servicio.activo ? 'Eliminar' : 'Reactivar',
                                        splashRadius: 20,
                                        onPressed: () async {
                                          String? error;
                                          if (servicio.activo) {
                                            error = await provider.deleteService(servicio.idServicio);
                                          } else {
                                            error = await provider.recoverService(servicio.idServicio);
                                          }
                                          if (context.mounted) {
                                            if (error == null) {
                                              CustomSnackBar.show(context, 
                                                message: servicio.activo ? 'Servicio eliminado' : 'Servicio reactivado', 
                                                type: SnackBarType.success
                                              );
                                            } else {
                                              CustomSnackBar.show(context, 
                                                message: error, 
                                                type: SnackBarType.error
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