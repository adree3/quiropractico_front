import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/auditoria_log.dart';
import 'package:quiropractico_front/providers/auditoria_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/user_avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/dashboard_dropdown.dart';
import 'package:quiropractico_front/ui/widgets/custom_date_range_picker.dart';
import 'package:quiropractico_front/ui/widgets/paginated_table.dart';

class AuditoriaView extends StatefulWidget {
  const AuditoriaView({super.key});

  @override
  State<AuditoriaView> createState() => _AuditoriaViewState();
}

class _AuditoriaViewState extends State<AuditoriaView> {
  Timer? _debounce;
  final searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuditoriaProvider>(context, listen: false).getLogs(page: 0);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AuditoriaProvider>(context, listen: false).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuditoriaProvider>(context);
    final logs = provider.logs;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const SizedBox(height: 40, width: 10),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  'Registros',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 20),
                // Buscador
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por usuario, detalles...',
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
                                      provider.setSearch('');
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 20),

                Tooltip(
                  message: "Filtrar fecha",
                  child: _HoverableFilterButton(
                    isActive:
                        provider.fechaInicio != null ||
                        provider.fechaFin != null,
                    onTap: () async {
                      final pickedRange = await CustomDateRangePicker.show(
                        context,
                        initialStartDate: provider.fechaInicio,
                        initialEndDate: provider.fechaFin,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );

                      if (pickedRange != null) {
                        provider.setRangoFechas(
                          pickedRange.start,
                          pickedRange.end,
                        );
                      }
                    },
                    onClear: () => provider.setRangoFechas(null, null),
                    label:
                      (provider.fechaInicio != null && provider.fechaFin != null)
                        ? "${DateFormat('dd/MM', 'es_ES').format(provider.fechaInicio!)} - ${DateFormat('dd/MM', 'es_ES').format(provider.fechaFin!)}"
                        : "Fecha",
                    icon: Icons.calendar_today,
                  ),
                ),

                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 10),

                // Filtro acción
                _buildActionDropdown(provider),
                const SizedBox(width: 10),

                // Filtro entidad
                _buildPrettyDropdown(provider),

                const SizedBox(width: 10),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tabla + paginador
          Expanded(
            child: PaginatedTable(
              isLoading: provider.isLoading,
              isEmpty: logs.isEmpty,
              emptyMessage: "No hay registros de auditoría",
              totalElements: provider.totalElements,
              pageSize: provider.pageSize,
              dataRowHeight: 68.0,
              currentPage: provider.currentPage,
              onPageChanged: (p) => provider.getLogs(page: p),
              columns: const [
                DataColumn(
                  label: Text(
                    'Fecha',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Usuario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Acción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Entidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Resumen',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              rows: logs.map((log) => _buildDataRow(log, context)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown bonito
  Widget _buildPrettyDropdown(AuditoriaProvider provider) {
    final entidades = [
      "CITA",
      "SESION",
      "BONO",
      "PAGO",
      "HORARIO",
      "BLOQUEO_AGENDA",
      "CLIENTE",
      "USUARIO",
      "WHATSAPP",
      "HISTORIAL_CLINICO",
      "SERVICIO",
      "GRUPO_FAMILIAR",
    ];

    final options = <DropdownOption<String?>>[
      const DropdownOption(
        value: null,
        label: "Todos",
        icon: Icons.list,
        color: Colors.grey,
      ),
      ...entidades.map(
        (entidad) => DropdownOption(
          value: entidad,
          label: _formatEntityName(entidad),
          icon: _getIconForEntity(entidad),
          color: _getColorForEntity(entidad),
        ),
      ),
    ];

    return DashboardDropdown<String?>(
      selectedValue: provider.filtroEntidad,
      customLabel: provider.filtroEntidad == null ? "Todos" : null,
      onSelected: (val) => provider.setFiltroEntidad(val),
      options: options,
      tooltip: "Filtrar entidad",
    );
  }

  // Iconos para acciones
  IconData _getIconForAction(String accion) {
    switch (accion) {
      case 'CREAR':
        return Icons.add_circle_outline;
      case 'EDITAR':
        return Icons.edit;
      case 'ELIMINAR':
        return Icons.delete_outline;
      case 'LOGIN':
        return Icons.login;
      case 'UNLOCK':
        return Icons.lock_open;
      case 'BLOQUEADO':
        return Icons.lock_outline;
      case 'REACTIVAR':
        return Icons.restore_from_trash;
      case 'VENTA':
        return Icons.sell_outlined;
      case 'CONSUMO':
        return Icons.shopping_bag_outlined;
      case 'NOTIFICACION':
        return Icons.notifications_none;
      case 'ERROR':
        return Icons.error_outline;
      case 'DESHACER':
        return Icons.undo;
      default:
        return Icons.help_outline;
    }
  }

  // Colores para acciones
  Color _getColorForAction(String accion) {
    switch (accion) {
      case 'CREAR':
      case 'UNLOCK':
      case 'REACTIVAR':
      case 'VENTA':
        return Colors.green;
      case 'EDITAR':
      case 'LOGIN':
      case 'CONSUMO':
        return Colors.blue;
      case 'ELIMINAR':
      case 'BLOQUEADO':
      case 'ERROR':
        return Colors.red;
      case 'NOTIFICACION':
        return Colors.orange;
      case 'DESHACER':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  // Texto bonito para acciones
  String _formatActionName(String accion) {
    if (accion.isEmpty) return accion;
    if (accion == 'BLOQUEADO') return 'Lock';
    return accion[0] + accion.substring(1).toLowerCase();
  }

  Widget _buildActionDropdown(AuditoriaProvider provider) {
    final acciones = [
      "CREAR",
      "EDITAR",
      "ELIMINAR",
      "LOGIN",
      "UNLOCK",
      "BLOQUEADO",
      "REACTIVAR",
      "VENTA",
      "CONSUMO",
      "NOTIFICACION",
      "ERROR",
    ];

    final options = <DropdownOption<String?>>[
      const DropdownOption(
        value: null,
        label: "Acciones",
        icon: Icons.filter_alt_off,
        color: Colors.grey,
      ),
      ...acciones.map(
        (accion) => DropdownOption(
          value: accion,
          label: _formatActionName(accion),
          icon: _getIconForAction(accion),
          color: _getColorForAction(accion),
        ),
      ),
    ];

    return DashboardDropdown<String?>(
      selectedValue: provider.filtroAccion,
      customLabel: provider.filtroAccion == null ? "Acciones" : null,
      onSelected: (val) => provider.setFiltroAccion(val),
      options: options,
      tooltip: "Filtrar acción",
    );
  }

  // Cada fila de la tabla
  DataRow _buildDataRow(AuditoriaLog log, BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return DataRow(
      cells: [
        // ── Fecha + #ID ──────────────────────────────────────
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(log.fechaHora),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '#${log.idAuditoria}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),

        DataCell(
          Builder(
            builder: (ctx) {
              final usersProvider = Provider.of<UsersProvider>(ctx, listen: false);
              Usuario? responsable;
              try {
                if (log.idUsuarioResponsable != null) {
                  responsable = usersProvider.usuarios.firstWhere((u) => u.idUsuario == log.idUsuarioResponsable);
                }
              } catch (_) {}

              return Row(
                children: [
                  responsable != null 
                    ? UserAvatarWidget(usuario: responsable, radius: 14, fontSize: 12)
                    : CircleAvatar(
                        radius: 14,
                        backgroundColor: _getColorHash(log.usernameResponsable),
                        child: Text(
                          (log.usernameResponsable ?? "S").isNotEmpty ? (log.usernameResponsable ?? "S")[0].toUpperCase() : "S",
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                  const SizedBox(width: 8),
                  Text(
                    log.usernameResponsable ?? "Sistema",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              );
            }
          ),
        ),

        DataCell(_buildActionBadge(log.accion)),

        DataCell(
          Row(
            children: [
              Icon(
                _getIconForEntity(log.entidad),
                size: 18,
                color: _getColorForEntity(log.entidad),
              ),
              const SizedBox(width: 8),
              Text(
                _formatEntityName(log.entidad),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ── Resumen (legible) + Botones de acciones ─────────
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 350, maxWidth: 450),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Tooltip(
                    message: (log.resumen != null && log.resumen!.isNotEmpty)
                        ? log.resumen!
                        : (log.detalles ?? '-'),
                    child: Text(
                      (log.resumen != null && log.resumen!.isNotEmpty)
                          ? log.resumen!
                          : (log.detalles ?? '-'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Botón copiar RESUMEN
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.copy_all,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    tooltip: 'Copiar resumen',
                    onPressed: () {
                      final text = (log.resumen != null && log.resumen!.isNotEmpty)
                          ? log.resumen!
                          : (log.detalles ?? '-');
                      Clipboard.setData(ClipboardData(text: text));
                      CustomSnackBar.show(
                        context,
                        message: 'Resumen copiado',
                        type: SnackBarType.info,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 4),
                // Botón detalles técnicos (JSON)
                if (log.detalles != null && log.detalles!.isNotEmpty)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.data_object,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      tooltip: 'Ver JSON técnico',
                      onPressed: () => _showDetallesTecnicosDialog(context, log),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDetallesTecnicosDialog(BuildContext context, AuditoriaLog log) {
    String formattedContent;
    try {
      if (log.detalles == null || log.detalles!.isEmpty) {
        formattedContent = '-';
      } else {
        final decoded = jsonDecode(log.detalles!);
        formattedContent = const JsonEncoder.withIndent('  ').convert(decoded);
      }
    } on FormatException {
      // No es un JSON válido, mostrar texto plano sin parsear
      formattedContent = log.detalles ?? '-';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.data_object, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text('Detalles Técnicos'),
            const Spacer(),
            Text(
              '#${log.idAuditoria}',
              style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              formattedContent,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: formattedContent));
              Navigator.of(ctx).pop();
              CustomSnackBar.show(
                context,
                message: 'JSON copiado al portapapeles',
                type: SnackBarType.info,
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  // Helpers visuales
  String _formatEntityName(String entidad) {
    switch (entidad) {
      // TRADUCCIONES PERSONALIZADAS
      case 'CLIENTE':
        return 'Pacientes';
      case 'USUARIO':
        return 'Equipo';
      case 'BLOQUEO_AGENDA':
        return 'Vacaciones';
      case 'SESION':
        return 'Login';
      case 'SERVICIO':
        return 'Tarifas';
      case 'HISTORIAL_CLINICO':
        return 'Historial Médico';
      case 'GRUPO_FAMILIAR':
        return 'Familiares';
      case 'WHATSAPP':
        return 'WhatsApp';
      case 'DESHACER':
        return 'Deshacer';
      default:
        return entidad
          .replaceAll("_", " ")
          .toLowerCase()
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '',
          )
          .join(' ');
    }
  }

  IconData _getIconForEntity(String entidad) {
    switch (entidad) {
      case 'CITA':
        return Icons.calendar_month;
      case 'SESION':
        return Icons.vpn_key;
      case 'BONO':
        return Icons.card_membership;
      case 'HORARIO':
        return Icons.schedule;
      case 'BLOQUEO_AGENDA':
        return Icons.block;
      case 'PAGO':
        return Icons.euro;
      case 'USUARIO':
        return Icons.badge_outlined;
      case 'CLIENTE':
        return Icons.person_outline;
      case 'WHATSAPP':
        return Icons.chat_bubble_outline;
      case 'HISTORIAL_CLINICO':
        return Icons.medical_services_outlined;
      case 'SERVICIO':
        return Icons.price_change_outlined;
      case 'GRUPO_FAMILIAR':
        return Icons.diversity_3;
      case 'DESHACER':
        return Icons.undo;
      default:
        return Icons.extension_outlined;
    }
  }

  Color _getColorForEntity(String entidad) {
    switch (entidad) {
      case 'CITA':
        return Colors.blue;
      case 'SESION':
        return Colors.teal;
      case 'BONO':
        return Colors.orange;
      case 'HORARIO':
        return Colors.blueGrey;
      case 'BLOQUEO_AGENDA':
        return Colors.red;
      case 'PAGO':
        return Colors.green;
      case 'USUARIO':
        return Colors.deepPurple;
      case 'CLIENTE':
        return Colors.cyan;
      case 'WHATSAPP':
        return Colors.purple;
      case 'HISTORIAL_CLINICO':
        return Colors.indigo;
      case 'SERVICIO':
        return Colors.deepOrange;
      case 'GRUPO_FAMILIAR':
        return Colors.pinkAccent;
      case 'DESHACER':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionBadge(String accion) {
    Color color;
    switch (accion) {
      case 'CREAR':
      case 'VENTA':
      case 'REACTIVAR':
      case 'UNLOCK':
        color = Colors.green;
        break;
      case 'EDITAR':
      case 'LOGIN':
      case 'CONSUMO':
        color = Colors.blue;
        break;
      case 'ELIMINAR_FISICO':
      case 'ELIMINAR_LOGICO':
      case 'BLOQUEADO':
      case 'ERROR':
        color = Colors.red;
        break;
      case 'NOTIFICACION':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        (accion == 'ELIMINAR_LOGICO' || accion == 'ELIMINAR_FISICO')
            ? 'ELIMINAR'
            : (accion == 'BLOQUEADO' ? 'LOCK' : accion),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorHash(String? text) {
    if (text == null) return Colors.grey;
    return Colors.primaries[text.hashCode % Colors.primaries.length];
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
