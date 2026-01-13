import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  String _filtroLabel = 'Histórico Total';
  String _kpiContexto = '(Total)';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarFiltro('SIEMPRE');
    });
  }

  Future<void> _aplicarFiltro(String tipo) async {
    final now = DateTime.now();
    DateTime inicio = DateTime(2020);
    DateTime fin = DateTime(2100);
    String label = "Histórico Total";
    String contexto = "(Total)";

    if (tipo == 'CUSTOM') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('es', 'ES'),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
              ),
            ),
            child: child!,
          );
        },
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
            Container(
              padding: const EdgeInsets.all(10),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  const SizedBox(width: 15),

                  // Buscador
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar por paciente o concepto...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon:
                            provider.currentSearchTerm.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    provider.onSearchChanged('');
                                  },
                                )
                                : null,
                      ),
                      onChanged: (val) => provider.onSearchChanged(val),
                    ),
                  ),

                  const SizedBox(width: 15),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  const SizedBox(width: 15),

                  // Filtro de Fecha (Dropdown)
                  DashboardDropdown<String>(
                    selectedValue:
                        'CUSTOM', // Dummy value or track actual selected key if possible
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
                        Icon(Icons.history, size: 20),
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
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // TABLA PENDIENTES
                          _PaginatedTable(
                            isLoading: provider.isLoadingPendientes,
                            isEmpty: provider.listaPendientes.isEmpty,
                            emptyMessage:
                                "¡Todo al día! No hay pagos pendientes.",
                            totalElements: provider.totalPendientesCount,
                            pageSize: provider.pageSize,
                            currentPage: provider.pagePendientes,
                            onPageChanged:
                                (p) => provider.getPagosPendientes(page: p),

                            // COLUMNAS
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "#",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Fecha",
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
                                  "Concepto",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Importe",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Expanded(
                                  child: Text(
                                    "Acción",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ],
                            // FILAS
                            rows:
                                provider.listaPendientes.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final pago = entry.value;
                                  final globalIndex =
                                      (provider.pagePendientes *
                                          provider.pageSize) +
                                      index +
                                      1;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          "$globalIndex",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(pago.fechaPago),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          pago.nombreCliente,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(pago.concepto)),
                                      DataCell(
                                        Text(
                                          "${pago.monto} €",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final error = await Provider.of<
                                                PaymentsProvider
                                              >(
                                                context,
                                                listen: false,
                                              ).confirmarPago(pago.idPago);
                                              if (context.mounted) {
                                                if (error == null) {
                                                  CustomSnackBar.show(
                                                    context,
                                                    message: "Pago confirmado",
                                                    type: SnackBarType.success,
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
                                            icon: const Icon(
                                              Icons.check,
                                              size: 16,
                                            ),
                                            label: const Text("COBRAR"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),

                          // TABLA HISTORIAL
                          _PaginatedTable(
                            isLoading: provider.isLoadingHistorial,
                            isEmpty: provider.listaHistorial.isEmpty,
                            emptyMessage: "No hay movimientos en este periodo.",
                            totalElements: provider.totalHistorialCount,
                            pageSize: provider.pageSize,
                            currentPage: provider.pageHistorial,
                            onPageChanged:
                                (p) => provider.getPagosHistorial(page: p),

                            columns: const [
                              DataColumn(
                                label: Text(
                                  "#",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Fecha/Hora",
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
                                  "Concepto",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Método",
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
                                  "Importe",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],

                            rows:
                                provider.listaHistorial.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final pago = entry.value;
                                  final globalIndex =
                                      (provider.pageHistorial *
                                          provider.pageSize) +
                                      index +
                                      1;
                                  final isPaid = pago.pagado;
                                  return DataRow(
                                    color: WidgetStateProperty.all(
                                      isPaid
                                          ? Colors.white
                                          : Colors.orange.shade50.withOpacity(
                                            0.3,
                                          ),
                                    ),
                                    cells: [
                                      DataCell(
                                        Text(
                                          "$globalIndex",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat(
                                            'dd/MM HH:mm',
                                          ).format(pago.fechaPago),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          pago.nombreCliente,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          pago.concepto,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
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
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isPaid
                                                    ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                    : Colors.orange.withOpacity(
                                                      0.1,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isPaid ? "PAGADO" : "PENDIENTE",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isPaid
                                                      ? Colors.green
                                                      : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Texto Principal
                  Text(
                    mainText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  // Texto Secundario
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
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

class _PaginatedTable extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final int totalElements;
  final int pageSize;
  final int currentPage;
  final Function(int) onPageChanged;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const _PaginatedTable({
    required this.isLoading,
    required this.isEmpty,
    required this.emptyMessage,
    required this.totalElements,
    required this.pageSize,
    required this.currentPage,
    required this.onPageChanged,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final bool showPagination = totalElements > pageSize;
    final int totalPages = (totalElements / pageSize).ceil();

    final int startRecord = (currentPage * pageSize) + 1;
    final int endRecord = min((currentPage + 1) * pageSize, totalElements);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        child: Column(
          children: [
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              emptyMessage,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Color(0xFF00AEEF),
                            ),
                            columnSpacing: 20,
                            dataRowMinHeight: 55,
                            dataRowMaxHeight: 55,
                            columns: columns,
                            rows: rows,
                          ),
                        ),
                      ),
            ),

            if (showPagination && !isLoading && !isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Mostrando $startRecord - $endRecord de $totalElements registros",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              currentPage > 0
                                  ? () => onPageChanged(currentPage - 1)
                                  : null,
                          padding: EdgeInsets.zero,
                          tooltip: "Anterior",
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Página ${currentPage + 1} de $totalPages",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              currentPage < totalPages - 1
                                  ? () => onPageChanged(currentPage + 1)
                                  : null,
                          padding: EdgeInsets.zero,
                          tooltip: "Siguiente",
                        ),
                      ],
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
