import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/ui/modals/vincular_familiar_modal.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/smart_desvinculacion_dialog.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/empty_state.dart';

class ClienteFamiliaresTab extends StatelessWidget {
  final Cliente cliente;

  const ClienteFamiliaresTab({super.key, required this.cliente});

  void _openVincularModal(BuildContext context, ClientDetailProvider provider) {
    showDialog(
      context: context,
      builder: (_) => VincularFamiliarModal(detailProvider: provider),
    ).then((result) async {
      if (result != null && result is Map) {
        final familiar = result['familiar'] as Cliente;
        final familiarName = "${familiar.nombre} ${familiar.apellidos}";

        await provider.refreshFamiliares(silent: true);
        await provider.refreshCliente(silent: true);

        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: "$familiarName vinculado a ${cliente.nombre} ${cliente.apellidos}",
            type: SnackBarType.success,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);
    final familiares = provider.familiares;

    return Stack(
      children: [
        if (familiares.isEmpty)
          EmptyStateWidget(
            icon: Icons.family_restroom,
            title: "Sin familiares vinculados",
            subtitle: "Puedes vincular otros pacientes (hijos, pareja) para gestionar sus citas conjuntamente.",
            action: ElevatedButton.icon(
              onPressed: () => _openVincularModal(context, provider),
              icon: const Icon(Icons.person_add),
              label: const Text("Vincular Familiar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openVincularModal(context, provider),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("Vincular Familiar", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.refreshFamiliares(silent: true);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: familiares.length,
                    itemBuilder: (context, index) {
                      final familiar = familiares[index];
                      final isActive = familiar.activo;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 4,
                                color: isActive ? AppTheme.primaryColor : Colors.red.shade300,
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    context.push('/pacientes/${familiar.idFamiliar}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        AvatarWidget(
                                          nombreCompleto: familiar.nombreCompleto,
                                          id: familiar.idFamiliar,
                                          radius: 24,
                                          fontSize: 18,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    familiar.nombreCompleto,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  if (!isActive) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.red.shade200),
                                                      ),
                                                      child: Text(
                                                        "BAJA",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.red.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.family_restroom, size: 14, color: Colors.blue.shade700),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          familiar.relacion,
                                                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (familiar.telefono != null && familiar.telefono!.isNotEmpty) ...[
                                                    const SizedBox(width: 12),
                                                    Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      familiar.telefono!,
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                    ),
                                                  ],
                                                  if (familiar.email != null && familiar.email!.isNotEmpty) ...[
                                                    const SizedBox(width: 12),
                                                    Icon(Icons.email, size: 14, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      familiar.email!,
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: () async {
                                              final List<int>? idsParaCancelar = await showDialog<List<int>>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (ctx) => SmartDesvinculacionDialog(
                                                  nombreFamiliar: familiar.nombreCompleto,
                                                  idGrupo: familiar.idGrupo,
                                                  fetchConflictos: (id) => provider.obtenerConflictos(id),
                                                ),
                                              );

                                              if (idsParaCancelar != null) {
                                                try {
                                                  final undoName = familiar.nombreCompleto;
                                                  await provider.desvincularFamiliar(familiar.idGrupo, idsParaCancelar);

                                                  if (context.mounted) {
                                                    await provider.refreshFamiliares(silent: true);
                                                    await provider.refreshCliente(silent: true);
                                                    
                                                    final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
                                                    agendaProvider.getCitasDelDia(agendaProvider.selectedDate);

                                                    CustomSnackBar.show(
                                                      context,
                                                      message: "$undoName desvinculado de ${cliente.nombre} ${cliente.apellidos}",
                                                      type: SnackBarType.success,
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    CustomSnackBar.show(
                                                      context,
                                                      message: "Error: $e",
                                                      type: SnackBarType.error,
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            child: Tooltip(
                                              message: "Desvincular familiar",
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Icon(Icons.link_off, color: Colors.red.shade300, size: 22),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
