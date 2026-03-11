import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/ui/modals/payment_selection_modal.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';
import 'package:quiropractico_front/ui/widgets/fecha_picker_dialog.dart';
import 'package:quiropractico_front/ui/widgets/horario_picker_dialog.dart';

class CitaModal extends StatefulWidget {
  final DateTime? selectedDate;
  final Cita? citaExistente;
  final Usuario? preSelectedDoctor;
  final Cliente? preSelectedClient;

  const CitaModal({
    super.key,
    this.selectedDate,
    this.citaExistente,
    this.preSelectedDoctor,
    this.preSelectedClient,
  });

  @override
  State<CitaModal> createState() => _CitaModalState();
}

class _CitaModalState extends State<CitaModal> {
  final _formKey = GlobalKey<FormState>();

  final notasCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final _clientSearchController = TextEditingController();
  final _clientFocusNode = FocusNode();
  bool _isLoading = false;

  // Selecciones
  Cliente? selectedCliente;
  Usuario? selectedQuiro;
  Map<String, String>? selectedHueco;
  late DateTime fechaSeleccionada;
  late TimeOfDay horaInicio;
  late TimeOfDay horaFin;

  String _estadoSeleccionado = 'programada';
  bool get isEditing => widget.citaExistente != null;

  @override
  void initState() {
    super.initState();

    // INICIALIZAR VARIABLES BÁSICAS
    if (isEditing) {
      final c = widget.citaExistente!;
      _estadoSeleccionado = c.estado;
      notasCtrl.text = c.notas ?? '';
      fechaSeleccionada = c.fechaHoraInicio;
    } else {
      var baseDate = widget.selectedDate ?? DateTime.now();

      // Ajustar si la fecha base cae en fin de semana (Sábado/Domingo)
      // para evitar error de aserción en showDatePicker (selectableDayPredicate)
      while (baseDate.weekday == DateTime.saturday ||
          baseDate.weekday == DateTime.sunday) {
        baseDate = baseDate.add(const Duration(days: 1));
      }

      fechaSeleccionada = baseDate;
    }

    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);

    // CARGAR DATOS ASÍNCRONOS (Listas y Huecos)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientsProv = Provider.of<ClientsProvider>(context, listen: false);
      final agendaProv = Provider.of<AgendaProvider>(context, listen: false);

      // Cargar listas si están vacías
      if (clientsProv.clients.isEmpty)
        await clientsProv.getPaginatedClients(page: 0);
      if (agendaProv.quiropracticos.isEmpty)
        await agendaProv.loadQuiropracticos();

      // Determinar Doctor Inicial
      Usuario? doctorInicial;
      if (isEditing) {
        try {
          doctorInicial = agendaProv.quiropracticos.firstWhere(
            (u) => u.idUsuario == widget.citaExistente!.idQuiropractico,
          );
        } catch (_) {}
      } else {
        if (widget.preSelectedDoctor != null) {
          doctorInicial = widget.preSelectedDoctor;
        } else if (agendaProv.quiropracticos.isNotEmpty) {
          doctorInicial = agendaProv.quiropracticos.first;
        }
      }

      // Pre-seleccionar Cliente
      if (widget.preSelectedClient != null && !isEditing) {
        // Si no estamos editando (cita nueva) y viene un cliente preseleccionado
        if (mounted) {
          setState(() {
            selectedCliente = widget.preSelectedClient;
            _clientSearchController.text =
                "${selectedCliente!.nombre} ${selectedCliente!.apellidos} (${selectedCliente!.telefono})";
          });
        }
      }

      // Cargar Huecos Disponibles
      if (doctorInicial != null) {
        await agendaProv.cargarHuecos(
          doctorInicial.idUsuario,
          fechaSeleccionada,
          idCitaExcluir: isEditing ? widget.citaExistente!.idCita : null,
        );
      }
      Cliente? clienteEncontrado;
      if (isEditing) {
        final idClienteDeLaCita = widget.citaExistente!.idCliente;
        clienteEncontrado = await clientsProv.getClientePorId(
          idClienteDeLaCita,
        );
      }

