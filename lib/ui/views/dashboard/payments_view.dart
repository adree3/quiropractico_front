import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/custom_date_range_picker.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_loader.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:go_router/go_router.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  String _filtroLabel = 'Histórico Total';
  String _kpiContexto = '(Total)';
  final _searchCtrl = TextEditingController();
  final ScrollController _headerScroll = ScrollController();
  final ScrollController _pendingScroll = ScrollController();
  final ScrollController _historyScroll = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerScroll.dispose();
    _pendingScroll.dispose();
    _historyScroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pendingScroll.addListener(_onScrollPending);
    _historyScroll.addListener(_onScrollHistory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarFiltro('SIEMPRE');
    });
  }

  void _onScrollPending() {
    if (_pendingScroll.position.pixels >=
        _pendingScroll.position.maxScrollExtent - 200) {
      context.read<PaymentsProvider>().loadMorePendientes();
    }
  }

  void _onScrollHistory() {
    if (_historyScroll.position.pixels >=
        _historyScroll.position.maxScrollExtent - 200) {
      context.read<PaymentsProvider>().loadMoreHistorial();
    }
  }

  Future<void> _aplicarFiltro(String tipo) async {
    final now = DateTime.now();
    DateTime inicio = DateTime(2020);
    DateTime fin = DateTime(2100);
    String label = "Histórico Total";
    String contexto = "(Total)";

    if (tipo == 'CUSTOM') {
      final picked = await CustomDateRangePicker.show(
        context,
        initialStartDate: null,
        initialEndDate: null,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (picked == null) return;

      inicio = picked.start;
      fin = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      label =
          "${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}";
      contexto =
          "(${DateFormat('dd/MM').format(inicio)} - ${DateFormat('dd/MM').format(fin)})";
    } else {
      switch (tipo) {
        case 'HOY':
          inicio = DateTime(now.year, now.month, now.day);
          fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          label = "Hoy";
          contexto = "(Hoy)";
          break;
        case 'SEMANA':
          inicio = now.subtract(Duration(days: now.weekday - 1));
          inicio = DateTime(inicio.year, inicio.month, inicio.day);
          label = "Esta Semana";
          contexto = "(Semana)";
          break;
        case 'MES':
          inicio = DateTime(now.year, now.month, 1);
          fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          label = "Este Mes";
          contexto = "(Mes)";
          break;
      }
    }

    setState(() {
      _filtroLabel = label;
      _kpiContexto = contexto;
    });
    if (mounted) {
      Provider.of<PaymentsProvider>(
        context,
        listen: false,
      ).loadAll(inicio, fin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final rol = authProvider.role ?? '';
    final esJefe = rol == 'admin' || rol == 'quiropráctico';

    // Datos KPis
    final int cantidadVentas = provider.totalHistorialCount;
    final int cantidadPendientes = provider.totalPendientesCount;

    String cobradoPrincipal;
    String cobradoSecundario;
    String pendientePrincipal;
    String pendienteSecundario;

    if (esJefe) {
      cobradoPrincipal = "${provider.totalCobrado.toStringAsFixed(2)} €";
      cobradoSecundario = "$cantidadVentas ventas";
      pendientePrincipal = "${provider.totalPendiente.toStringAsFixed(2)} €";
      pendienteSecundario = "$cantidadPendientes pendientes";
    } else {
      cobradoPrincipal = "$cantidadVentas";
      cobradoSecundario = "ventas realizadas";
      pendientePrincipal = "$cantidadPendientes";
      pendienteSecundario = "pagos pendientes";
    }

    return DefaultTabController(
      length: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(
                      Colors.grey.withOpacity(0.3),
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
                          minWidth:
                              constraints
                                  .maxWidth, // Estirar la cabecera al 100%
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 10),
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

                                  SizedBox(
                                    width: (constraints.maxWidth - 400).clamp(
                                      200.0,
                                      400.0,
                                    ), // Buscador dinámico estilo clients_view
                                    child: TextField(
                                      controller: _searchCtrl,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Buscar por paciente o concepto...',
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
                                            provider
                                                    .currentSearchTerm
                                                    .isNotEmpty
                                                ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    _searchCtrl.clear();
                                                    provider.onSearchChanged(
                                                      '',
                                                    );
                                                  },
                                                )
                                                : null,
                                      ),
                                      onChanged:
                                          (val) =>
                                              provider.onSearchChanged(val),
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
                                        value: 'SIEMPRE',
                                        label: "Histórico Total",
                                        icon: Icons.history,
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
                                        value: 'MES',
                                        label: "Este Mes",
                                        icon: Icons.calendar_month,
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
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // KPIs
            Row(
              children: [
                Expanded(
                  child: _KpiCardColored(
                    title:
                        esJefe
                            ? "Cobrado $_kpiContexto"
                            : "Ventas $_kpiContexto",
                    mainText: cobradoPrincipal,
                    subText: cobradoSecundario,
                    color: Colors.green,
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _KpiCardColored(
                    title:
                        esJefe ? "Deuda Total (Global)" : "Pendientes (Global)",
                    mainText: pendientePrincipal,
                    subText: pendienteSecundario,
                    color: Colors.orange,
                    icon: Icons.pending_actions,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // PESTAÑAS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                  left: BorderSide(color: Colors.grey.shade300),
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide.none,
                ),
              ),
              child: TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text("PENDIENTES (${provider.totalPendientesCount})"),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        Text("HISTORIAL"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // LISTAS
            Expanded(
              child:
                  provider.isLoading
                      ? const SkeletonLoader(rowCount: 8)
                      : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // LISTADO PENDIENTES
                          _InfiniteScrollList(
                            isLoading: provider.isLoadingPendientes,
                            isLoadingMore: provider.isLoadingMorePendientes,
                            hasMore: provider.hasMorePendientes,
                            isEmpty: provider.listaPendientes.isEmpty,
                            emptyMessage:
                                "¡Todo al día! No hay pagos pendientes.",
                            controller: _pendingScroll,
                            columns: const [
                              _TableCol(label: "Id", flex: 1),
                              _TableCol(label: "Fecha", flex: 3),
                              _TableCol(label: "Paciente", flex: 4),
                              _TableCol(label: "Concepto", flex: 3),
                              _TableCol(label: "Importe", flex: 2),
                              _TableCol(label: "Acción", flex: 2),
                            ],
                            items:
                                provider.listaPendientes.map((pago) {
                                  return _TableRow(
                                    key: ValueKey("p-${pago.idPago}"),
                                    cells: [
                                      Text(
                                        "#${pago.idPago}",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(pago.fechaPago),
                                      ),
                                      Tooltip(
                                        message:
                                            "Detalles de ${pago.nombreCliente}",
                                        child: InkWell(
                                          onTap: () {
                                            context.push(
                                              '/pacientes/${pago.idCliente}',
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              children: [
                                                AvatarWidget(
                                                  nombreCompleto:
                                                      pago.nombreCliente,
                                                  id: pago.idPago,
                                                  radius: 14,
                                                  fontSize: 12,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    pago.nombreCliente,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        pago.concepto,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "${pago.monto} €",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      // Botón Cobrar
                                      _CobrarButton(pago: pago),
                                    ],
                                  );
                                }).toList(),
                          ),

                          // LISTADO HISTORIAL
                          _InfiniteScrollList(
                            isLoading: provider.isLoadingHistorial,
                            isLoadingMore: provider.isLoadingMoreHistorial,
                            hasMore: provider.hasMoreHistorial,
                            isEmpty: provider.listaHistorial.isEmpty,
                            emptyMessage: "No hay movimientos en este periodo.",
                            controller: _historyScroll,
                            columns: const [
                              _TableCol(label: "Id", flex: 1),
                              _TableCol(label: "Fecha/Hora", flex: 3),
                              _TableCol(label: "Paciente", flex: 4),
                              _TableCol(label: "Concepto", flex: 3),
                              _TableCol(
                                label: "Método",
                                flex: 2,
                                isCenter: true,
                              ),
                              _TableCol(
                                label: "Estado",
                                flex: 2,
                                isCenter: true,
                              ),
                              _TableCol(label: "Importe", flex: 2),
                            ],
                            items:
                                provider.listaHistorial.map((pago) {
                                  final isPaid = pago.pagado;
                                  return _TableRow(
                                    key: ValueKey("h-${pago.idPago}"),
                                    cells: [
                                      Text(
                                        "#${pago.idPago}",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd/MM HH:mm',
                                        ).format(pago.fechaPago),
                                      ),
                                      Tooltip(
                                        message:
                                            "Detalles de ${pago.nombreCliente}",
                                        child: InkWell(
                                          onTap: () {
                                            context.push(
                                              '/pacientes/${pago.idCliente}',
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              children: [
                                                AvatarWidget(
                                                  nombreCompleto:
                                                      pago.nombreCliente,
                                                  id: pago.idPago,
                                                  radius: 14,
                                                  fontSize: 12,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    pago.nombreCliente,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        pago.concepto,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Chip(
                                        label: Text(
                                          pago.metodoPago.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.grey.shade100,
                                      ),
                                      _EstadoBadge(isPaid: isPaid),
                                      Text(
                                        "${pago.monto} €",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isPaid
                                                  ? Colors.black87
                                                  : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCardColored extends StatelessWidget {
  final String title;
  final String mainText;
  final String subText;
  final Color color;
  final IconData icon;

  const _KpiCardColored({
    required this.title,
    required this.mainText,
    required this.subText,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color.darken(0.1),
                  ),
                ),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _InfiniteScrollList extends StatefulWidget {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isEmpty;
  final String emptyMessage;
  final ScrollController controller;
  final List<_TableCol> columns;
  final List<Widget> items;

  const _InfiniteScrollList({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.isEmpty,
    required this.emptyMessage,
    required this.controller,
    required this.columns,
    required this.items,
  });

  @override
  State<_InfiniteScrollList> createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<_InfiniteScrollList> {
  late final ScrollController _horizontalScroll;

  @override
  void initState() {
    super.initState();
    _horizontalScroll = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return const SkeletonLoader(rowCount: 8);
    }

    if (widget.isEmpty && !widget.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.3)),
              thickness: WidgetStateProperty.all(8),
              radius: const Radius.circular(10),
            ),
            child: Scrollbar(
              controller: _horizontalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width:
                      constraints.maxWidth > 1050
                          ? constraints.maxWidth
                          : 1050.0,
                  child: Column(
                    children: [
                      // Header Fijo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00AEEF),
                        ),
                        child: Row(
                          children:
                              widget.columns
                                  .map((col) => col.toWidget())
                                  .toList(),
                        ),
                      ),
                      // Lista con Scroll
                      Expanded(
                        child: ListView.separated(
                          controller: widget.controller,
                          itemCount:
                              widget.items.length + (widget.hasMore ? 1 : 0),
                          padding: EdgeInsets.zero,
                          separatorBuilder:
                              (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                          itemBuilder: (context, index) {
                            if (index == widget.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return widget.items[index];
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableCol {
  final String label;
  final int flex;
  final bool isCenter;

  const _TableCol({
    required this.label,
    required this.flex,
    this.isCenter = false,
  });

  Widget toWidget() {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final List<Widget> cells;
  const _TableRow({super.key, required this.cells});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _isHovered ? Colors.grey.shade50 : Colors.white,
        child: Row(
          children:
              widget.cells.asMap().entries.map((entry) {
                final idx = entry.key;
                final cell = entry.value;
                // Necesitamos saber el flex de la columna correspondiente.
                // Para simplificar, usaremos los mismos flex que en _InfiniteScrollList.
                // En un diseño real, esto debería pasarse o compartirse.
                // Por simplicidad en este refactor, mapearemos los flex manualmente
                // basados en el orden de las columnas enviadas en PaymentsView.
                int flex = 2; // default
                bool isCenter = false;

                // Lógica de mapeo de flex (debe coincidir con las columnas definidas arriba)
                // Esto es un poco rígido pero efectivo para este componente privado.
                if (widget.cells.length == 6) {
                  // Pendientes
                  final flexes = [1, 3, 4, 3, 2, 2];
                  flex = flexes[idx];
                } else if (widget.cells.length == 7) {
                  // Historial
                  final flexes = [1, 3, 4, 3, 2, 2, 2];
                  flex = flexes[idx];
                  if (idx == 4 || idx == 5) isCenter = true;
                }

                return Expanded(
                  flex: flex,
                  child: Align(
                    alignment:
                        isCenter ? Alignment.center : Alignment.centerLeft,
                    child: cell,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _CobrarButton extends StatefulWidget {
  final Pago pago;
  const _CobrarButton({required this.pago});

  @override
  State<_CobrarButton> createState() => _CobrarButtonState();
}

class _CobrarButtonState extends State<_CobrarButton> {
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text(
              "¡PAGADO!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final error = await Provider.of<PaymentsProvider>(
          context,
          listen: false,
        ).confirmarPago(widget.pago.idPago);
        if (context.mounted) {
          if (error == null) {
            setState(() => _isSuccess = true);
            final fechaFormat = DateFormat(
              'dd/MM/yyyy',
            ).format(widget.pago.fechaPago);
            CustomSnackBar.show(
              context,
              message:
                  "Pago de ${widget.pago.nombreCliente} del $fechaFormat cobrado",
              type: SnackBarType.success,
              actionLabel: "DESHACER",
              onAction: () async {
                await Provider.of<PaymentsProvider>(
                  context,
                  listen: false,
                ).deshacerPago(widget.pago.idPago);
                if (context.mounted) {
                  CustomSnackBar.show(
                    context,
                    message: "Cobro deshecho",
                    type: SnackBarType.info,
                  );
                }
              },
            );
          } else {
            CustomSnackBar.show(
              context,
              message: error,
              type: SnackBarType.error,
            );
          }
        }
      },
      icon: const Icon(Icons.check, size: 16),
      label: const Text("COBRAR"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final bool isPaid;
  const _EstadoBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isPaid
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isPaid
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Text(
        isPaid ? "PAGADO" : "PENDIENTE",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPaid ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
