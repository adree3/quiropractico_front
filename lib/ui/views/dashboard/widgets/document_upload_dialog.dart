import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/models/tipo_documento.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_widgets.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_folder_grid.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/quota_exceeded_dialog.dart';

class DocumentUploadDialog extends StatefulWidget {
  final Cliente cliente;
  final CarpetaLogica? carpeta;
  final TipoDocumento? initialTipo;

  const DocumentUploadDialog({
    super.key,
    required this.cliente,
    this.carpeta,
    this.initialTipo,
  });

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notasController = TextEditingController();
  final _etiquetaController = TextEditingController();
  late TipoDocumento _selectedTipo;
  List<PlatformFile> _selectedFiles = [];
  Cita? _selectedCita;
  Pago? _selectedPago;
  List<Cita> _clientCitas = [];
  List<Pago> _clientPagos = [];
  bool _isLoadingCitas = true;
  bool _isLoadingPagos = true;
  bool _isSubmitting = false;
  String? _globalError;
  bool _autoValidate = false;
  bool _dragging = false;
  
  // Para Consentimientos
  String? _selectedConsentType;
  final _customConsentController = TextEditingController();
  
  // Para Otros
  final _customTitleController = TextEditingController();

  final _citaSearchController = TextEditingController();
  final _citaFocusNode = FocusNode();
  final _pagoSearchController = TextEditingController();
  final _pagoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialTipo != null) {
      _selectedTipo = widget.initialTipo!;
    } else if (widget.carpeta != null) {
      switch (widget.carpeta!.id) {
        case 'imagenes': _selectedTipo = TipoDocumento.pruebaMedica; break;
        case 'firmas': _selectedTipo = TipoDocumento.justificanteAsistencia; break;
        case 'consentimientos': _selectedTipo = TipoDocumento.consentimientoLopd; break;
        case 'informes': _selectedTipo = TipoDocumento.informeMedico; break;
        case 'facturacion': _selectedTipo = TipoDocumento.facturacion; break;
        default: _selectedTipo = TipoDocumento.otro; break;
      }
    } else {
      _selectedTipo = TipoDocumento.pruebaMedica;
    }

    if (_selectedTipo == TipoDocumento.facturacion) {
      _fetchPagos();
    } else if (_selectedTipo != TipoDocumento.consentimientoLopd && _selectedTipo != TipoDocumento.consentimientoTratamiento) {
      _fetchCitas();
    } else {
      _isLoadingCitas = false;
      _isLoadingPagos = false;
    }
  }

  Future<void> _fetchPagos() async {
    final provider = Provider.of<PaymentsProvider>(context, listen: false);
    final pagos = await provider.fetchPagosCliente(widget.cliente.idCliente);
    if (mounted) {
      setState(() {
        _clientPagos = pagos;
        _isLoadingPagos = false;
      });
    }
  }

  Future<void> _fetchCitas() async {
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    final docsProvider = Provider.of<DocumentosProvider>(context, listen: false);
    
    List<Cita> citas = await citasProvider.fetchCitasCliente(widget.cliente.idCliente);
    
    // Si es justificante de firma, solo mostramos citas que NO tengan firma activa
    if (_selectedTipo == TipoDocumento.justificanteAsistencia) {
      final idsCitasFirmadas = docsProvider.documentos
          .where((d) => d.tipo == TipoDocumento.justificanteAsistencia)
          .map((d) => d.idCita)
          .where((id) => id != null)
          .toSet();
      
      citas = citas.where((c) => !idsCitasFirmadas.contains(c.idCita)).toList();
    }

    if (mounted) {
      setState(() {
        _clientCitas = citas;
        _isLoadingCitas = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FileType fileType = FileType.any;
    List<String>? allowedExtensions;
    if (_selectedTipo == TipoDocumento.pruebaMedica) {
      fileType = FileType.image;
    } else if (_selectedTipo == TipoDocumento.justificanteAsistencia ||
               _selectedTipo == TipoDocumento.consentimientoLopd ||
               _selectedTipo == TipoDocumento.consentimientoTratamiento ||
               _selectedTipo == TipoDocumento.informeMedico) {
      fileType = FileType.custom;
      allowedExtensions = ['pdf'];
    } else if (_selectedTipo == TipoDocumento.facturacion) {
      fileType = FileType.custom;
      allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
      allowMultiple: _selectedTipo == TipoDocumento.pruebaMedica,
    );

    if (result != null) {
      // Limitar tamaño a 15MB para la web
      if (result.files.any((f) => f.size > 15 * 1024 * 1024)) {
        setState(() {
          _globalError = 'Algún archivo supera el límite de 15MB.';
        });
        return;
      }
      setState(() {
        _selectedFiles = result.files;
        _globalError = null; // Limpiar error global al seleccionar archivo
      });
    }
  }

  @override
  void dispose() {
    _etiquetaController.dispose();
    _notasController.dispose();
    _customConsentController.dispose();
    _customTitleController.dispose();
    _citaSearchController.dispose();
    _citaFocusNode.dispose();
    _pagoSearchController.dispose();
    _pagoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirma = _selectedTipo == TipoDocumento.justificanteAsistencia;
    final Color temaColor = _selectedTipo.color;

    return AlertDialog(
      title: Row(
        children: [
          Icon(_selectedTipo.icono, color: temaColor),
          const SizedBox(width: 8),
          Text(isFirma ? 'Subir Cita Firmada' : 'Subir Documento (${_selectedTipo.nombreLegible})'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Selector de archivo ──
                DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: (details) async {
                    setState(() => _dragging = false);
                    var files = details.files;
                    if (files.isEmpty) return;
                    
                    if (_selectedTipo != TipoDocumento.pruebaMedica && files.length > 1) {
                      files = [files.first];
                    }

                    List<PlatformFile> validFiles = [];
                    for (var file in files) {
                       final name = file.name.toLowerCase();
                       bool isValid = true;
                       if (_selectedTipo == TipoDocumento.justificanteAsistencia ||
                           _selectedTipo == TipoDocumento.consentimientoLopd ||
                           _selectedTipo == TipoDocumento.consentimientoTratamiento ||
                           _selectedTipo == TipoDocumento.informeMedico) {
                         isValid = name.endsWith('.pdf');
                       } else if (_selectedTipo == TipoDocumento.facturacion) {
                         isValid = name.endsWith('.pdf') || name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');
                       } else if (_selectedTipo == TipoDocumento.pruebaMedica) {
                         isValid = name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.gif') || name.endsWith('.webp');
                       }

                       if (!isValid) {
                         setState(() => _globalError = 'Tipo de archivo no permitido para ${_selectedTipo.nombreLegible}.');
                         return;
                       }
                       final bytes = await file.readAsBytes();
                       validFiles.add(PlatformFile(
                         name: file.name,
                         size: bytes.length,
                         bytes: bytes,
                       ));
                    }
                    
                    if (validFiles.any((f) => f.size > 15 * 1024 * 1024)) {
                      setState(() {
                        _globalError = 'Algún archivo supera el límite de 15MB.';
                      });
                      return;
                    }
                    
                    setState(() {
                       _selectedFiles = validFiles;
                       _globalError = null;
                    });
                  },
                  child: InkWell(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dragging 
                              ? temaColor 
                              : (_selectedFiles.isNotEmpty ? temaColor : Colors.grey.shade400),
                          width: _dragging || _selectedFiles.isNotEmpty ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _dragging 
                            ? temaColor.withValues(alpha: 0.1) 
                            : (_selectedFiles.isNotEmpty
                                ? temaColor.withValues(alpha: 0.05)
                                : Colors.grey.shade50),
                      ),
                      child: Column(
                      children: [
                        // PDF firmada → icono PDF estilizado; otros → icono genérico
                        if (isFirma)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 56,
                                  color: _selectedFiles.isNotEmpty
                                      ? Colors.red.shade600
                                      : Colors.red.shade200),
                              if (_selectedFiles.isNotEmpty)
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.green, shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          )
                        else
                          Icon(Icons.cloud_upload_rounded, size: 48,
                              color: _selectedFiles.isNotEmpty ? temaColor : Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFiles.isNotEmpty
                              ? (_selectedFiles.length == 1 ? _selectedFiles.first.name : '${_selectedFiles.length} archivos seleccionados')
                              : isFirma
                                  ? '1. Seleccionar documento PDF firmado'
                                  : '1. Arrastra archivos aquí o haz clic para subir',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedFiles.isNotEmpty ? Colors.black87 : Colors.blueGrey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFiles.length == 1)
                          Text(
                            '${(_selectedFiles.first.size / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          )
                        else if (_selectedFiles.length > 1)
                          Text(
                            '${(_selectedFiles.fold(0, (sum, f) => sum + f.size) / 1024).toStringAsFixed(1)} KB en total',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        if (isFirma && _selectedFiles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Solo se admiten archivos PDF',
                              style: TextStyle(color: Colors.red.shade300, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
                
              // ── 2. Categoría y Etiqueta ──
              Row(
                children: [
                  const Text('2. Categoría del Documento', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.initialTipo != null || widget.carpeta != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 12, color: Colors.blueGrey),
                          SizedBox(width: 4),
                          Text('Fijada por carpeta',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final bool isTipoBloqueado = widget.initialTipo != null || widget.carpeta != null;

                  return DropdownButtonFormField<TipoDocumento>(
                    value: _selectedTipo,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: isTipoBloqueado,
                      fillColor: isTipoBloqueado ? Colors.grey.shade100 : null,
                      suffixIcon: isTipoBloqueado
                          ? const Tooltip(
                              message: 'Categoría fijada por la carpeta actual',
                              child: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.blueGrey),
                            )
                          : null,
                    ),
                    disabledHint: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedTipo.icono, color: _selectedTipo.color, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _selectedTipo.nombreLegible,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    items: TipoDocumento.values.map((tipo) {
                      return DropdownMenuItem<TipoDocumento>(
                        value: tipo,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tipo.icono, color: tipo.color, size: 20),
                            const SizedBox(width: 10),
                            Text(tipo.nombreLegible),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: isTipoBloqueado
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTipo = val;
                                if (_selectedTipo == TipoDocumento.facturacion && _clientPagos.isEmpty) {
                                  _fetchPagos();
                                } else if (_clientCitas.isEmpty) {
                                  _fetchCitas();
                                }
                              });
                            }
                          },
                  );
                },
              ),
              if (_selectedTipo == TipoDocumento.pruebaMedica || _selectedTipo == TipoDocumento.otro) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _etiquetaController,
                  decoration: InputDecoration(
                    labelText: 'Etiqueta / Descripción (Opcional)',
                    hintText: _selectedTipo == TipoDocumento.pruebaMedica
                        ? 'Ej: Radiografía Lumbar, Resonancia C5-C6...'
                        : 'Ej: DNI, Presupuesto, Documento Externo...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 16),

                // ── 3. Vinculación Opcional ──
                if (_selectedTipo == TipoDocumento.facturacion) ...[
                  const Text('3. Vincular a Pago / Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _isLoadingPagos
                      ? const SkeletonWidget(width: double.infinity, height: 55)
                      : _buildPagoAutocomplete(),
                ] else if (_selectedTipo != TipoDocumento.consentimientoLopd && _selectedTipo != TipoDocumento.consentimientoTratamiento) ...[
                  Row(
                    children: [
                      const Text('3. Vincular a Sesión (Cita)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Opcional',
                            style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingCitas
                      ? const SkeletonWidget(width: double.infinity, height: 55)
                      : _buildCitaAutocomplete(required: false),
                ],

                const SizedBox(height: 24),

                // ── 3. Notas ──
                Text(
                  _getLabelForNotes(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notasController,
                  maxLines: (_selectedTipo == TipoDocumento.justificanteAsistencia ||
                          _selectedTipo == TipoDocumento.consentimientoLopd ||
                          _selectedTipo == TipoDocumento.consentimientoTratamiento)
                      ? 2
                      : 4,
                  onChanged: (_) {
                     if (_globalError != null && _globalError!.startsWith('❌')) setState(() => _globalError = null);
                  },
                  decoration: InputDecoration(
                    hintText: _getHintForNotes(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (val) {
                    bool obligatorio = _selectedTipo == TipoDocumento.pruebaMedica || _selectedTipo == TipoDocumento.informeMedico;
                    if (obligatorio && (val == null || val.trim().isEmpty)) {
                      return 'Especifica el contexto de este documento.';
                    }
                    return null;
                  },
                ),

                // ── Cajón de Error Global (Archivo o Backend) ──
                if (_globalError != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _globalError!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: _isSubmitting ? Colors.grey.shade400 : Colors.grey)),
        ),
        Consumer<DocumentosProvider>(
          builder: (context, provider, child) {
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: temaColor),
              onPressed: _isSubmitting ? null : _submitDialog,
              icon: _isSubmitting 
                  ? const SizedBox.shrink()
                  : const Icon(Icons.cloud_upload_rounded),
              label: _isSubmitting 
                  ? SizedBox(
                      width: 140,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Subiendo... ${(provider.uploadProgress * 100).toInt()}%'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: provider.uploadProgress,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    )
                  : Text(_getLabelForSubmit()),
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitDialog() async {
    setState(() => _autoValidate = true);
    
    final formOk = _formKey.currentState!.validate();
    
    if (_selectedFiles.isEmpty) {
      setState(() => _globalError = 'Adjunta al menos un archivo antes de guardar.');
      return;
    }

    if (!formOk) return;

    // Preparar datos de salida
    String? finalNotes = _notasController.text.trim().isEmpty ? null : _notasController.text.trim();
    String finalTipo = _selectedTipo.codigo;
    String? finalEtiqueta = _etiquetaController.text.trim().isEmpty ? null : _etiquetaController.text.trim();

    if (_selectedTipo == TipoDocumento.consentimientoLopd || _selectedTipo == TipoDocumento.consentimientoTratamiento) {
       if (_selectedConsentType != null) {
         finalNotes = "Tipo: ${_selectedConsentType == 'OTRO' ? _customConsentController.text : _selectedConsentType}. ${finalNotes ?? ''}".trim();
       }
    }
    if (_selectedTipo == TipoDocumento.otro && _customTitleController.text.isNotEmpty) {
       finalNotes = "Título: ${_customTitleController.text}. ${finalNotes ?? ''}".trim();
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    
    int errorsCount = 0;
    String lastError = '';

    for (var file in _selectedFiles) {
      final error = await provider.subirDocumento(
        idCliente: widget.cliente.idCliente,
        bytes: file.bytes!,
        filename: file.name,
        tipoDocumento: finalTipo,
        etiqueta: finalEtiqueta,
        idCita: _selectedCita?.idCita,
        idPago: _selectedPago?.idPago,
        notas: finalNotes,
      );
      if (error != null) {
        errorsCount++;
        lastError = error;
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (errorsCount == 0) {
        Navigator.pop(context, true); // true = exito
      } else {
        if (lastError == 'Has superado el límite de almacenamiento de tu plan. No se puede subir el archivo.') {
          showDialog(
            context: context,
            builder: (_) => const QuotaExceededDialog(),
          );
          // Ocultamos el error en rojo del modal para evitar redundancia
          setState(() => _globalError = null);
        } else {
          setState(() => _globalError = '❌ Fallaron $errorsCount archivo(s). Detalle: $lastError');
        }
      }
    }
  }

  String _getLabelForNotes() {
    switch (_selectedTipo) {
      case TipoDocumento.justificanteAsistencia:
      case TipoDocumento.consentimientoLopd:
      case TipoDocumento.consentimientoTratamiento:
        return '3. Notas adicionales (Opcional)';
      case TipoDocumento.facturacion:
        return '3. Notas (Opcional)';
      case TipoDocumento.informeMedico:
      case TipoDocumento.pruebaMedica:
        return '3. Notas Clínicas (Obligatorio)';
      case TipoDocumento.otro:
        return '3. Notas (Opcional)';
    }
  }

  String _getHintForNotes() {
    switch (_selectedTipo) {
      case TipoDocumento.justificanteAsistencia:
        return 'Ej: Firmado en tablet por el paciente...';
      case TipoDocumento.consentimientoLopd:
      case TipoDocumento.consentimientoTratamiento:
        return 'Ej: Versión renovada del 2024...';
      case TipoDocumento.informeMedico:
        return 'Resume el contenido del informe médico...';
      case TipoDocumento.pruebaMedica:
        return 'Escribe hallazgos o conclusiones...';
      case TipoDocumento.facturacion:
        return 'Ej: Factura de tratamiento, justificante bancario...';
      case TipoDocumento.otro:
        return 'Escribe tus observaciones aquí...';
    }
  }

  String _getLabelForSubmit() {
    switch (_selectedTipo) {
      case TipoDocumento.justificanteAsistencia:
        return 'Guardar Justificante';
      case TipoDocumento.consentimientoLopd:
      case TipoDocumento.consentimientoTratamiento:
        return 'Guardar Consentimiento';
      case TipoDocumento.facturacion:
        return 'Subir Comprobante';
      default:
        return 'Subir al Historial';
    }
  }

  Widget _buildCitaAutocomplete({bool required = false}) {
    return RawAutocomplete<Cita>(
      textEditingController: _citaSearchController,
      focusNode: _citaFocusNode,
      displayStringForOption: (Cita option) => 
        "${option.fechaHoraInicio.day}/${option.fechaHoraInicio.month}/${option.fechaHoraInicio.year} - #${option.idCita}",
      optionsBuilder: (TextEditingValue textEditingValue) {
        final queryRaw = textEditingValue.text.trim();
        if (queryRaw.isEmpty) return const Iterable<Cita>.empty();
        
        final bool searchByIdOnly = queryRaw.startsWith('#');
        final lowerQuery = searchByIdOnly ? queryRaw.substring(1).trim() : queryRaw.toLowerCase();
        
        final matches = _clientCitas.where((cita) {
          final idStr = cita.idCita.toString();
          if (searchByIdOnly) {
            return idStr == lowerQuery || idStr.startsWith(lowerQuery);
          }
          final quiro = cita.nombreQuiropractico.toLowerCase();
          final dateStr = "${cita.fechaHoraInicio.day}/${cita.fechaHoraInicio.month}/${cita.fechaHoraInicio.year}";
          return idStr.contains(lowerQuery) || quiro.contains(lowerQuery) || dateStr.contains(lowerQuery);
        }).toList();

        matches.sort((a, b) => _calculateScore(b, lowerQuery).compareTo(_calculateScore(a, lowerQuery)));
        return matches.take(5);
      },
      onSelected: (Cita selection) => setState(() => _selectedCita = selection),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) {
            if (_globalError != null && _globalError!.startsWith('❌')) setState(() => _globalError = null);
          },
          decoration: InputDecoration(
            labelText: required
                ? 'Buscar cita a vincular (obligatorio)'
                : 'Buscar por ID, Fecha o Quiropráctico',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _selectedCita != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18), 
                  onPressed: () {
                    controller.clear();
                    setState(() {
                       _selectedCita = null;
                       _globalError = null;
                    });
                  }
                ) 
              : null,
          ),
          validator: (val) {
             if (required && _selectedCita == null) {
               return 'Vincula una sesión';
             }
             if (val != null && val.trim().isNotEmpty && _selectedCita == null) {
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
              constraints: const BoxConstraints(maxHeight: 250),
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

  Widget _buildPagoAutocomplete() {
    return RawAutocomplete<Pago>(
      textEditingController: _pagoSearchController,
      focusNode: _pagoFocusNode,
      displayStringForOption: (Pago option) => 
        "${option.fechaPago?.day}/${option.fechaPago?.month}/${option.fechaPago?.year} - ${option.monto}€ - ${option.concepto}",
      optionsBuilder: (TextEditingValue textEditingValue) {
        final queryRaw = textEditingValue.text.trim();
        if (queryRaw.isEmpty) return const Iterable<Pago>.empty();
        
        final bool searchByIdOnly = queryRaw.startsWith('#');
        final lowerQuery = searchByIdOnly ? queryRaw.substring(1).trim() : queryRaw.toLowerCase();
        
        final matches = _clientPagos.where((pago) {
          final idStr = pago.idPago.toString();
          if (searchByIdOnly) {
            return idStr == lowerQuery || idStr.startsWith(lowerQuery);
          }
          final concepto = pago.concepto.toLowerCase();
          final monto = pago.monto.toString();
          final dateStr = "${pago.fechaPago?.day}/${pago.fechaPago?.month}/${pago.fechaPago?.year}";
          return idStr.contains(lowerQuery) || concepto.contains(lowerQuery) || dateStr.contains(lowerQuery) || monto.contains(lowerQuery);
        }).toList();

        matches.sort((a, b) => _calculatePagoScore(b, lowerQuery).compareTo(_calculatePagoScore(a, lowerQuery)));
        return matches.take(5);
      },
      onSelected: (Pago selection) => setState(() => _selectedPago = selection),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) {
            if (_globalError != null && _globalError!.startsWith('❌')) setState(() => _globalError = null);
          },
          decoration: InputDecoration(
            labelText: 'Buscar por concepto, monto o fecha',
            prefixIcon: const Icon(Icons.payment_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _selectedPago != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18), 
                  onPressed: () {
                    controller.clear();
                    setState(() {
                       _selectedPago = null;
                       _globalError = null;
                    });
                  }
                ) 
              : null,
          ),
          validator: (val) {
             if (_selectedTipo == TipoDocumento.facturacion && _selectedPago == null) {
               return 'Vincula un pago específico';
             }
             if (val != null && val.trim().isNotEmpty && _selectedPago == null) {
               return 'Pago no encontrado. Selecciona uno de la lista.';
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
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final Pago option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(option.pagado ? Icons.check_circle_outline : Icons.pending_actions, 
                           color: option.pagado ? Colors.green : Colors.orange, size: 20),
                    title: Text("${option.fechaPago?.day}/${option.fechaPago?.month}/${option.fechaPago?.year} - ${option.monto}€"),
                    subtitle: Text(option.concepto),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculatePagoScore(Pago pago, String query) {
    final q = query.toLowerCase();
    final id = pago.idPago.toString().toLowerCase();
    final concepto = pago.concepto.toLowerCase();
    
    if (id == q) return 1000;
    if (id.startsWith(q)) return 500;
    if (concepto.contains(q)) return 300;
    return 0;
  }
}
