import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/custom_date_range_picker.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/premium_data_table.dart';
import 'package:quiropractico_front/ui/widgets/financial_kpi_card.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  String _filtroLabel = 'Este Mes';
  String _kpiContexto = '(Mes)';
  Timer? _searchDebounce;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _headerScroll = ScrollController();
  final ScrollController _scrollPendientes = ScrollController();
  final ScrollController _scrollHistorial = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollPendientes.addListener(_onPendientesScroll);
    _scrollHistorial.addListener(_onHistorialScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarFiltro('MES');
    });
  }

  void _onPendientesScroll() {
    if (!_scrollPendientes.hasClients) return;
    final maxScroll = _scrollPendientes.position.maxScrollExtent;
    final currentScroll = _scrollPendientes.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.90) {
      context.read<PaymentsProvider>().loadMorePendientes();
    }
  }

  void _onHistorialScroll() {
    if (!_scrollHistorial.hasClients) return;
    final maxScroll = _scrollHistorial.position.maxScrollExtent;
    final currentScroll = _scrollHistorial.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.90) {
      context.read<PaymentsProvider>().loadMoreHistorial();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _headerScroll.dispose();
    _scrollPendientes.removeListener(_onPendientesScroll);
    _scrollPendientes.dispose();
    _scrollHistorial.removeListener(_onHistorialScroll);
    _scrollHistorial.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<PaymentsProvider>().onSearchChanged(val);
      }
    });
  }

  Future<void> _aplicarFiltro(String tipo) async {
    final now = DateTime.now();
    DateTime? inicio;
    DateTime? fin;
    String label = "Este Mes";
    String contexto = "(Mes)";

    if (tipo == 'CUSTOM') {
      final picked = await CustomDateRangePicker.show(
        context,
        initialStartDate: context.read<PaymentsProvider>().fechaInicio,
        initialEndDate: context.read<PaymentsProvider>().fechaFin,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (picked == null) return;

      inicio = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      fin = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      label =
          "${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}";
      contexto =
          "(${DateFormat('dd/MM').format(inicio)} - ${DateFormat('dd/MM').format(fin)})";
    } else {
      switch (tipo) {
        case 'HOY':
          inicio = DateTime(now.year, now.month, now.day, 0, 0, 0);
          fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          label = "Hoy";
          contexto = "(Hoy)";
          break;
        case 'SEMANA':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          inicio = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
          fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          label = "Esta Semana";
          contexto = "(Semana)";
          break;
        case 'MES':
          inicio = DateTime(now.year, now.month, 1, 0, 0, 0);
          fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          label = "Este Mes";
          contexto = "(Mes)";
          break;
        case 'SIEMPRE':
          inicio = null;
          fin = null;
          label = "Histórico Total";
          contexto = "(Total)";
          break;
      }
    }

    setState(() {
      _filtroLabel = label;
      _kpiContexto = contexto;
    });

    if (mounted) {
      context.read<PaymentsProvider>().setDateRange(inicio, fin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esJefe = authProvider.isGestor;

    final int cantidadVentas = provider.totalVentas > 0
        ? provider.totalVentas
        : provider.totalHistorialCount;

    return DefaultTabController(
      length: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SUPERIOR CON BÚSQUEDA Y FILTRO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(
                        Colors.grey.withValues(alpha: 0.3),
                      ),
                      thickness: WidgetStateProperty.all(4),
                      radius: const Radius.circular(10),
                    ),
                    child: Scrollbar(
                      controller: _headerScroll,
                      child: SingleChildScrollView(
                        controller: _headerScroll,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 24,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Gestionar Pagos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 15),

                                  // Buscador sincronizado con el backend
                                  SizedBox(
                                    width: (constraints.maxWidth - 420).clamp(
                                      200.0,
                                      400.0,
                                    ),
                                    child: TextField(
                                      controller: _searchCtrl,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Buscar por paciente o concepto...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                        suffixIcon:
                                            _searchCtrl.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 18,
                                                      color: Colors.grey,
                                                    ),
                                                    onPressed: () {
                                                      _searchCtrl.clear();
                                                      _searchDebounce?.cancel();
                                                      provider.onSearchChanged('');
                                                    },
                                                  )
                                                : null,
                                      ),
                                      onChanged: _onSearchChanged,
                                    ),
                                  ),

                                  const SizedBox(width: 15),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 15),

                                  // Filtro de Fecha (Dropdown)
                                  DashboardDropdown<String>(
                                    tooltip: "Filtrar Fecha",
                                    selectedValue: 'CUSTOM',
                                    customLabel: _filtroLabel,
                                    customIcon: Icons.calendar_today,
                                    onSelected: _aplicarFiltro,
                                    options: const [
                                      DropdownOption(
                                        value: 'MES',
                                        label: "Este Mes",
                                        icon: Icons.calendar_month,
                                      ),
                                      DropdownOption(
                                        value: 'HOY',
                                        label: "Hoy",
                                        icon: Icons.today,
                                      ),
                                      DropdownOption(
                                        value: 'SEMANA',
                                        label: "Esta Semana",
                                        icon: Icons.date_range,
                                      ),
                                      DropdownOption(
                                        value: 'SIEMPRE',
                                        label: "Histórico Total",
                                        icon: Icons.history,
                                      ),
                                      DropdownOption(
                                        value: 'CUSTOM',
                                        label: "Rango Personalizado...",
                                        icon: Icons.edit_calendar,
                                      ),
                                    ],
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

            const SizedBox(height: 14),

            // 2. HEADER FINANCIERO: GRID HORIZONTAL DE 4 KPI CARDS (Flat Desktop + RBAC)
            Row(
              children: [
                // KPI 1: Cobrado (General)
                Expanded(
                  child: FinancialKpiCard(
                    title: esJefe
                        ? "Cobrado $_kpiContexto"
                        : "Ventas $_kpiContexto",
                    importeText:
                        "${provider.totalCobrado.toStringAsFixed(2)} €",
                    countText: esJefe
                        ? "$cantidadVentas ventas registradas"
                        : "$cantidadVentas",
                    countLabel: esJefe ? null : "ventas realizadas",
                    isGestor: esJefe,
                    accentColor: const Color(0xFF10B981),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),

                // KPI 2: Efectivo (Filtro de periodo)
                Expanded(
                  child: FinancialKpiCard(
                    title: "Efectivo $_kpiContexto",
                    importeText:
                        "${provider.totalEfectivo.toStringAsFixed(2)} €",
                    countText: esJefe
                        ? "${provider.cantidadEfectivo} cobros en efectivo"
                        : "${provider.cantidadEfectivo}",
                    countLabel: esJefe ? null : "cobros en efectivo",
                    isGestor: esJefe,
                    accentColor: const Color(0xFF0D9488),
                    icon: Icons.point_of_sale_outlined,
                  ),
                ),
                const SizedBox(width: 12),

                // KPI 3: Ventas en Bonos (Fidelización)
                Expanded(
                  child: FinancialKpiCard(
                    title: "Ventas en Bonos",
                    importeText:
                        "${provider.totalBonos.toStringAsFixed(2)} €",
                    countText: esJefe
                        ? "${provider.porcentajeBonos.toStringAsFixed(1)}% total (${provider.cantidadBonos} bonos)"
                        : "${provider.cantidadBonos}",
                    countLabel: esJefe ? null : "bonos vendidos",
                    isGestor: esJefe,
                    accentColor: const Color(0xFF8B5CF6),
                    icon: Icons.card_membership_outlined,
                  ),
                ),
                const SizedBox(width: 12),

                // KPI 4: Deuda Pendiente (Global)
                Expanded(
                  child: FinancialKpiCard(
                    title: esJefe
                        ? "Deuda Pendiente (Global)"
                        : "Pagos Pendientes (Global)",
                    importeText:
                        "${provider.totalPendiente.toStringAsFixed(2)} €",
                    countText: esJefe
                        ? "${provider.totalPendientesCount} pagos pendientes"
                        : "${provider.totalPendientesCount}",
                    countLabel: esJefe ? null : "pagos pendientes",
                    isGestor: esJefe,
                    accentColor: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. TABLA CON TAB NAVIGATION INTEGRADO (Estructura Monolítica sin wrapInCard)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Cabecera de pestañas integrada en la parte superior de la tabla
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        indicatorColor: AppTheme.primaryColor,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey.shade600,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "PAGOS PENDIENTES (${provider.totalPendientesCount})",
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.history, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "HISTORIAL DE MOVIMIENTOS (${provider.totalHistorialCount})",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cuerpo de la tabla con paginación delegada estricta
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildPendientesTable(context, provider),
                          _buildHistorialTable(context, provider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tabla de Pagos Pendientes con [PremiumDataTable] y scroll infinito
  Widget _buildPendientesTable(
    BuildContext context,
    PaymentsProvider provider,
  ) {
    const columnFlexes = [1, 2, 3, 3, 1, 2];

    return PremiumDataTable<Pago>(
      items: provider.pendientes,
      wrapInCard: false,
      isLoading: provider.isLoadingPendientes,
      hasMore: provider.hasMorePendientes,
      scrollController: _scrollPendientes,
      onLoadMore: () => provider.loadMorePendientes(),
      columnFlexes: columnFlexes,
      columnHeaders: [
        _buildHeaderCell("ID", alignment: Alignment.centerLeft),
        _buildHeaderCell("Fecha", alignment: Alignment.centerLeft),
        _buildHeaderCell("Paciente", alignment: Alignment.centerLeft),
        _buildHeaderCell("Concepto", alignment: Alignment.centerLeft),
        _buildHeaderCell("Importe", alignment: Alignment.centerRight),
        _buildHeaderCell("Acción", alignment: Alignment.centerRight),
      ],
      emptyStateBuilder: (_) => _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: "¡Todo al día!",
        subtitle: "No se encontraron pagos pendientes con los filtros aplicados.",
      ),
      rowBuilder: (context, pago, index) {
        return InkWell(
          key: ValueKey('row-p-${pago.idPago}'),
          hoverColor: Colors.grey.shade50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: Colors.orange.shade600,
                  width: 4.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 13.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: columnFlexes[0],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '#${pago.idPago}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[1],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(pago.fechaPago),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[2],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: "Ver paciente: ${pago.nombreCliente}",
                      child: InkWell(
                        onTap: () => context.push('/pacientes/${pago.idCliente}'),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(
                              nombreCompleto: pago.nombreCliente,
                              id: pago.idCliente,
                              radius: 14,
                              fontSize: 11,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                pago.nombreCliente,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[3],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pago.concepto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[4],
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${pago.monto.toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[5],
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _CobrarButton(
                      key: ValueKey('btn-cobrar-${pago.idPago}'),
                      pago: pago,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye la tabla de Historial de Movimientos con [PremiumDataTable] y scroll infinito
  Widget _buildHistorialTable(
    BuildContext context,
    PaymentsProvider provider,
  ) {
    const columnFlexes = [1, 2, 3, 2, 2, 1, 1];

    return PremiumDataTable<Pago>(
      items: provider.historial,
      wrapInCard: false,
      isLoading: provider.isLoadingHistorial,
      hasMore: provider.hasMoreHistorial,
      scrollController: _scrollHistorial,
      onLoadMore: () => provider.loadMoreHistorial(),
      columnFlexes: columnFlexes,
      columnHeaders: [
        _buildHeaderCell("ID", alignment: Alignment.centerLeft),
        _buildHeaderCell("Fecha/Hora", alignment: Alignment.centerLeft),
        _buildHeaderCell("Paciente", alignment: Alignment.centerLeft),
        _buildHeaderCell("Concepto", alignment: Alignment.centerLeft),
        _buildHeaderCell("Método", alignment: Alignment.centerLeft),
        _buildHeaderCell("Estado", alignment: Alignment.centerLeft),
        _buildHeaderCell("Importe", alignment: Alignment.centerRight),
      ],
      emptyStateBuilder: (_) => _buildEmptyState(
        icon: Icons.history,
        title: "Sin movimientos",
        subtitle: "No se encontraron movimientos registrados en este periodo.",
      ),
      rowBuilder: (context, pago, index) {
        final bool isPaid = pago.pagado;
        final Color leftBorderColor =
            isPaid ? Colors.green.shade600 : Colors.orange.shade600;

        return InkWell(
          key: ValueKey('row-h-${pago.idPago}'),
          hoverColor: Colors.grey.shade50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: leftBorderColor,
                  width: 4.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 13.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: columnFlexes[0],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '#${pago.idPago}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[1],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('dd/MM HH:mm').format(pago.fechaPago),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[2],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: "Ver paciente: ${pago.nombreCliente}",
                      child: InkWell(
                        onTap: () => context.push('/pacientes/${pago.idCliente}'),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(
                              nombreCompleto: pago.nombreCliente,
                              id: pago.idCliente,
                              radius: 14,
                              fontSize: 11,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                pago.nombreCliente,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[3],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pago.concepto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[4],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        pago.metodoPago.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[5],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isPaid
                              ? Colors.green.shade300
                              : Colors.orange.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isPaid ? "PAGADO" : "PENDIENTE",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isPaid
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: columnFlexes[6],
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${pago.monto.toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPaid ? Colors.black87 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildHeaderCell(
    String title, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Align(
      alignment: alignment,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.blueGrey.shade800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón interactivo de cobrar para pagos pendientes
class _CobrarButton extends StatefulWidget {
  final Pago pago;
  const _CobrarButton({super.key, required this.pago});

  @override
  State<_CobrarButton> createState() => _CobrarButtonState();
}

class _CobrarButtonState extends State<_CobrarButton> {
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void didUpdateWidget(covariant _CobrarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pago.idPago != widget.pago.idPago) {
      _isSubmitting = false;
      _isSuccess = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
            const SizedBox(width: 4),
            Text(
              "COBRADO",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isSubmitting
          ? null
          : () async {
              setState(() => _isSubmitting = true);
              final error = await Provider.of<PaymentsProvider>(
                context,
                listen: false,
              ).confirmarPago(widget.pago.idPago);

              if (!context.mounted) return;

              if (error == null) {
                setState(() {
                  _isSubmitting = false;
                  _isSuccess = true;
                });
                final fechaFormat = DateFormat(
                  'dd/MM/yyyy',
                ).format(widget.pago.fechaPago);
                CustomSnackBar.show(
                  context,
                  message:
                      "Pago de ${widget.pago.nombreCliente} ($fechaFormat) cobrado correctamente",
                  type: SnackBarType.success,
                );
              } else {
                setState(() => _isSubmitting = false);
                CustomSnackBar.show(
                  context,
                  message: error,
                  type: SnackBarType.error,
                );
              }
            },
      icon: _isSubmitting
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check, size: 14),
      label: Text(_isSubmitting ? "COBRANDO..." : "COBRAR"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
