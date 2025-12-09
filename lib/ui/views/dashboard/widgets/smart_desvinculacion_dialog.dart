import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/cita_conflicto.dart';

class SmartDesvinculacionDialog extends StatefulWidget {
  final String nombreFamiliar;
  final int idGrupo;
  final Future<List<CitaConflicto>> Function(int) fetchConflictos;

  const SmartDesvinculacionDialog({
    Key? key,
    required this.nombreFamiliar,
    required this.idGrupo,
    required this.fetchConflictos,
  }) : super(key: key);

  @override
  State<SmartDesvinculacionDialog> createState() => _SmartDesvinculacionDialogState();
}

class _SmartDesvinculacionDialogState extends State<SmartDesvinculacionDialog> {
  bool _loading = true;
  List<CitaConflicto> _conflictos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _consultarConflictos();
  }

  Future<void> _consultarConflictos() async {
    try {
      final datos = await widget.fetchConflictos(widget.idGrupo);
      if (mounted) {
        setState(() {
          _conflictos = datos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error de conexión: $e";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        content: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Analizando citas pendientes...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text("Error de Conexión", textAlign: TextAlign.center),
        content: Text(_error!, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
        ],
      );
    }

    if (_conflictos.isEmpty) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 30, left: 20, right: 20),
        contentPadding: const EdgeInsets.all(20),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link_off, size: 40, color: Colors.orange.shade800),
            ),
            const SizedBox(height: 15),
            const Text(
              "¿Desvincular Familiar?",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        content: Text(
          "Vas a desvincular a ${widget.nombreFamiliar}.\n\nNo tiene citas futuras pagadas con tus bonos, por lo que es seguro proceder sin perder dinero.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Cancelar", style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, <int>[]), // Lista vacía = Proceder
            child: const Text("Confirmar Desvinculación", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
    final citasACancelarCount = _conflictos.where((c) => c.cancelar).length;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.only(top: 25, bottom: 10),
      title: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 10),
          Text(
            "Citas Pendientes de ${widget.nombreFamiliar}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 5),
          const Text(
            "Este familiar tiene citas pagadas con TUS bonos",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _conflictos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _conflictos[index];
                    final bgColor = item.cancelar ? Colors.red.shade50 : Colors.green.shade50;
                    final borderColor = item.cancelar ? Colors.red.shade200 : Colors.green.shade200;
                    final textColor = item.cancelar ? Colors.red.shade900 : Colors.green.shade900;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        activeColor: Colors.red,
                        activeTrackColor: Colors.red.shade200,
                        inactiveThumbColor: Colors.green, 
                        inactiveTrackColor: Colors.green.shade200,
                        
                        title: Text(
                          "Cita ${DateFormat('dd/MM HH:mm').format(item.fecha)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bono: ${item.nombreBono}", style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              item.cancelar 
                                ? "ACCIÓN: CANCELAR Y DEVOLVER SALDO" 
                                : "ACCIÓN: MANTENER (REGALAR CITA)",
                              style: TextStyle(
                                color: textColor, 
                                fontWeight: FontWeight.w800, 
                                fontSize: 11, 
                                letterSpacing: 0.5
                              ),
                            ),
                          ],
                        ),
                        value: item.cancelar,
                        onChanged: (val) {
                          setState(() {
                            item.cancelar = val;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Se cancelarán $citasACancelarCount de ${_conflictos.length} citas",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  if (citasACancelarCount > 0)
                    const Text(
                      "+ Saldo devuelto",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    )
                ],
              ),
            )
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text("Atrás"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text("Aplicar Cambios y Desvincular"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          onPressed: () {
            final idsACancelar = _conflictos
                .where((c) => c.cancelar)
                .map((c) => c.idCita)
                .toList();
            Navigator.pop(context, idsACancelar);
          },
        ),
      ],
    );
  }
}