      if (mounted) {
        setState(() {
          selectedQuiro = doctorInicial;

          if (isEditing && clienteEncontrado != null) {
            selectedCliente = clienteEncontrado;
            _clientSearchController.text =
                "${clienteEncontrado.nombre} ${clienteEncontrado.apellidos} (${clienteEncontrado.telefono})";
          }

          if (doctorInicial != null) {
            final targetTime =
                isEditing
                    ? widget.citaExistente!.fechaHoraInicio
                    : fechaSeleccionada;
            final targetTimeStr =
                "${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}";

            try {
              final huecoEncontrado = agendaProv.huecosDisponibles.firstWhere(
                (h) => h['horaInicio'] == targetTimeStr,
              );
              selectedHueco = huecoEncontrado;
              _actualizarHorasDesdeHueco(huecoEncontrado);
            } catch (e) {
              print("No se pudo pre-seleccionar el hueco: $targetTimeStr");
            }
          }
        });
      }
    });
  }

  void _actualizarHorasDesdeHueco(Map<String, String> hueco) {
    final partsInicio = hueco['horaInicio']!.split(':');
    final partsFin = hueco['horaFin']!.split(':');
    horaInicio = TimeOfDay(
      hour: int.parse(partsInicio[0]),
      minute: int.parse(partsInicio[1]),
    );
    horaFin = TimeOfDay(
      hour: int.parse(partsFin[0]),
      minute: int.parse(partsFin[1]),
    );
  }

  DateTime _joinDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    final clientsProvider = Provider.of<ClientsProvider>(context);

    Color colorTema;
    switch (_estadoSeleccionado) {
      case 'completada':
        colorTema = Colors.green;
        break;
      case 'cancelada':
        colorTema = Colors.red;
        break;
      case 'ausente':
        colorTema = Colors.grey;
        break;
      default:
        colorTema = AppTheme.primaryColor;
    }

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 520, maxWidth: 520),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de acento izquierda
              Container(
                width: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorTema, colorTema.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Contenido principal
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // CABECERA
                        _buildHeader(colorTema),

                        SizedBox(height: 15),
                        // SECCIÓN: FECHA Y HORARIO
                        _buildDateAndTimeSelector(
                          context,
                          colorTema,
                          agendaProvider,
                        ),
                        SizedBox(height: 10),
                        // SECCIÓN: PROFESIONAL
                        _buildProfessionalSelector(agendaProvider),
                        SizedBox(height: 10),
                        // SECCIÓN: PACIENTE
                        _buildClientSelector(clientsProvider),
                        SizedBox(height: 5),
                        // Notas
                        _buildNotas(),

                        // RESUMEN PREVIO
                        _buildResumenPrevio(colorTema),

                        // ── ACCIONES ───────────────────────────
                        _buildFooterActions(context, colorTema, agendaProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color colorTema) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
      decoration: BoxDecoration(
        color: colorTema.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Cita' : 'Nueva Cita',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat(
                    "EEEE, d 'de' MMMM · yyyy",
                    'es',
                  ).format(fechaSeleccionada),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorTema.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorTema.withOpacity(0.4)),
            ),
            child: Text(
              _estadoSeleccionado.toUpperCase(),
              style: TextStyle(
                color: colorTema,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndTimeSelector(
    BuildContext context,
    Color colorTema,
    AgendaProvider agendaProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fecha (50%) ──
          Expanded(
            child: TextFormField(
              controller: fechaCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onTap: () async {
                final horariosProvider = Provider.of<HorariosProvider>(
                  context,
                  listen: false,
                );
                final bloqueoProvider = Provider.of<AgendaBloqueoProvider>(
                  context,
                  listen: false,
                );
                final picked = await showDialog<DateTime>(
                  context: context,
                  builder:
                      (ctx) => FechaPickerDialog(
                        initialDate: fechaSeleccionada,
                        colorTema: AppTheme.primaryColor,
                        diasActivosSemana: horariosProvider.diasActivosSemana,
                        bloqueos: bloqueoProvider.bloqueos,
                        idQuiroSeleccionado: selectedQuiro?.idUsuario,
                      ),
                );
                if (picked != null) {
                  setState(() {
                    fechaSeleccionada = picked;
                    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                    selectedHueco = null;
                  });
                  if (selectedQuiro != null) {
                    agendaProvider.cargarHuecos(
                      selectedQuiro!.idUsuario,
                      picked,
                      idCitaExcluir:
                          isEditing ? widget.citaExistente!.idCita : null,
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // ── Horario (50%) ──
          Expanded(
            child: FormField<Map<String, String>>(
              initialValue: selectedHueco,
              validator:
                  (_) => selectedHueco == null ? 'Selecciona un horario' : null,
              builder: (fieldState) {
                final String textToShow;
                if (selectedHueco != null) {
                  textToShow = selectedHueco!['texto']!;
                } else if (agendaProvider.isLoadingHuecos) {
                  textToShow = 'Cargando...';
                } else if (selectedQuiro != null && agendaProvider.huecosDisponibles.isEmpty) {
                  textToShow = 'No disponible';
                } else {
                  textToShow = '';
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final huecos = agendaProvider.huecosDisponibles;
                    if (huecos.isEmpty) return;
                    final result = await showDialog<Map<String, String>>(
                      context: context,
                      builder:
                          (ctx) => HorarioPickerDialog(
                            huecos: huecos,
                            selected: selectedHueco,
                          ),
                    );
                    if (result != null) {
                      setState(() {
                        selectedHueco = result;
                        _actualizarHorasDesdeHueco(result);
                      });
                      fieldState.didChange(result);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(
                        Icons.watch_later_outlined,
                        color: fieldState.hasError ? Colors.red : null,
                      ),
                      suffixIcon:
                          agendaProvider.isLoadingHuecos
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : const Icon(Icons.expand_more),
                      errorText:
                          fieldState.hasError ? fieldState.errorText : null,
                      border: const OutlineInputBorder(),
                    ),
                    isEmpty: textToShow.isEmpty,
                    child: Text(
                      textToShow,
                      style: TextStyle(
                        color: selectedHueco != null ? null : Colors.grey[500],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSelector(AgendaProvider agendaProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: DropdownButtonFormField<Usuario>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Doctor seleccionado',
          prefixIcon: Icon(Icons.medical_services_outlined),
        ),
        value: selectedQuiro,
        dropdownColor: Colors.white,
        menuMaxHeight: 300,
        items: agendaProvider.quiropracticos.map((u) {
          final initials = u.nombreCompleto.isNotEmpty
              ? u.nombreCompleto.substring(0, 1).toUpperCase()
              : 'D';
          return DropdownMenuItem(
            value: u,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  u.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            selectedQuiro = val;
            selectedHueco = null;
            if (val != null) {
              agendaProvider.cargarHuecos(
                val.idUsuario,
                fechaSeleccionada,
                idCitaExcluir: isEditing ? widget.citaExistente!.idCita : null,
              );
            }
          });
        },
        validator: (val) => val == null ? 'Selecciona un doctor' : null,
      ),
    );
  }

  Widget _buildClientSelector(ClientsProvider clientsProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: RawAutocomplete<Cliente>(
        textEditingController: _clientSearchController,
        focusNode: _clientFocusNode,
        displayStringForOption:
            (Cliente option) =>
                "${option.nombre} ${option.apellidos} (${option.telefono})",
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty)
            return const Iterable<Cliente>.empty();
          return await clientsProvider.searchClientesByName(
            textEditingValue.text,
          );
        },
        onSelected:
            (Cliente selection) => setState(() {
              selectedCliente = selection;
            }),
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Paciente (Nombre o Teléfono)',
              prefixIcon: const Icon(Icons.person_search_outlined),
              suffixIcon:
                  selectedCliente != null
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            selectedCliente = null;
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (text) {
              if (selectedCliente != null) {
                setState(() {
                  selectedCliente = null;
                });
              }
            },
            validator:
                (value) =>
                    selectedCliente == null
                        ? 'Busca y selecciona un paciente'
                        : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 420,
                constraints: const BoxConstraints(maxHeight: 200),
                color: Colors.white,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Cliente option = options.elementAt(index);
                    return ListTile(
                      leading: AvatarWidget(
                        nombreCompleto: option.nombre,
                        id: option.idCliente,
                        radius: 15,
                        fontSize: 14,
                      ),
                      title: Text("${option.nombre} ${option.apellidos}"),
                      subtitle: Text(option.telefono),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: TextFormField(
        controller: notasCtrl,
        decoration: const InputDecoration(
          labelText: 'Notas (opcional)',
          prefixIcon: Icon(Icons.note_alt_outlined),
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildResumenPrevio(Color colorTema) {
    if (selectedCliente != null &&
        selectedHueco != null &&
        selectedQuiro != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorTema.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorTema.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colorTema),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${selectedCliente!.nombre} ${selectedCliente!.apellidos} · ${selectedHueco!['texto']} · ${selectedQuiro!.nombreCompleto.split(' ').first}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorTema,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFooterActions(
    BuildContext context,
    Color colorTema,
    AgendaProvider agendaProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        children: [
          // Botón Cancelar
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Cancelar'),
          ),

          // Iconos de estado (solo en modo edición)
          if (isEditing) ...[
            const SizedBox(width: 8),
            _buildEstadoIconButton(
              'cancelada',
              Icons.cancel_outlined,
              Icons.cancel,
              Colors.red,
            ),
            _buildEstadoIconButton(
              'ausente',
              Icons.person_off_outlined,
              Icons.person_off,
              Colors.orange,
            ),
            _buildEstadoIconButton(
              'programada',
              Icons.event_outlined,
              Icons.event,
              AppTheme.primaryColor,
            ),
            _buildEstadoIconButton(
              'completada',
              Icons.check_circle_outline,
              Icons.check_circle,
              Colors.green,
            ),
          ],

          const Spacer(),

          // Botón Guardar (tamaño fijo)
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            final inicioFinal = _joinDateTime(
                              fechaSeleccionada,
                              horaInicio,
                            );
                            final finFinal = _joinDateTime(
                              fechaSeleccionada,
                              horaFin,
                            );
                            int? idBonoElegido;

                            if (!isEditing) {
                              final resultado = await showDialog(
                                context: context,
                                builder:
                                    (_) => PaymentSelectionModal(
                                      cliente: selectedCliente!,
                                    ),
                              );
                              if (resultado == null) {
                                if (mounted)
                                  setState(() {
                                    _isLoading = false;
                                  });
                                return;
                              }
                              if (resultado is int) idBonoElegido = resultado;
                            }

                            String? error;
                            if (isEditing) {
                              error = await agendaProvider.editarCita(
                                widget.citaExistente!.idCita,
                                selectedCliente!.idCliente,
                                selectedQuiro!.idUsuario,
                                inicioFinal,
                                finFinal,
                                notasCtrl.text,
                                _estadoSeleccionado,
                              );
                            } else {
                              error = await agendaProvider.crearCita(
                                selectedCliente!.idCliente,
                                selectedQuiro!.idUsuario,
                                inicioFinal,
                                finFinal,
                                notasCtrl.text,
                                idBonoAUtilizar: idBonoElegido,
                              );
                            }

                            if (!context.mounted) return;
                            if (error == null) {
                              if (mounted)
                                setState(() {
                                  _isLoading = false;
                                });
                              Navigator.pop(context, true);
                              CustomSnackBar.show(
                                context,
                                message:
                                    isEditing
                                        ? 'Cita actualizada'
                                        : 'Cita creada',
                                type: SnackBarType.success,
                              );
                            } else {
                              if (mounted)
                                setState(() {
                                  _isLoading = false;
                                });
                              if (error.toLowerCase().contains(
                                    "no tiene bonos",
                                  ) ||
                                  error.toLowerCase().contains("saldo")) {
                                final quiereComprar = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 30,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(20),
                                                    ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .account_balance_wallet_outlined,
                                                    size: 60,
                                                    color:
                                                        Colors.orange.shade800,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    "Saldo Insuficiente",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors
                                                              .orange
                                                              .shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(25),
                                              child: Text(
                                                "El paciente no dispone de sesiones activas.\n\n¿Quieres realizar una venta ahora mismo?",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[700],
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actionsPadding:
                                            const EdgeInsets.fromLTRB(
                                              20,
                                              0,
                                              20,
                                              20,
                                            ),
                                        actionsAlignment:
                                            MainAxisAlignment.center,
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, false),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey,
                                            ),
                                            child: const Text("No, cancelar"),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed:
                                                () => Navigator.pop(ctx, true),
                                            icon: const Icon(
                                              Icons.shopping_cart,
                                            ),
                                            label: const Text("Vender Bono"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 25,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (quiereComprar == true && context.mounted) {
                                  final ventaExitosa = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => VentaBonoModal(
                                          cliente: selectedCliente!,
                                        ),
                                  );
                                  if (ventaExitosa == true && context.mounted) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    final reintentoError = await agendaProvider
                                        .crearCita(
                                          selectedCliente!.idCliente,
                                          selectedQuiro!.idUsuario,
                                          inicioFinal,
                                          finFinal,
                                          notasCtrl.text,
                                        );
                                    if (!context.mounted) return;
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    if (reintentoError == null) {
                                      Navigator.pop(context, true);
                                      CustomSnackBar.show(
                                        context,
                                        title: "Proceso completado",
                                        message:
                                            "Bono comprado y cita agendada correctamente.",
                                        type: SnackBarType.success,
                                        duration: const Duration(seconds: 5),
                                      );
                                    } else {
                                      CustomSnackBar.show(
                                        context,
                                        title: "Bono comprado",
                                        message:
                                            "El bono se compró, pero falló la cita: $reintentoError",
                                        type: SnackBarType.error,
                                      );
                                    }
                                  }
                                }
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  message: error,
                                  type: SnackBarType.error,
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted)
                              setState(() {
                                _isLoading = false;
                              });
                            CustomSnackBar.show(
                              context,
                              message: "Error inesperado: $e",
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        isEditing ? 'Guardar Cambios' : 'Agendar Cita',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIconButton(
    String estado,
    IconData iconOutlined,
    IconData iconFilled,
    Color color,
  ) {
    final isSelected = _estadoSeleccionado == estado;
    return Tooltip(
      message: estado[0].toUpperCase() + estado.substring(1),
      child: IconButton(
        onPressed: () => setState(() => _estadoSeleccionado = estado),
        icon: Icon(
          isSelected ? iconFilled : iconOutlined,
          color: isSelected ? color : Colors.grey.shade400,
          size: 24,
        ),
        style: IconButton.styleFrom(
          backgroundColor:
              isSelected ? color.withOpacity(0.1) : Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
