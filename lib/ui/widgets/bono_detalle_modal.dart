import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/consumo_bono.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/ui/widgets/avatar_widget.dart';

class BonoDetalleModal extends StatefulWidget {
  final Bono bono;
  final String nombreCliente;
  final int idCliente;
  final int? resaltarCitaId;

  const BonoDetalleModal({
    super.key,
    required this.bono,
    required this.nombreCliente,
    required this.idCliente,
    this.resaltarCitaId,
  });

  @override
  State<BonoDetalleModal> createState() => _BonoDetalleModalState();
}

class _BonoDetalleModalState extends State<BonoDetalleModal> {
  bool isLoading = true;
  List<ConsumoBono> consumos = [];
  String? errorMessage;

  // Variables para el scroll auto
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadConsumos();
  }

  Future<void> _loadConsumos() async {
    try {
      final response = await ApiService.dio.get(
        '${ApiConfig.baseUrl}/bonos/${widget.bono.idBonoActivo}/consumos',
      );

      if (response.data is List) {
        setState(() {
          consumos =
              (response.data as List)
                  .map((e) => ConsumoBono.fromJson(e))
                  .toList();
          isLoading = false;
        });

        // Disparar scroll hacia el item resaltado
        if (widget.resaltarCitaId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToResaltado();
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error al cargar el historial: $e";
        isLoading = false;
      });
    }
  }

  void _scrollToResaltado() {
    final targetIndex = consumos.indexWhere(
      (c) => c.idCita == widget.resaltarCitaId,
    );

    print(
      "DEBUG Modal - Cita Target: ${widget.resaltarCitaId} | Encontrado en Index: $targetIndex",
    );

    if (targetIndex != -1) {
      // Altura real del item suele rondar los 170px dependiendo de la información
      final double estimatedItemHeight = 170.0;
      // Reducimos el offset negativo a solo 20.0 para que se posicione más arriba en pantalla
      double targetScroll = (targetIndex * estimatedItemHeight) - 20.0;
      if (targetScroll < 0) targetScroll = 0;

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.bono.nombreServicio,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: "  #${widget.bono.idBonoActivo}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cliente: ${widget.nombreCliente}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Comprado el: ${DateFormat('dd/MM/yyyy').format(widget.bono.fechaCompra)}",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // Info Resumen
            _buildInfoResumen(),
            const SizedBox(height: 24),

            const Text(
              "Historial de Uso",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista Consumos
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoResumen() {
    final porcentaje =
        widget.bono.sesionesTotales > 0
            ? widget.bono.sesionesRestantes / widget.bono.sesionesTotales
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saldo Actual",
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "${widget.bono.sesionesRestantes}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Text(
                      " / ${widget.bono.sesionesTotales} sesiones",
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: porcentaje,
                  backgroundColor: Colors.white,
                  color: Colors.blue,
                  strokeWidth: 6,
                ),
                Center(
                  child: Text(
                    "${(porcentaje * 100).toInt()}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (consumos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No hay consumos registrados",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: consumos.length,
      itemBuilder: (context, index) {
        final consumo = consumos[index];
        final isLast = index == consumos.length - 1;
        final fecha = DateFormat(
          'dd/MM/yyyy • HH:mm',
        ).format(consumo.fechaConsumo);

        final isResaltado = consumo.idCita == widget.resaltarCitaId;

        return IntrinsicHeight(
          child: Container(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline line and dot
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isResaltado
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isResaltado
                                    ? Colors.orange.shade500
                                    : Colors.blue.shade500,
                            width: isResaltado ? 3 : 2,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Sesión consumida",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            if (isResaltado) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'Cita desde la que consultaste este bono',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        color: Colors.orange.shade800,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Cita Seleccionada",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fecha,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (consumo.nombrePaciente != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              AvatarWidget(
                                nombreCompleto: consumo.nombrePaciente!,
                                id: consumo.idPaciente,
                                radius: 8,
                                fontSize: 8,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Paciente: ${consumo.nombrePaciente}",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (consumo.idPaciente != null &&
                                  consumo.idPaciente != widget.idCliente) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    "Familiar",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Card de detalle de la cita asociada
                        if (consumo.fechaCita != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Cita asociada",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(consumo.fechaCita!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      if (consumo.nombreQuiropractico != null)
                                        Text(
                                          "Dr. ${consumo.nombreQuiropractico}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          "Saldo restante tras uso: ${consumo.sesionesRestantesSnapshot}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
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
      },
    );
  }
}
