import 'package:flutter/material.dart';
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
  final notasCtrl = TextEditingController();
  String _estadoSeleccionado = 'programada';
  
  Cliente? selectedCliente;
  Usuario? selectedQuiro;

  late DateTime fechaInicio;
  late DateTime fechaFin;

  bool get isEditing => widget.citaExistente != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final c = widget.citaExistente!;
      fechaInicio = c.fechaHoraInicio;
      fechaFin = c.fechaHoraFin;
      notasCtrl.text = c.notas ?? '';
      _estadoSeleccionado = widget.citaExistente!.estado;
    } else {
      fechaInicio = widget.selectedDate ?? DateTime.now();
      fechaFin = fechaInicio.add(const Duration(minutes: 30));
      _estadoSeleccionado = 'programada';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientsProv = Provider.of<ClientsProvider>(context, listen: false);
      final agendaProv = Provider.of<AgendaProvider>(context, listen: false);
      
      if (clientsProv.clients.isEmpty) await clientsProv.getPaginatedClients(page: 0);
      if (agendaProv.quiropracticos.isEmpty) await agendaProv.loadQuiropracticos();

      if (isEditing && mounted) {
        setState(() {
          try {
            selectedCliente = clientsProv.clients.firstWhere(
              (c) => c.idCliente == widget.citaExistente!.idCliente
            );
          } catch (_) {} 

          try {
            selectedQuiro = agendaProv.quiropracticos.firstWhere(
              (u) => u.idUsuario == widget.citaExistente!.idQuiropractico
            );
          } catch (_) {}
        });
      }
    });
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colorTema, width: 2)
      ),
      title: Text(
          isEditing 
            ? 'Editar Cita (${_estadoSeleccionado.toUpperCase()})' // Muestra el estado actual
            : 'Nueva Cita', 
          style: TextStyle(color: colorTema, fontWeight: FontWeight.bold)
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      "${fechaInicio.hour}:${fechaInicio.minute.toString().padLeft(2,'0')} - ${fechaFin.hour}:${fechaFin.minute.toString().padLeft(2,'0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<Cliente>(
                decoration: const InputDecoration(labelText: 'Paciente', prefixIcon: Icon(Icons.person)),
                value: selectedCliente,
                items: clientsProvider.clients.map((c) => DropdownMenuItem(value: c, child: Text("${c.nombre} ${c.apellidos}"))).toList(),
                onChanged: (val) => setState(() => selectedCliente = val),
                validator: (val) => val == null ? 'Selecciona un paciente' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<Usuario>(
                decoration: const InputDecoration(labelText: 'Doctor', prefixIcon: Icon(Icons.medical_services_outlined)),
                value: selectedQuiro,
                items: agendaProvider.quiropracticos.map((u) => DropdownMenuItem(value: u, child: Text(u.nombreCompleto))).toList(),
                onChanged: (val) => setState(() => selectedQuiro = val),
                validator: (val) => val == null ? 'Selecciona un doctor' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: notasCtrl,
                decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.note_alt_outlined)),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      
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
                onPressed: () {
                   setState(() => _estadoSeleccionado = 'cancelada');
                },
              ),
              IconButton(
                tooltip: 'Marcar Ausente',
                icon: Icon(
                    _estadoSeleccionado == 'ausente' ? Icons.person_off : Icons.person_off_outlined, 
                    color: _estadoSeleccionado == 'ausente' ? Colors.black87 : Colors.grey
                ),
                onPressed: () {
                   setState(() => _estadoSeleccionado = 'ausente');
                },
              ),
              IconButton(
                tooltip: 'Marcar Completada',
                icon: Icon(
                    _estadoSeleccionado == 'completada' ? Icons.check_circle : Icons.check_circle_outline, 
                    color: _estadoSeleccionado == 'completada' ? Colors.green : Colors.grey
                ),
                onPressed: () {
                   setState(() => _estadoSeleccionado = 'completada');
                },
              ),
              if (_estadoSeleccionado != 'programada')
                IconButton(
                  tooltip: 'Restaurar a Programada',
                  icon: const Icon(Icons.undo, color: Colors.blue),
                  onPressed: () {
                     setState(() => _estadoSeleccionado = 'programada');
                  },
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
                  
                  String? error;
                  
                  if (isEditing) {
                    error = await agendaProvider.editarCita(
                      widget.citaExistente!.idCita,
                      selectedCliente!.idCliente,
                      selectedQuiro!.idUsuario,
                      fechaInicio,
                      fechaFin,
                      notasCtrl.text,
                      _estadoSeleccionado
                    );
                  } else {
                    error = await agendaProvider.crearCita(
                      selectedCliente!.idCliente,
                      selectedQuiro!.idUsuario,
                      fechaInicio,
                      fechaFin,
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
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