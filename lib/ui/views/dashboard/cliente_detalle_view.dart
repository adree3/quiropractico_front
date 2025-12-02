import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/ui/modals/client_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
import 'package:quiropractico_front/ui/modals/vincular_familiar_modal.dart';


class ClienteDetalleView extends StatelessWidget {
  final int idCliente;

  const ClienteDetalleView({super.key, required this.idCliente});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientDetailProvider()..loadFullData(idCliente),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    
    if (provider.cliente == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Cliente no encontrado", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/pacientes'),
              child: const Text("Volver")
            )
          ],
        ),
      );
    }
    final cliente = provider.cliente!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navegación
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => context.go('/pacientes'),
              tooltip: 'Volver',
            ),
            const SizedBox(width: 10),
            const Text("Detalles del Paciente", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
            

        // 2. Card info cliente
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 25),
                
                // Datos del Cliente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${cliente.nombre} ${cliente.apellidos}", 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(cliente.email ?? 'Sin email', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 20),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(cliente.telefono, style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
                
                const Spacer(),
                
                // Botones de Acción Rápida
                ElevatedButton.icon(
                  onPressed: () async {
                    final bool? ventaExitosa = await showDialog(
                      context: context, 
                      builder: (_) => VentaBonoModal(cliente: cliente)
                    );
                    if (ventaExitosa == true) {
                       provider.loadFullData(cliente.idCliente);
                    }
                  },
                  icon: const Icon(Icons.shopping_cart), 
                  label: const Text("Vender Bono"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                  ),
                ),
                const SizedBox(width: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    final refresh = await showDialog(
                      context: context, 
                      builder: (_) => ClientModal(clienteExistente: cliente)
                    );
                    if (refresh == true) {
                      provider.loadFullData(cliente.idCliente);
                    }
                  },
                  icon: const Icon(Icons.edit), 
                  label: const Text("Editar Datos")
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Tabbar
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "Historial de Citas", icon: Icon(Icons.history)),
                    Tab(text: "Cartera de Bonos", icon: Icon(Icons.card_membership)),
                    Tab(text: "Familiares", icon: Icon(Icons.family_restroom)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Historial Citas
                      provider.historialCitas.isEmpty
                          ? const Center(child: Text("No hay citas registradas"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(5),
                              itemCount: provider.historialCitas.length,
                              itemBuilder: (ctx, i) {
                                final cita = provider.historialCitas[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.grey.shade200)
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.calendar_today, color: Colors.blue),
                                    ),
                                    title: Text(
                                      DateFormat('dd/MM/yyyy  HH:mm').format(cita.fechaHoraInicio),
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                    subtitle: Text("Dr. ${cita.nombreQuiropractico}"),
                                    trailing: Chip(
                                      backgroundColor: cita.estado == 'completada' ? Colors.green : 
                                                       cita.estado == 'cancelada' ? Colors.red : 
                                                       cita.estado == 'ausente' ? Colors.grey : Colors.blue,
                                      padding: EdgeInsets.zero, 
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8), 
                                      
                                      
                                      
                                      label: SizedBox(
                                        width: 85, 
                                        child: Text(
                                          cita.estado.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Bonos
                      provider.bonos.isEmpty 
                          ? const Center(child: Text("El cliente no tiene bonos activos"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(5),
                              itemCount: provider.bonos.length,
                              itemBuilder: (ctx, i) {
                                final bono = provider.bonos[i];
                                final caducidad = bono.fechaCaducidad != null 
                                    ? DateFormat('dd/MM/yyyy').format(bono.fechaCaducidad!)
                                    : 'Sin caducidad';

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.amber,
                                      child: Icon(Icons.star, color: Colors.white),
                                    ),
                                    title: Text(bono.nombreServicio, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Caduca: $caducidad"),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.green)
                                      ),
                                      child: Text(
                                        "${bono.sesionesRestantes} sesiones", 
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Familiares
                      Column(
                        children: [
                          // Botón Añadir Familiar 
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => VincularFamiliarModal(detailProvider: provider)
                                );
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text("Vincular Familiar"),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: provider.familiares.isEmpty
                              ? const Center(child: Text("Sin familiares vinculados"))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(5),
                                  itemCount: provider.familiares.length,
                                  itemBuilder: (ctx, i) {
                                    final fam = provider.familiares[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.purple,
                                          child: Icon(Icons.link, color: Colors.white),
                                        ),
                                        title: Text(fam.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text("Relación: ${fam.relacion}"),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                          tooltip: "Ir a su ficha",
                                          onPressed: () => context.push('/pacientes/${fam.idFamiliar}'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}