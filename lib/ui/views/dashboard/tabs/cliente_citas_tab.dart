import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/client_detail_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_date_range_picker.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/empty_state.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_filter_button.dart';

class ClienteCitasTab extends StatefulWidget {
  final Cliente cliente;

  const ClienteCitasTab({super.key, required this.cliente});

  @override
  State<ClienteCitasTab> createState() => _ClienteCitasTabState();
}

class _ClienteCitasTabState extends State<ClienteCitasTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ClientDetailProvider>(
        context,
        listen: false,
      );
      if (!provider.isLoadingMoreCitas && provider.hasMoreCitas) {
        provider.loadMoreCitas();
      }
    }
  }

  Map<String, List<Cita>> _agruparCitasPorMes(List<Cita> citas) {
    final Map<String, List<Cita>> agrupado = {};
    final now = DateTime.now();

    for (var cita in citas) {
      String format = 'MMMM yyyy';
      if (cita.fechaHoraInicio.year == now.year) {
        format = 'MMMM';
      }
      String key = DateFormat(format, 'es').format(cita.fechaHoraInicio);
      key = toBeginningOfSentenceCase(key) ?? key;

      if (!agrupado.containsKey(key)) {
        agrupado[key] = [];
      }
      agrupado[key]!.add(cita);
    }
    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientDetailProvider>(context);
    final citasAgrupadas = _agruparCitasPorMes(provider.historialCitas);
    final mesKeys = citasAgrupadas.keys.toList();

    return Column(
      children: [
        // --- HEADER CON ACCIONES ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                height: 38,
                child: Tooltip(
                  message: "Cita para ${widget.cliente.nombre}",
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final refresh = await showDialog(
                        context: context,
                        builder:
                            (_) => CitaModal(preSelectedClient: widget.cliente),
                      );
                      if (refresh == true) {
                        provider.loadFullData(widget.cliente.idCliente);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Crear Cita",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Filtro Fechas
              SizedBox(
                height: 38,
                child: HoverableFilterButton(
                  label:
                      provider.fechaInicio != null
                          ? "${DateFormat('dd/MM/yy').format(provider.fechaInicio!)} - ${provider.fechaFin != null ? DateFormat('dd/MM/yy').format(provider.fechaFin!) : '...'}"
                          : "Fechas",
                  icon: Icons.date_range,
                  isActive: provider.fechaInicio != null,
                  tooltip: "Filtrar por rango de fechas",
                  onTap: () async {
                    final picked = await CustomDateRangePicker.show(
                      context,
                      initialStartDate: provider.fechaInicio,
                      initialEndDate: provider.fechaFin,
                    );
                    if (picked != null) {
                      provider.setRangoFechas(picked.start, picked.end);
                    }
                  },
                  onClear: () => provider.setRangoFechas(null, null),
                ),
              ),
              const SizedBox(width: 10),
              // Filtro Estado
              SizedBox(
                height: 38,
                child: DashboardDropdown<String?>(
                  selectedValue: provider.filtroEstado,
                  tooltip: "Filtrar por estado",
                  options: [
                    const DropdownOption(
                      value: null,
                      label: "Estado: Todas",
                      icon: Icons.filter_list,
                    ),
                    DropdownOption(
                      value: "programada",
                      label: "Programadas",
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    DropdownOption(
                      value: "completada",
                      label: "Completadas",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    DropdownOption(
                      value: "ausente",
                      label: "Ausentes",
                      icon: Icons.person_off,
                      color: Colors.grey,
                    ),
                    DropdownOption(
                      value: "cancelada",
                      label: "Canceladas",
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                  onSelected: (val) => provider.setFiltroEstado(val),
                ),
              ),
            ],
          ),
        ),

        if (provider.isLoadingCitas)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),

        Expanded(
          child:
              provider.historialCitas.isEmpty &&
                      !provider.isLoading &&
                      !provider.isLoadingCitas
                  ? const EmptyStateWidget(
                    icon: Icons.event_note,
                    title: "No hay citas registradas",
                    subtitle:
                        "El historial de citas de este paciente aparecerá aquí.",
                  )
                  : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!provider.isLoadingMoreCitas &&
                          provider.hasMoreCitas &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200) {
                        provider.loadMoreCitas();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(5),
                      itemCount:
                          mesKeys.length + (provider.hasMoreCitas ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == mesKeys.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final mesKey = mesKeys[i];
                        final citasDelMes = citasAgrupadas[mesKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cabecera del Mes
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    mesKey,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.blue.shade100,
                                      thickness: 1,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Lista de citas del mes
                            Column(
                              children:
                                  citasDelMes.map((cita) {
                                    return _CitaCard(
                                      cita: cita,
                                      cliente: widget.cliente,
                                    );
                                  }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final Cliente cliente;

  const _CitaCard({required this.cita, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm', 'es');

    Color estadoColor = Colors.grey;
    IconData estadoIcon = Icons.help_outline;

    switch (cita.estado.toLowerCase()) {
      case 'programada':
      case 'confirmada':
      case 'pendiente':
        estadoColor = Colors.blue;
        estadoIcon = Icons.calendar_today;
        break;
      case 'completada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle_outline;
        break;
      case 'cancelada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel_outlined;
        break;
      case 'ausente':
        estadoColor = Colors.grey;
        estadoIcon = Icons.person_off_outlined;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Tooltip(
        message: "Ver detalles de la cita",
        child: InkWell(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (_) => CitaDetalleModal(cita: cita),
            );
            if (context.mounted) {
              Provider.of<ClientDetailProvider>(
                context,
                listen: false,
              ).loadCitas(resetPage: false, notify: true);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cuadrado Fecha (Izquierda)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateFormat.format(cita.fechaHoraInicio).split(' ')[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: estadoColor,
                        ),
                      ),
                      Text(
                        dateFormat
                            .format(cita.fechaHoraInicio)
                            .split(' ')[1]
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // Info Central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.infoPago,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(cita.fechaHoraInicio),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cita.nombreQuiropractico,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Estado y Hora (Derecha)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(estadoIcon, color: estadoColor),
                    const SizedBox(height: 4),
                    Text(
                      cita.estado,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${timeFormat.format(cita.fechaHoraInicio)} - ${timeFormat.format(cita.fechaHoraFin)}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
