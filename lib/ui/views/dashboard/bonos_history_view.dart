import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/bonos_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/ui/modals/cita_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/bono_detalle_modal.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/hoverable_action_button.dart';
import 'package:quiropractico_front/ui/widgets/premium_data_table.dart';

class BonosHistoryView extends StatefulWidget {
  const BonosHistoryView({super.key});

  @override
  State<BonosHistoryView> createState() => _BonosHistoryViewState();
}

class _BonosHistoryViewState extends State<BonosHistoryView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _headerScroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<int> _columnFlexes = [1, 2, 3, 2, 2, 1, 1];

  String _filtroRapido = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BonosProvider>(context, listen: false);
      if (provider.bonos.isEmpty) {
        provider.getHistorial(refresh: true);
      } else {
        provider.getHistorial(refresh: true, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ESTRICTA: LEFT ACCENT BORDER (4px) ---
  Color _getLeftAccentBorderColor(BonoHistorico bono) {
    if (bono.sesionesRestantes == 0) {
      return Colors.grey.shade400;
    }
    if (!bono.pagado) {
      return Colors.orange.shade600;
    }
    if (!bono.tieneProximaCita) {
      return Colors.red.shade500;
    }
    return Colors.green.shade500;
  }

  List<BonoHistorico> _filtrarBonos(List<BonoHistorico> lista) {
    if (_filtroRapido == 'TODOS') return lista;
    if (_filtroRapido == 'PENDIENTES') {
      return lista.where((b) => !b.pagado).toList();
    }
    if (_filtroRapido == 'RIESGO') {
      return lista
          .where((b) => b.sesionesRestantes <= 2 && !b.tieneProximaCita)
          .toList();
    }
    if (_filtroRapido == 'ACTIVOS') {
      return lista
          .where((b) => b.pagado && b.sesionesRestantes > 0 && !b.caducado)
          .toList();
    }
    if (_filtroRapido == 'AGOTADOS') {
      return lista.where((b) => b.sesionesRestantes == 0).toList();
    }
    return lista;
  }

  Future<void> _agendarCita(BonoHistorico bono) async {
    final partes = bono.nombreCliente.trim().split(' ');
    final nombre = partes.isNotEmpty ? partes.first : bono.nombreCliente;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    final cliente = Cliente(
      idCliente: bono.idCliente,
      nombre: nombre,
      apellidos: apellidos,
      telefono: '',
      activo: true,
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => CitaModal(preSelectedClient: cliente),
    );

    if (resultado == true && mounted) {
      Provider.of<BonosProvider>(
        context,
        listen: false,
      ).getHistorial(refresh: true);
    }
  }

  Future<void> _abrirVentaBono(BuildContext context) async {
    final Cliente? clienteSeleccionado = await showDialog<Cliente>(
      context: context,
      builder: (ctx) => const _SeleccionarClienteDialog(),
    );

    if (clienteSeleccionado != null && context.mounted) {
      final ventaExitosa = await showDialog<bool>(
        context: context,
        builder: (ctx) => VentaBonoModal(cliente: clienteSeleccionado),
      );

      if (ventaExitosa == true && context.mounted) {
        Provider.of<BonosProvider>(
          context,
          listen: false,
        ).getHistorial(refresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bonosProvider = Provider.of<BonosProvider>(context);
    final bonosVisualizados = _filtrarBonos(bonosProvider.bonos);

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER ESTÁNDAR (FLAT DESKTOP)
          _buildHeader(bonosProvider),

          const SizedBox(height: 16),

          // 2. TABLA ENTERPRISE PREMIUMN
          Expanded(
            child: PremiumDataTable<BonoHistorico>(
              items: bonosVisualizados,
              isLoading: bonosProvider.isLoading && bonosProvider.bonos.isEmpty,
              hasMore: bonosProvider.hasMore,
              loadMoreThreshold: 200.0,
              onLoadMore: () => bonosProvider.getHistorial(),
              scrollController: _scrollController,
              columnFlexes: _columnFlexes,
              wrapInCard: true,
              columnHeaders: [
                _buildHeaderColumn('ID', Alignment.centerLeft),
                _buildHeaderColumn('Fecha Compra', Alignment.centerLeft),
                _buildHeaderColumn('Paciente', Alignment.centerLeft),
                _buildHeaderColumn('Servicio', Alignment.centerLeft),
                _buildHeaderColumn('Saldo de Sesiones', Alignment.centerLeft),
                _buildHeaderColumn('Estado / Pago', Alignment.centerLeft),
                _buildHeaderColumn('Acciones', Alignment.centerRight),
              ],
              rowBuilder: (context, bono, index) {
                return _buildRow(context, bono, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  // --- HEADER FLAT DESKTOP ---
  Widget _buildHeader(BonosProvider bonosProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(4),
              radius: const Radius.circular(4),
              thumbColor: WidgetStateProperty.all(
                Colors.grey.withValues(alpha: 0.35),
              ),
              trackColor: WidgetStateProperty.all(Colors.transparent),
              trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              thumbVisibility: WidgetStateProperty.all(true),
            ),
            child: Scrollbar(
              controller: _headerScroll,
              child: SingleChildScrollView(
                controller: _headerScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 9),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // GRUPO IZQUIERDO: Título + Buscador
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            Icons.confirmation_num_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Historial de Bonos y Sesiones',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${bonosProvider.totalElements} bonos',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
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
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Buscar por paciente o servicio...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
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
                                            setState(() {});
                                            bonosProvider.onSearchChanged('');
                                          },
                                        )
                                        : null,
                              ),
                              onChanged: (val) {
                                setState(() {});
                                bonosProvider.onSearchChanged(val);
                              },
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
                          Tooltip(
                            message: "Filtrar por estado",
                            child: DashboardDropdown<String>(
                              selectedValue: _filtroRapido,
                              tooltip: "Filtrar estado",
                              onSelected: (val) {
                                setState(() => _filtroRapido = val);
                              },
                              options: [
                                DropdownOption(
                                  value: 'TODOS',
                                  label: 'Todos los Bonos',
                                  icon: Icons.list,
                                  color: Colors.grey,
                                ),
                                DropdownOption(
                                  value: 'RIESGO',
                                  label: 'En Riesgo',
                                  icon: Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                DropdownOption(
                                  value: 'PENDIENTES',
                                  label: 'Pendientes de Pago',
                                  icon: Icons.credit_card_off_outlined,
                                  color: Colors.redAccent,
                                ),
                                DropdownOption(
                                  value: 'ACTIVOS',
                                  label: 'Activos',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                DropdownOption(
                                  value: 'AGOTADOS',
                                  label: 'Agotados',
                                  icon: Icons.done_all,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 12),

                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: "Vender un bono",
                            child: HoverableActionButton(
                              label: "Bono",
                              icon: Icons.add,
                              isPrimary: true,
                              onTap: () => _abrirVentaBono(context),
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
    );
  }

  // --- FILA DE DATOS ---
  Widget _buildRow(BuildContext context, BonoHistorico bono, int index) {
    final borderLeftColor = _getLeftAccentBorderColor(bono);

    // Cálculo del desgaste para LinearProgressIndicator
    final double ratio =
        bono.sesionesTotales > 0
            ? (bono.sesionesRestantes / bono.sesionesTotales).clamp(0.0, 1.0)
            : 0.0;

    Color progressColor;
    if (bono.sesionesTotales == 1) {
      progressColor =
          bono.sesionesRestantes == 1
              ? Colors.green.shade500
              : Colors.grey.shade400;
    } else if (bono.sesionesRestantes <= 2) {
      progressColor = Colors.red.shade500;
    } else if (ratio <= 0.5) {
      progressColor = Colors.orange.shade500;
    } else {
      progressColor = Colors.green.shade500;
    }

    final bool sinCitaFutura =
        bono.sesionesRestantes > 0 && !bono.tieneProximaCita;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => BonoDetalleModal.show(context, bono: bono),
        hoverColor: Colors.blue.shade50.withValues(alpha: 0.25),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: borderLeftColor,
                width: 4.0, // Regla estricta: Left Accent Border 4px
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 1. ID (Flex 1 - centerLeft)
              Expanded(
                flex: _columnFlexes[0],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '#${bono.idBonoActivo}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // 2. Fecha Compra (Flex 2 - centerLeft)
              Expanded(
                flex: _columnFlexes[1],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(bono.fechaCompra),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (bono.fechaCaducidad != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Caduca: ${DateFormat('dd/MM/yyyy').format(bono.fechaCaducidad!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                bono.caducado
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                            fontWeight:
                                bono.caducado
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Paciente (Flex 3 - centerLeft) - REGLA DE ORO: Flexible (prohibido Expanded)
              Expanded(
                flex: _columnFlexes[2],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: "Ver detalles de ${bono.nombreCliente}",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => context.push('/pacientes/${bono.idCliente}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(
                              nombreCompleto: bono.nombreCliente,
                              id: bono.idCliente,
                              radius: 16,
                              fontSize: 13,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                bono.nombreCliente,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Tipo de Bono (Flex 2 - centerLeft)
              Expanded(
                flex: _columnFlexes[3],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          bono.nombreServicio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Saldo de Sesiones (Flex 2 - centerLeft)
              Expanded(
                flex: _columnFlexes[4],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${bono.sesionesRestantes} / ${bono.sesionesTotales} disponibles',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (sinCitaFutura) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Sin próxima cita agendada',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade600,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 130,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Estado / Pago (Flex 1 - centerLeft)
              Expanded(
                flex: _columnFlexes[5],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(bono),
                ),
              ),

              // 7. Acciones (Flex 1 - centerRight)
              Expanded(
                flex: _columnFlexes[6],
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Si el paciente está en riesgo, icono destacado para ir a agendarle cita
                      if (sinCitaFutura)
                        Tooltip(
                          message: 'Agendar cita',
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(5),
                              constraints: const BoxConstraints(),
                              onPressed: () => _agendarCita(bono),
                            ),
                          ),
                        ),

                      // Botón para ver historial de consumos
                      Tooltip(
                        message: 'Ver Historial de Consumos',
                        child: IconButton(
                          icon: Icon(
                            Icons.visibility_outlined,
                            color: Colors.grey.shade700,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(5),
                          constraints: const BoxConstraints(),
                          onPressed: () => BonoDetalleModal.show(context, bono: bono),
                          hoverColor: Colors.blue.shade50,
                          splashRadius: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BADGE DE ESTADO COMPACTO ---
  Widget _buildStatusBadge(BonoHistorico bono) {
    String text;
    Color bg;
    Color fg;
    Color border;

    if (!bono.pagado) {
      text = 'PENDIENTE PAGO';
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      border = Colors.orange.shade300;
    } else if (bono.caducado) {
      text = 'CADUCADO';
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      border = Colors.red.shade200;
    } else if (bono.sesionesTotales == 1) {
      if (bono.sesionesRestantes == 1) {
        text = 'DISPONIBLE';
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        border = Colors.green.shade200;
      } else {
        text = 'AGOTADO';
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        border = Colors.grey.shade300;
      }
    } else if (bono.sesionesRestantes == 0) {
      text = 'AGOTADO';
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      border = Colors.grey.shade300;
    } else if (bono.sesionesRestantes <= 2) {
      text = 'POR AGOTAR';
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      border = Colors.amber.shade300;
    } else {
      text = 'ACTIVO';
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      border = Colors.green.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// --- DIÁLOGO RÁPIDO PARA SELECCIONAR CLIENTE AL VENDER BONO ---
class _SeleccionarClienteDialog extends StatefulWidget {
  const _SeleccionarClienteDialog();

  @override
  State<_SeleccionarClienteDialog> createState() =>
      _SeleccionarClienteDialogState();
}

class _SeleccionarClienteDialogState extends State<_SeleccionarClienteDialog> {
  final TextEditingController _filtroCtrl = TextEditingController();
  List<Cliente> _sugerencias = [];
  bool _buscando = false;

  @override
  void dispose() {
    _filtroCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _sugerencias = []);
      return;
    }
    setState(() => _buscando = true);
    final resultados = await Provider.of<ClientsProvider>(
      context,
      listen: false,
    ).searchClientesByName(query);

    if (mounted) {
      setState(() {
        _sugerencias = resultados;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Seleccionar Paciente para Bono',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _filtroCtrl,
              autofocus: true,
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: 'Escribe el nombre o teléfono del paciente...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (_buscando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_sugerencias.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sugerencias.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = _sugerencias[index];
                    return ListTile(
                      leading: AvatarWidget(
                        nombreCompleto: '${c.nombre} ${c.apellidos}',
                        id: c.idCliente,
                        radius: 18,
                        fontSize: 14,
                      ),
                      title: Text(
                        '${c.nombre} ${c.apellidos}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        c.telefono.isNotEmpty ? c.telefono : 'Sin teléfono',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              )
            else if (_filtroCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No se encontraron pacientes',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Introduce al menos una letra para buscar.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
