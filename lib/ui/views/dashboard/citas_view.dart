import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/ui_provider.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/modals/cita_detalle_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/widgets/paginated_table.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/custom_date_range_picker.dart';
import 'package:quiropractico_front/ui/widgets/kpi_skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CitasView extends StatefulWidget {
  const CitasView({super.key});

  @override
  State<CitasView> createState() => _CitasViewState();
}

class _CitasViewState extends State<CitasView> {
  Timer? _debounce;
  final searchCtrl = TextEditingController();
  final ScrollController _headerScroll = ScrollController();

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    _headerScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<CitasProvider>(context, listen: false).setSearchTerm(query);
    });
  }

  String _formatPago(String info) {
    if (info.startsWith('Bono') && info.contains('(')) {
      final parts = info.split('(');
      if (parts.length > 1) {
        final insideParens = parts[1].split('/')[0].trim();
        final isFamiliar = !info.toLowerCase().startsWith('bono propio');
        return insideParens + (isFamiliar ? ' (F)' : '');
      }
    }
    return info;
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UiProvider>(context);
        final citasProvider = Provider.of<CitasProvider>(context);
    final citas = citasProvider.citas;
    final kpis = citasProvider.kpis;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thickness: WidgetStateProperty.all(4),
                    radius: const Radius.circular(4),
                    thumbColor: WidgetStateProperty.all(
                      Colors.grey.withOpacity(0.35),
                    ),
                    trackColor: WidgetStateProperty.all(Colors.transparent),
                    trackBorderColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    thumbVisibility: WidgetStateProperty.all(true),
                  ),
                  child: Scrollbar(
                    controller: _headerScroll,
                    child: SingleChildScrollView(
                      controller: _headerScroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 9),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // GRUPO IZQUIERDO: Título + Buscador
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 24,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Gestión Citas',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 20),
                                // Buscador
                                SizedBox(
                                  width: (constraints.maxWidth - 670).clamp(
                                    200.0,
                                    400.0,
                                  ),
                                  child: TextField(
                                    controller: searchCtrl,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Buscar por telefono, nombre o ID',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                      suffixIcon:
                                          searchCtrl.text.isNotEmpty
                                              ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  searchCtrl.clear();
                                                  _debounce?.cancel();
                                                  Provider.of<CitasProvider>(
                                                    context,
                                                    listen: false,
                                                  ).setSearchTerm('');
                                                },
                                              )
                                              : null,
                                    ),
                                    onChanged: _onSearchChanged,
                                  ),
                                ),
                              ],
                            ),

                            // GRUPO DERECHO: Filtros + Botón
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 10),

                                // Filtro Fechas
                                Tooltip(
                                  message: "Filtrar por fecha",
                                  child: _HoverableFilterButton(
                                    isActive:
                                        citasProvider.filterFechaInicio !=
                                            null ||
                                        citasProvider.filterFechaFin != null,
                                    onTap: () async {
                                      final pickedRange =
                                          await CustomDateRangePicker.show(
                                            context,
                                            initialStartDate:
                                                citasProvider.filterFechaInicio,
                                            initialEndDate:
                                                citasProvider.filterFechaFin,
                                            firstDate: DateTime(2023),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                          );

                                      if (pickedRange != null) {
                                        citasProvider.setDateRange(
                                          pickedRange.start,
                                          pickedRange.end,
                                        );
                                      }
                                    },
                                    onClear:
                                        () => citasProvider.setDateRange(
                                          null,
                                          null,
                                        ),
                                    label:
                                        (citasProvider.filterFechaInicio !=
                                                    null &&
                                                citasProvider.filterFechaFin !=
                                                    null)
                                            ? (citasProvider
                                                        .filterFechaInicio ==
                                                    citasProvider.filterFechaFin
                                                ? DateFormat(
                                                  'dd MMM yy',
                                                  'es_ES',
                                                ).format(
                                                  citasProvider
                                                      .filterFechaInicio!,
                                                )
                                                : "${DateFormat('dd/MM/y', 'es_ES').format(citasProvider.filterFechaInicio!)} - ${DateFormat('dd/MM/y', 'es_ES').format(citasProvider.filterFechaFin!)}")
                                            : "Fechas",
                                    icon: Icons.calendar_today,
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 10),

                                // Filtro estado
                                Tooltip(
                                  message: "Filtrar por estado",
                                  child: _buildStatusDropdown(citasProvider),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 10),

                                // Nueva Cita
                                Tooltip(
                                  message: "Crear Cita",
                                  child: HoverableActionButton(
                                    label: "Nueva Cita",
                                    icon: Icons.add,
                                    isPrimary: true,
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const CitaModal(),
                                      );
                                    },
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
              },
            ),
          ),

          const SizedBox(height: 20),

          // TABLA Y KPIS
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool showKpis = constraints.maxWidth > 800;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: PaginatedTable(
                        isLoading: citasProvider.isLoading,
                        isEmpty: citas.isEmpty,
                        emptyMessage: "No se encuentran citas con esos filtros",
                        totalElements: citasProvider.totalElements,
                        pageSize: citasProvider.pageSize,
                        currentPage: citasProvider.currentPage,
                        rowSpacing: 8.0,
                        hoverElevation: 0.0,
                        enableSmoothTransitions: true,
                        onPageChanged: (page) {
                          citasProvider.setPage(page);
                        },
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Id",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Fecha y Hora",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Paciente",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Forma de Pago",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Estado",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Acciones",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            citas.map((cita) {
                              String fecha = DateFormat(
                                'dd/MM/yy, HH:mm',
                              ).format(cita.fechaHoraInicio);
                              Color estadoColor;
                              switch (cita.estado.toLowerCase()) {
                                case 'programada':
                                  estadoColor = Colors.blue;
                                  break;
                                case 'completada':
                                  estadoColor = Colors.green;
                                  break;
                                case 'cancelada':
                                  estadoColor = Colors.red;
                                  break;
                                case 'ausente':
                                  estadoColor = Colors.grey;
                                  break;
                                default:
                                  estadoColor = Colors.grey;
                              }

                              return DataRow(
                                // Removemos el onSelectChanged global para que no interfiera cuando cliquean el Avatar, WhatsApp o Forma de Pago.
                                // La navegación al detalle de la cita se hará en un widget específico de la celda u otra zona, pero para
                                // mantener toda la fila clicable excepto esas áreas, la envolveremos en un detector de gestos si es necesario,
                                // o dejaremos el onSelectChanged activo y le daremos prioridad a botones. Flutter DataRow prioriza
                                // InkWell / IconButton hijos sobre onSelectChanged.
                                onSelectChanged: (_) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) =>
                                            CitaDetalleModal(cita: cita),
                                  ).then((value) {
                                    if (value == true) {
                                      citasProvider.loadCitas(
                                        page: citasProvider.currentPage,
                                      );
                                    } else if (value == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) =>
                                                CitaModal(citaExistente: cita),
                                      ).then((valEdit) {
                                        if (valEdit == true) {
                                          citasProvider.loadCitas(
                                            page: citasProvider.currentPage,
                                          );
                                        }
                                      });
                                    }
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Tooltip(
                                      message: "Detalles de la cita",
                                      child: Text(
                                        '#${cita.idCita}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Tooltip(
                                      message: "Detalles de la cita",
                                      child: Text(
                                        fecha,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap:
                                              () => context.push(
                                                '/pacientes/${cita.idCliente}',
                                              ),
                                          child: AvatarWidget(
                                            nombreCompleto:
                                                cita.nombreClienteCompleto,
                                            id: cita.idCliente,
                                            radius: 16,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Tooltip(
                                                  message:
                                                      "Detalles de ${cita.nombreClienteCompleto}",
                                                  child: InkWell(
                                                    onTap:
                                                        () => context.push(
                                                          '/pacientes/${cita.idCliente}',
                                                        ),
                                                    child: Text(
                                                      cita.nombreClienteCompleto,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.whatsapp,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                tooltip: "Abrir WhatsApp",
                                                onPressed: () {
                                                  String url =
                                                      'https://wa.me/34${cita.telefonoCliente.replaceAll(RegExp(r'[^\d]'), '')}';
                                                  launchUrl(Uri.parse(url));
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Tooltip(
                                      message: "Ver bono utilizado",
                                      child: InkWell(
                                        // onTap en InkWell previene que el click burbujee hasta el DataRow.onSelectChanged
                                        onTap: () {
                                          context.push(
                                            '/pacientes/${cita.idBonoCliente ?? cita.idCliente}?tabIndex=1&showBono=true&resaltarCitaId=${cita.idCita}',
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatPago(
                                                cita.infoPago,
                                              ).replaceAll(' (F)', ''),
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (cita.infoPago.contains(
                                                  'Bono de',
                                                ) ||
                                                _formatPago(
                                                  cita.infoPago,
                                                ).contains('(F)')) ...[
                                              const SizedBox(width: 6),
                                              Tooltip(
                                                message: "Pagado por familiar",
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors
                                                              .orange
                                                              .shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Fam',
                                                    style: TextStyle(
                                                      color:
                                                          Colors
                                                              .orange
                                                              .shade700,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: estadoColor,
                                          ),
                                        ),
                                        child: Text(
                                          cita.estado.toUpperCase(),
                                          style: TextStyle(
                                            color: estadoColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: "Ir a Agenda",
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Colors.blueGrey,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              context.go(
                                                '/agenda?fecha=${cita.fechaHoraInicio.toIso8601String().split('T')[0]}',
                                              );
                                            },
                                          ),
                                        ),
                                        Tooltip(
                                          message: "Editar Cita",
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => CitaModal(
                                                      citaExistente: cita,
                                                    ),
                                              ).then((value) {
                                                if (value == true) {
                                                  citasProvider.loadCitas(
                                                    page:
                                                        citasProvider
                                                            .currentPage,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                    if (showKpis) const SizedBox(width: 20),
                    if (showKpis)
                      SizedBox(
                        width: uiProvider.isCitasSidePanelCollapsed ? 80 : 250,
                        child: _buildKpiPanel(kpis, citasProvider.isLoading),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS AUXILIARES PARA EL HEADER

  Widget _buildStatusDropdown(CitasProvider provider) {
    return DashboardDropdown<String?>(
      selectedValue: provider.filterEstado,
      tooltip: "Filtrar por estado",
      onSelected: (val) => provider.setFilterEstado(val),
      customLabel:
          provider.filterEstado != null
              ? provider.filterEstado![0].toUpperCase() +
                  provider.filterEstado!.substring(1)
              : "Estado",
      customIcon: Icons.filter_alt_outlined,
      options: const [
        DropdownOption(
          value: null,
          label: "Todos los estados",
          icon: Icons.list,
          color: Colors.grey,
        ),
        DropdownOption(
          value: "programada",
          label: "Programada",
          icon: Icons.event,
          color: Colors.blue,
        ),
        DropdownOption(
          value: "completada",
          label: "Completada",
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        DropdownOption(
          value: "cancelada",
          label: "Cancelada",
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        ),
        DropdownOption(
          value: "ausente",
          label: "Ausente",
          icon: Icons.person_off_outlined,
          color: Colors.grey,
        ),
      ],
    );
  }

  // WIDGET DEL PANEL LATERAL KPI
  Widget _buildKpiPanel(dynamic kpis, bool isLoading) {
    final uiProvider = Provider.of<UiProvider>(context);
        return Container(
      padding: EdgeInsets.all(uiProvider.isCitasSidePanelCollapsed ? 10 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment:
            uiProvider.isCitasSidePanelCollapsed
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                uiProvider.isCitasSidePanelCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
            children: [
              if (!uiProvider.isCitasSidePanelCollapsed)
                Text(
                  "Resumen Actual",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              Tooltip(
                message:
                    uiProvider.isCitasSidePanelCollapsed
                        ? "Expandir"
                        : "Colapsar",
                child: InkWell(
                  onTap: () => uiProvider.toggleCitasSidePanel(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      uiProvider.isCitasSidePanelCollapsed
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isLoading && kpis == null) ...[
            const SizedBox(height: 25),
            if (uiProvider.isCitasSidePanelCollapsed)
              const _KpiItem(
                icon: Icons.hourglass_empty,
                label: "Cargando",
                value: "...",
                color: Colors.grey,
                isCollapsed: true,
              )
            else
              const KpiSkeletonLoader(count: 3),
          ] else ...[
            if (!uiProvider.isCitasSidePanelCollapsed) ...[
              const SizedBox(height: 5),
              Text(
                "Datos basados en los filtros aplicados",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 25),

            if (kpis != null) ...[
              _KpiItem(
                icon: Icons.list_alt,
                label: "Total Filtradas",
                value: kpis.total.toString(),
                color: Colors.blueGrey,
                isCollapsed: uiProvider.isCitasSidePanelCollapsed,
              ),
              if (!uiProvider.isCitasSidePanelCollapsed)
                const Divider(height: 30)
              else
                const SizedBox(height: 15),
              _KpiItem(
                icon: Icons.event,
                label: "Programadas",
                value: kpis.programadas.toString(),
                color: AppTheme.primaryColor,
                isCollapsed: uiProvider.isCitasSidePanelCollapsed,
              ),
              const SizedBox(height: 15),
              _KpiItem(
                icon: Icons.check_circle_outline,
                label: "Completadas",
                value: kpis.completadas.toString(),
                color: Colors.green,
                isCollapsed: uiProvider.isCitasSidePanelCollapsed,
              ),
              const SizedBox(height: 15),
              _KpiItem(
                icon: Icons.cancel_outlined,
                label: "Canceladas",
                value: kpis.canceladas.toString(),
                color: Colors.red,
                isCollapsed: uiProvider.isCitasSidePanelCollapsed,
              ),
              const SizedBox(height: 15),
              _KpiItem(
                icon: Icons.person_off_outlined,
                label: "Ausentes",
                value: kpis.ausentes.toString(),
                color: Colors.grey,
                isCollapsed: uiProvider.isCitasSidePanelCollapsed,
              ),
            ] else ...[
              Center(
                child:
                    uiProvider.isCitasSidePanelCollapsed
                        ? const Icon(Icons.do_not_disturb)
                        : const Text("No hay datos"),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// COMPONENTE DROPDOWN PERZONALIZADO
class _HeaderDropdown extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _HeaderDropdown({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onClear,
  });

  @override
  State<_HeaderDropdown> createState() => _HeaderDropdownState();
}

class _HeaderDropdownState extends State<_HeaderDropdown> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : _isHovering
                    ? Colors.grey.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.isActive
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color:
                    widget.isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color:
                      widget.isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade700,
                  fontWeight:
                      widget.isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onClear,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isCollapsed;

  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Tooltip(
        message: "$label: $value",
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget para añadir hover a los botones
class _HoverableFilterButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String label;
  final IconData icon;
  final bool isActive;

  const _HoverableFilterButton({
    required this.onTap,
    this.onClear,
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  @override
  State<_HoverableFilterButton> createState() => _HoverableFilterButtonState();
}

class _HoverableFilterButtonState extends State<_HoverableFilterButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? Colors.blue.shade50
                    : (_isHovering ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.isActive ? Colors.blue.shade200 : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? Colors.blue : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isActive && widget.onClear != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: GestureDetector(
                    onTap: widget.onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
