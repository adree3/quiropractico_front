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
  State<SmartDesvinculacionDialog> createState() =>
      _SmartDesvinculacionDialogState();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        content: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Analizando citas pendientes...",
                style: TextStyle(color: Colors.grey),
              ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      );
    }

    if (_conflictos.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Desvinculación Segura",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 16),

              // Tarjeta de información encapsulada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      "Estás a punto de desvincular a:",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.nombreFamiliar,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "No existen conflictos de citas ni pagos pendientes con tus bonos.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, <int>[]),
                      child: const Text("Desvincular"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final citasACancelarCount = _conflictos.where((c) => c.cancelar).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 28,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Conflictos Detectados",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.nombreFamiliar} tiene citas pagadas con tus bonos",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _conflictos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _conflictos[index];
                    final isCancel = item.cancelar;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isCancel
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.red.shade400,
                        inactiveThumbColor: Colors.green,
                        inactiveTrackColor: Colors.green.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          "Cita ${DateFormat('dd/MM HH:mm').format(item.fecha)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombreBono,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCancel ? "Devolver saldo" : "Regalar cita",
                              style: TextStyle(
                                color: isCancel ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      citasACancelarCount > 0
                          ? "Se cancelarán $citasACancelarCount citas y se devolverá el saldo."
                          : "No se cancelará ninguna cita (se regalan).",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            citasACancelarCount > 0
                                ? Colors.black87
                                : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Cancelar"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    final idsACancelar =
                        _conflictos
                            .where((c) => c.cancelar)
                            .map((c) => c.idCita)
                            .toList();
                    Navigator.pop(context, idsACancelar);
                  },
                  child: const Text("Confirmar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
