import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';

class CitaModal extends StatefulWidget {
  final DateTime? selectedDate;
  final Cita? citaExistente;

  const CitaModal({super.key, this.selectedDate, this.citaExistente});

  @override
  State<CitaModal> createState() => _CitaModalState();
}

class _CitaModalState extends State<CitaModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final notasCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();

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
      final baseDate = widget.selectedDate ?? DateTime.now();
      fechaSeleccionada = baseDate;
    }

    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);

    // CARGAR DATOS ASÍNCRONOS (Listas y Huecos)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientsProv = Provider.of<ClientsProvider>(context, listen: false);
      final agendaProv = Provider.of<AgendaProvider>(context, listen: false);

      // Cargar listas si están vacías
      if (clientsProv.clients.isEmpty) await clientsProv.getPaginatedClients(page: 0);
      if (agendaProv.quiropracticos.isEmpty) await agendaProv.loadQuiropracticos();

      // Determinar Doctor Inicial
      Usuario? doctorInicial;
      if (isEditing) {
        try {
          doctorInicial = agendaProv.quiropracticos.firstWhere((u) => u.idUsuario == widget.citaExistente!.idQuiropractico);
        } catch (_) {}
      } else {
        if (agendaProv.quiropracticos.isNotEmpty) doctorInicial = agendaProv.quiropracticos.first;
      }

      // Cargar Huecos Disponibles
      if (doctorInicial != null) {
        await agendaProv.cargarHuecos(
          doctorInicial.idUsuario,
          fechaSeleccionada,
          idCitaExcluir: isEditing ? widget.citaExistente!.idCita : null 
        );

        if (mounted) {          
          final targetTime = isEditing 
              ? widget.citaExistente!.fechaHoraInicio
              : widget.selectedDate!;
          final targetTimeStr = "${targetTime.hour.toString().padLeft(2,'0')}:${targetTime.minute.toString().padLeft(2,'0')}";
          
          try {
            final huecoEncontrado = agendaProv.huecosDisponibles.firstWhere(
              (h) => h['horaInicio'] == targetTimeStr
            );
            
            setState(() {
              selectedHueco = huecoEncontrado;
              _actualizarHorasDesdeHueco(huecoEncontrado);
            });
          } catch (e) {
            print("No se pudo pre-seleccionar el hueco: $targetTimeStr");
          }
        }
      }

      // Actualizar estado visual de los dropdowns de Cliente y Doctor
      if (mounted) {
        setState(() {
          selectedQuiro = doctorInicial;
          if (isEditing) {
            try {
              selectedCliente = clientsProv.clients.firstWhere((c) => c.idCliente == widget.citaExistente!.idCliente);
            } catch (_) {}
          }
        });
      }
    });
  }


  void _actualizarHorasDesdeHueco(Map<String, String> hueco) {
    final partsInicio = hueco['horaInicio']!.split(':');
    final partsFin = hueco['horaFin']!.split(':');
    horaInicio = TimeOfDay(hour: int.parse(partsInicio[0]), minute: int.parse(partsInicio[1]));
    horaFin = TimeOfDay(hour: int.parse(partsFin[0]), minute: int.parse(partsFin[1]));
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
      case 'completada': colorTema = Colors.green; break;
      case 'cancelada': colorTema = Colors.red; break;
      case 'ausente': colorTema = Colors.grey; break;
      default: colorTema = AppTheme.primaryColor;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: colorTema, width: 2)
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditing ? 'Editar Cita' : 'Nueva Cita',
            style: TextStyle(color: colorTema, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(width: 10),

          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorTema.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorTema)
              ),
              child: Text(
                _estadoSeleccionado.toUpperCase(),
                style: TextStyle(
                  color: colorTema, 
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5
                ),
              ),
            ),
        ],
      ),
      
      content: SizedBox(
        width: AppTheme.dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // FECHA
                TextFormField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fecha', prefixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('es', 'ES'),
                      selectableDayPredicate: (DateTime date) {
                        return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
                      },
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
                          idCitaExcluir: isEditing ? widget.citaExistente!.idCita : null
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 15),

                // DROPDOWN DE Horarios
                DropdownButtonFormField<Map<String, String>>(
                  decoration: const InputDecoration(
                    labelText: 'Horario Disponible',
                    prefixIcon: Icon(Icons.watch_later_outlined),
                  ),
                  value: selectedHueco,
                  items: agendaProvider.huecosDisponibles.map((hueco) {
                    return DropdownMenuItem(
                      value: hueco,
                      child: Text(hueco['texto']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedHueco = val;
                      if (val != null) _actualizarHorasDesdeHueco(val);
                    });
                  },
                  hint: agendaProvider.huecosDisponibles.isEmpty 
                      ? const Text("No hay huecos o cargando...", style: TextStyle(color: Colors.grey)) 
                      : const Text("Selecciona hora"),
                  validator: (val) => val == null ? 'Selecciona un horario' : null,
                ),
                
                const SizedBox(height: 15),

                // DOCTOR
                DropdownButtonFormField<Usuario>(
                  decoration: const InputDecoration(labelText: 'Doctor', prefixIcon: Icon(Icons.medical_services_outlined)),
                  value: selectedQuiro,
                  items: agendaProvider.quiropracticos.map((u) => DropdownMenuItem(value: u, child: Text(u.nombreCompleto))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedQuiro = val;
                      selectedHueco = null;
                    });
                    if (val != null) {
                      agendaProvider.cargarHuecos(
                        val.idUsuario, 
                        fechaSeleccionada,
                        idCitaExcluir: isEditing ? widget.citaExistente!.idCita : null
                      );
                    }
                  },
                  validator: (val) => val == null ? 'Selecciona un doctor' : null,
                ),
                const SizedBox(height: 15),

                // PACIENTE
                DropdownButtonFormField<Cliente>(
                  decoration: const InputDecoration(labelText: 'Paciente', prefixIcon: Icon(Icons.person)),
                  value: selectedCliente,
                  items: clientsProvider.clients.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} ${c.apellidos}"))).toList(),
                  onChanged: (val) => setState(() => selectedCliente = val),
                  validator: (val) => val == null ? 'Selecciona un paciente' : null,
                ),
                const SizedBox(height: 15),

                // NOTAS
                TextFormField(
                  controller: notasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.note_alt_outlined)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      
      // BOTONES DE ACCIÓN
      actionsPadding: const EdgeInsets.all(16),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      
      actions: [
        if (isEditing) 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Marcar para Cancelar',
                icon: Icon(
                    _estadoSeleccionado == 'cancelada' ? Icons.cancel : Icons.cancel_outlined, 
                    color: _estadoSeleccionado == 'cancelada' ? Colors.red : Colors.grey
                ),
                onPressed: () => setState(() => _estadoSeleccionado = 'cancelada'),
              ),
              IconButton(
                tooltip: 'Marcar Ausente',
                icon: Icon(
                    _estadoSeleccionado == 'ausente' ? Icons.person_off : Icons.person_off_outlined, 
                    color: _estadoSeleccionado == 'ausente' ? Colors.black87 : Colors.grey
                ),
                onPressed: () => setState(() => _estadoSeleccionado = 'ausente'),
              ),
              IconButton(
                tooltip: 'Marcar Completada',
                icon: Icon(
                    _estadoSeleccionado == 'completada' ? Icons.check_circle : Icons.check_circle_outline, 
                    color: _estadoSeleccionado == 'completada' ? Colors.green : Colors.grey
                ),
                onPressed: () => setState(() => _estadoSeleccionado = 'completada'),
              ),
              if (_estadoSeleccionado != 'programada')
                IconButton(
                  tooltip: 'Restaurar a Programada',
                  icon: const Icon(Icons.undo, color: Colors.blue),
                  onPressed: () => setState(() => _estadoSeleccionado = 'programada'),
                ),
            ],
          )
        else 
          const SizedBox(),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cerrar')
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final inicioFinal = _joinDateTime(fechaSeleccionada, horaInicio);
                  final finFinal = _joinDateTime(fechaSeleccionada, horaFin);

                  String? error;
                  if (isEditing) {
                    error = await agendaProvider.editarCita(
                      widget.citaExistente!.idCita,
                      selectedCliente!.idCliente,
                      selectedQuiro!.idUsuario,
                      inicioFinal,
                      finFinal,
                      notasCtrl.text,
                      _estadoSeleccionado
                    );
                  } else {
                    error = await agendaProvider.crearCita(
                      selectedCliente!.idCliente,
                      selectedQuiro!.idUsuario,
                      inicioFinal,
                      finFinal,
                      notasCtrl.text
                    );
                  }

                  if (context.mounted) {
                    if (error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Cita actualizada' : 'Cita creada'), backgroundColor: Colors.green)
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red)
                      );
                    }
                  }
                }
              }, 
              child: Text(isEditing ? 'Guardar Cambios' : 'Agendar')
            ),
          ],
        ),
      ],
    );
  }
}