import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/ui/widgets/document_thumbnail.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_widgets.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/utils/download_helper.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';

class DocumentInfoDialog extends StatefulWidget {
  final Documento doc;
  final VoidCallback onOpenFull;
  final bool isPapelera;

  const DocumentInfoDialog({
    super.key, 
    required this.doc, 
    required this.onOpenFull,
    this.isPapelera = false,
  });

  @override
  State<DocumentInfoDialog> createState() => _DocumentInfoDialogState();
}

class _DocumentInfoDialogState extends State<DocumentInfoDialog> {
  bool _isEditing = false;
  bool _isDownloaded = false;
  bool _autoValidate = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notasController;
  int? _idCitaTemporal;

  @override
  void initState() {
    super.initState();
    _notasController = TextEditingController(text: widget.doc.notasMedicas);
    _idCitaTemporal = widget.doc.idCita;
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    final error = await provider.actualizarMetadatos(
      widget.doc.idDocumento,
      idCita: (widget.doc.idCita == null) ? _idCitaTemporal : null,
      notas: _notasController.text,
    );

    if (!mounted) return;
    if (error == null) {
      CustomSnackBar.show(context, message: 'Ficha clínica actualizada', type: SnackBarType.success);
      setState(() => _isEditing = false);
    } else {
      CustomSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteConfirmDialog(
        title: 'Eliminar',
        content: 'Este archivo se moverá a la papelera.',
        confirmText: 'Eliminar',
        confirmColor: Colors.deepOrange,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirmar == true && mounted) {
      final provider = Provider.of<DocumentosProvider>(context, listen: false);
      final error = await provider.eliminarDocumento(widget.doc.idDocumento);
      if (mounted) {
        if (error == null) {
          CustomSnackBar.show(context, message: 'Documento movido a la papelera', type: SnackBarType.success);
          Navigator.pop(context, true); // Se retorna true para recargar
        } else {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        }
      }
    }
  }

  Future<void> _restaurarDocumento(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteConfirmDialog(
        title: 'Restaurar documento',
        content: 'El archivo volverá a su ubicación original y será visible de nuevo en el historial clínico.',
        confirmText: 'Restaurar',
        confirmColor: Colors.green,
        icon: Icons.restore_rounded,
      ),
    );

    if (confirmar == true && mounted) {
      final provider = Provider.of<DocumentosProvider>(context, listen: false);
      final error = await provider.restaurarDocumento(widget.doc.idDocumento);
      if (mounted) {
        if (error == null) {
          CustomSnackBar.show(context, message: 'Documento restaurado al historial', type: SnackBarType.success);
          Navigator.pop(context, true); // Se retorna true para recargar
        } else {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mime = widget.doc.mimeType ?? '';
    final isImage = mime.contains('image');
    final isPdf = mime.contains('pdf') || widget.doc.nombreOriginal.toLowerCase().endsWith('.pdf');

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.description_rounded, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.doc.nombreOriginal, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18))),
          if (!_isEditing) IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImage) ...[
                Stack(
                  children: [
                    InkWell(
                      onTap: widget.onOpenFull,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: DocumentThumbnail(
                          doc: widget.doc,
                          width: double.infinity,
                          height: 250,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isDownloaded
                                ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, key: ValueKey('done'))
                                : const Icon(Icons.download_rounded, color: Colors.white, key: ValueKey('dl')),
                          ),
                          onPressed: () {
                            final provider = Provider.of<DocumentosProvider>(context, listen: false);
                            DownloadHelper.downloadFile(provider.getDownloadUrl(widget.doc.idDocumento), widget.doc.nombreOriginal);
                            setState(() => _isDownloaded = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _isDownloaded = false);
                            });
                          },
                          tooltip: 'Descargar imagen',
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: IgnorePointer(
                        child: Chip(
                          label: Text('Abrir imagen', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
              ] else if (isPdf) ...[
                // ─── Preview PDF ─────────────────────────────
                Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        final provider = Provider.of<DocumentosProvider>(context, listen: false);
                        DownloadHelper.viewFile(provider.getViewUrl(widget.doc.idDocumento));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 72, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              widget.doc.nombreOriginal,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Haz clic para visualizar',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón Descargar (Esquina superior derecha)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isDownloaded
                                ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, key: ValueKey('done'))
                                : const Icon(Icons.download_rounded, color: Colors.white, key: ValueKey('dl')),
                          ),
                          onPressed: () {
                            final provider = Provider.of<DocumentosProvider>(context, listen: false);
                            DownloadHelper.downloadFile(provider.getDownloadUrl(widget.doc.idDocumento), widget.doc.nombreOriginal);
                            setState(() => _isDownloaded = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _isDownloaded = false);
                            });
                          },
                          tooltip: 'Descargar archivo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fecha de subida:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Text('${widget.doc.fechaSubida.day.toString().padLeft(2,'0')}/${widget.doc.fechaSubida.month.toString().padLeft(2,'0')}/${widget.doc.fechaSubida.year}'),
                ],
              ),
              if (widget.isPapelera && widget.doc.fechaEliminacionLogica != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      const Text('Eliminado el:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      const Spacer(),
                      Text(
                        () {
                          final d = widget.doc.fechaEliminacionLogica!;
                          final fecha = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                          final hora = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
                          return '$fecha a las $hora';
                        }(),
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              
              Form(
                key: _formKey,
                autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sesión vinculada:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    if (widget.doc.idCita != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 18, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text('Cita asociada: #${widget.doc.idCita}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                      )
                    else if (_isEditing)
                      _buildAppointmentSelector()
                    else
                      const Text('Sin cita asociada', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),

                    const SizedBox(height: 16),

                    const Text('Diagnóstico / Notas Clínicas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextFormField(
                        controller: _notasController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Añade observaciones críticas...',
                          filled: true,
                          fillColor: Colors.amber.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (val) {
                          bool obligatorio = widget.doc.tipoDocumento == 'IMAGEN_MEDICA' || widget.doc.tipoDocumento == 'INFORME_CLINICO';
                          if (obligatorio && (val == null || val.trim().isEmpty)) {
                            return 'Especifica el contexto de este documento.';
                          }
                          return null;
                        },
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          (widget.doc.notasMedicas != null && widget.doc.notasMedicas!.isNotEmpty) ? widget.doc.notasMedicas! : 'Sin notas registradas.',
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (_isEditing) ...[
          const SizedBox.shrink(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Aplicar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              )
            ]
          )
        ] else ...[
          if (!widget.isPapelera)
            TextButton.icon(
              onPressed: () => _confirmarEliminacion(context),
              icon: const Icon(Icons.delete_outline, color: Colors.deepOrange),
              label: const Text('Eliminar', style: TextStyle(color: Colors.deepOrange)),
            )
          else
            TextButton.icon(
              onPressed: () => _restaurarDocumento(context),
              icon: const Icon(Icons.restore_rounded, color: Colors.green),
              label: const Text('Restaurar Archivo', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              if (!widget.isPapelera)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                ),
            ]
          )
        ]
      ],
    );
  }

  Widget _buildAppointmentSelector() {
    return Consumer<CitasProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<List<Cita>>(
          future: provider.fetchCitasCliente(widget.doc.idCliente!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonWidget(width: double.infinity, height: 55);
            }
            final citas = snapshot.data ?? [];
            if (citas.isEmpty) return const Text('Historico de citas vacío', style: TextStyle(color: Colors.grey));
            
            return RawAutocomplete<Cita>(
              displayStringForOption: (Cita option) => 
                "${option.fechaHoraInicio.day}/${option.fechaHoraInicio.month}/${option.fechaHoraInicio.year} - #${option.idCita}",
              optionsBuilder: (TextEditingValue textEditingValue) {
                final queryRaw = textEditingValue.text.trim();
                if (queryRaw.isEmpty) return const Iterable<Cita>.empty();
                
                final bool searchByIdOnly = queryRaw.startsWith('#');
                final lowerQuery = searchByIdOnly ? queryRaw.substring(1).trim() : queryRaw.toLowerCase();
                
                final matches = citas.where((cita) {
                  final idStr = cita.idCita.toString();
                  if (searchByIdOnly) {
                    return idStr == lowerQuery || idStr.startsWith(lowerQuery);
                  }
                  final quiro = cita.nombreQuiropractico.toLowerCase();
                  final dateStr = "${cita.fechaHoraInicio.day}/${cita.fechaHoraInicio.month}/${cita.fechaHoraInicio.year}";
                  return idStr.contains(lowerQuery) || quiro.contains(lowerQuery) || dateStr.contains(lowerQuery);
                }).toList();

                matches.sort((a, b) {
                  int scoreA = _calculateScore(a, lowerQuery);
                  int scoreB = _calculateScore(b, lowerQuery);
                  return scoreB.compareTo(scoreA);
                });

                return matches.take(5);
              },
              onSelected: (Cita selection) => setState(() => _idCitaTemporal = selection.idCita),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text.isEmpty && _idCitaTemporal != null) {
                  // Pre-rellenar si ya hay algo seleccionado pero no en el campo
                  final c = citas.firstWhere((element) => element.idCita == _idCitaTemporal);
                  controller.text = "${c.fechaHoraInicio.day}/${c.fechaHoraInicio.month}/${c.fechaHoraInicio.year} - #${c.idCita}";
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Buscar cita por ID o Fecha',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _idCitaTemporal != null 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18), 
                          onPressed: () {
                            controller.clear();
                            setState(() => _idCitaTemporal = null);
                          }
                        ) 
                      : null,
                  ),
                  validator: (val) {
                    // Validar que si han escrito algo, obligatoriamente hayan seleccionado una cita válida
                    if (val != null && val.trim().isNotEmpty && _idCitaTemporal == null) {
                      return 'Sesión no válida. Selecciona una de la lista.';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 400,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final Cita option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text("#${option.idCita} - ${option.fechaHoraInicio.day}/${option.fechaHoraInicio.month}/${option.fechaHoraInicio.year}"),
                            subtitle: Text("Quiro: ${option.nombreQuiropractico}"),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }
  int _calculateScore(Cita cita, String query) {
    final q = query.toLowerCase();
    final id = cita.idCita.toString().toLowerCase();
    final quiro = cita.nombreQuiropractico.toLowerCase();
    
    if (id == q) return 1000;
    if (id.startsWith(q)) return 500;
    if (quiro.startsWith(q)) return 300;
    if (id.contains(q)) return 100;
    return 0;
  }
}
