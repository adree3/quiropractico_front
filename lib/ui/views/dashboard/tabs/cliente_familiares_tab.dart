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

        await provider.loadFullData(cliente.idCliente);

        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message:
                "$familiarName vinculado a ${cliente.nombre} ${cliente.apellidos}",
            type: SnackBarType.success,
            actionLabel: "DESHACER",
            onAction: () async {
              try {
                final fam = provider.familiares.firstWhere(
                  (f) => f.idFamiliar == familiar.idCliente,
                  orElse: () => throw Exception("Familiar no encontrado"),
                );

                await provider.desvincularFamiliar(fam.idGrupo, [], undo: true);

                if (context.mounted) {
                  provider.loadFullData(cliente.idCliente);
                  CustomSnackBar.show(
                    context,
                    message: "Vinculación deshecha",
                    type: SnackBarType.info,
                  );
                }
              } catch (e) {
                print("Error deshaciendo: $e");
              }
            },
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
            subtitle:
                "Puedes vincular otros pacientes (hijos, pareja) para gestionar sus citas conjuntamente.",
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
          RefreshIndicator(
            onRefresh: () async {
              await provider.loadFullData(cliente.idCliente);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: 80,
              ),
              itemCount: familiares.length,
              itemBuilder: (context, index) {
                final familiar = familiares[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Tooltip(
                    message: "Ver perfil de ${familiar.nombreCompleto}",
                    child: InkWell(
                      onTap: () {
                        context.push('/pacientes/${familiar.idFamiliar}');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            AvatarWidget(
                              nombreCompleto: familiar.nombreCompleto,
                              id: familiar.idFamiliar,
                              radius: 20,
                              fontSize: 16,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${familiar.nombreCompleto}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.family_restroom,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Relación: ${familiar.relacion}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  final List<int>? idsParaCancelar =
                                      await showDialog<List<int>>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (ctx) => SmartDesvinculacionDialog(
                                              nombreFamiliar:
                                                  familiar.nombreCompleto,
                                              idGrupo: familiar.idGrupo,
                                              fetchConflictos:
                                                  (id) => provider
                                                      .obtenerConflictos(id),
                                            ),
                                      );

                                  if (idsParaCancelar != null) {
                                    try {
                                      final undoIdFamiliar =
                                          familiar.idFamiliar;
                                      final undoRelacion = familiar.relacion;
                                      final undoName = familiar.nombreCompleto;

                                      await provider.desvincularFamiliar(
                                        familiar.idGrupo,
                                        idsParaCancelar,
                                      );

                                      if (context.mounted) {
                                        provider.loadFullData(
                                          cliente.idCliente,
                                        );
                                        final agendaProvider =
                                            Provider.of<AgendaProvider>(
                                              context,
                                              listen: false,
                                            );
                                        agendaProvider.getCitasDelDia(
                                          agendaProvider.selectedDate,
                                        );

                                        CustomSnackBar.show(
                                          context,
                                          message:
                                              "$undoName desvinculado de ${cliente.nombre} ${cliente.apellidos}",
                                          type: SnackBarType.success,
                                          actionLabel: "DESHACER",
                                          onAction: () async {
                                            await provider.vincularFamiliar(
                                              undoIdFamiliar,
                                              undoRelacion,
                                              undo: true,
                                              idsCitasARestaurar:
                                                  idsParaCancelar,
                                            );
                                            if (context.mounted) {
                                              provider.loadFullData(
                                                cliente.idCliente,
                                              );
                                              CustomSnackBar.show(
                                                context,
                                                message:
                                                    "Vinculación restaurada",
                                                type: SnackBarType.info,
                                              );
                                            }
                                          },
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
                                    child: Icon(
                                      Icons.link_off,
                                      color: Colors.red.shade300,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openVincularModal(context, provider),
            icon: const Icon(Icons.person_add),
            label: const Text("Vincular"),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
