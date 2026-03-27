import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_widgets.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_folder_grid.dart'; // Para CarpetaLogica

class DocumentUploadDialog extends StatefulWidget {
  final Cliente cliente;
  final CarpetaLogica carpeta;

  const DocumentUploadDialog({super.key, required this.cliente, required this.carpeta});

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notasController = TextEditingController();
  PlatformFile? _selectedFile;
  Cita? _selectedCita;
  Pago? _selectedPago;
  List<Cita> _clientCitas = [];
  List<Pago> _clientPagos = [];
  bool _isLoadingCitas = true;
  bool _isLoadingPagos = true;
  
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
    if (widget.carpeta.id == 'facturacion') {
      _fetchPagos();
    } else if (widget.carpeta.id != 'consentimientos') {
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
    
    // Si estamos en la carpeta de firmas, solo mostramos citas que NO tengan firma activa
    if (widget.carpeta.id == 'firmas') {
      final idsCitasFirmadas = docsProvider.documentos
          .where((d) => d.tipoDocumento == 'JUSTIFICANTE_ASISTENCIA')
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
    // Firmas → solo PDF; Imágenes → solo images; resto → any
    FileType fileType = FileType.any;
    List<String>? allowedExtensions;
    if (widget.carpeta.id == 'firmas') {
      fileType = FileType.custom;
      allowedExtensions = ['pdf'];
    } else if (widget.carpeta.id == 'imagenes') {
      fileType = FileType.image;
    } else if (widget.carpeta.id == 'consentimientos' || widget.carpeta.id == 'informes') {
      fileType = FileType.custom;
      allowedExtensions = ['pdf'];
    } else if (widget.carpeta.id == 'facturacion') {
      fileType = FileType.custom;
      allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirma = widget.carpeta.id == 'firmas';

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.carpeta.icon, color: widget.carpeta.color),
          const SizedBox(width: 8),
          Text(isFirma ? 'Subir Cita Firmada' : 'Subir Evidencia Clínica'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Selector de archivo ──
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFile != null ? widget.carpeta.color : Colors.grey.shade400,
                        width: _selectedFile != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedFile != null
                          ? widget.carpeta.color.withOpacity(0.05)
                          : Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        // PDF firmada → icono PDF estilizado; otros → icono genérico
                        if (isFirma)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 56,
                                  color: _selectedFile != null
                                      ? Colors.red.shade600
                                      : Colors.red.shade200),
                              if (_selectedFile != null)
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
                          Icon(Icons.drive_folder_upload_rounded, size: 48,
                              color: widget.carpeta.color.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile != null
                              ? _selectedFile!.name
                              : isFirma
                                  ? '1. Seleccionar documento PDF firmado'
                                  : '1. Haz clic aquí para adjuntar archivo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedFile != null ? Colors.black87 : Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFile != null)
                          Text(
                            '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        if (isFirma && _selectedFile == null)
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
                const SizedBox(height: 24),

                // ── 2. Campos Específicos según Carpeta ──
                if (widget.carpeta.id == 'consentimientos') ...[
                  const Text('2. Tipo de Consentimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedConsentType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOPD', child: Text('Protección de Datos (LOPD)')),
                      DropdownMenuItem(value: 'TRATAMIENTO', child: Text('Consentimiento de Tratamiento')),
                      DropdownMenuItem(value: 'OTRO', child: Text('Otro (Especificar...)')),
                    ],
                    onChanged: (val) => setState(() => _selectedConsentType = val),
                    validator: (val) => val == null ? 'Selecciona un tipo' : null,
                  ),
                  if (_selectedConsentType == 'OTRO') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customConsentController,
                      decoration: InputDecoration(
                        labelText: 'Especifica el nombre del consentimiento',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Escribe el nombre' : null,
                    ),
                  ],
                ] else if (widget.carpeta.id == 'facturacion') ...[
                   const Text('2. Vincular a Pago / Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   _isLoadingPagos
                      ? const SkeletonWidget(width: double.infinity, height: 55)
                      : _buildPagoAutocomplete(),
                ] else if (widget.carpeta.id == 'otros') ...[
                  const Text('2. Título o nombre del documento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customTitleController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Documento de Identidad, Presupuesto...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'Debes poner un nombre' : null,
                  ),
                ] else ...[
                  // Imagenes, Firmas, Informes -> Buscador de Citas
                  Row(
                    children: [
                      Text(
                        widget.carpeta.id == 'informes' ? '2. Vincular a Sesión (Cita)' : '2. Vincular a Sesión (Cita)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
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
                  maxLines: (widget.carpeta.id == 'firmas' || widget.carpeta.id == 'consentimientos') ? 2 : 4,
                  decoration: InputDecoration(
                    hintText: _getHintForNotes(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (val) {
                    // Obligatorio en Imágenes e Informes
                    bool obligatorio = widget.carpeta.id == 'imagenes' || widget.carpeta.id == 'informes';
                    if (obligatorio && (val == null || val.trim().isEmpty)) {
                      return 'Debe especificarse el contexto de este documento.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: widget.carpeta.color),
          onPressed: () {
            final formOk = _formKey.currentState!.validate();
            if (_selectedFile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debes seleccionar un archivo primero.', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (formOk) {
              // Preparar datos de salida
              String? finalNotes = _notasController.text;
              String? finalTipo = widget.carpeta.tiposIncluidos.first;

              if (widget.carpeta.id == 'consentimientos') {
                 finalNotes = "Tipo: ${_selectedConsentType == 'OTRO' ? _customConsentController.text : _selectedConsentType}. $finalNotes";
                 // Mapear al enum correcto del backend
                 if (_selectedConsentType == 'LOPD') finalTipo = 'CONSENTIMIENTO_LOPD';
                 if (_selectedConsentType == 'TRATAMIENTO') finalTipo = 'CONSENTIMIENTO_TRATAMIENTO';
              }
              if (widget.carpeta.id == 'otros') {
                 finalNotes = "Título: ${_customTitleController.text}. $finalNotes";
              }

              Navigator.pop(context, {
                'file': _selectedFile,
                'notas': finalNotes,
                'tipo': finalTipo,
                'idCita': _selectedCita?.idCita,
                'idPago': _selectedPago?.idPago,
                'customName': widget.carpeta.id == 'otros' ? _customTitleController.text : null,
              });
            }
          },
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text(_getLabelForSubmit()),
        ),
      ],
    );
  }

  String _getLabelForNotes() {
    switch (widget.carpeta.id) {
      case 'firmas': return '3. Notas adicionales (Opcional)';
      case 'consentimientos': return '3. Notas adicionales (Opcional)';
      case 'facturacion': return '3. Notas (Opcional)';
      case 'informes': return '3. Notas Clínicas (Obligatorio)';
      case 'imagenes': return '3. Notas Clínicas (Obligatorio)';
      default: return '3. Notas (Opcional)';
    }
  }

  String _getHintForNotes() {
    switch (widget.carpeta.id) {
      case 'firmas': return 'Ej: Firmado en tablet por el paciente...';
      case 'consentimientos': return 'Ej: Versión renovada del 2024...';
      case 'informes': return 'Resume el contenido del informe médico...';
      case 'imagenes': return 'Escribe hallazgos o conclusiones...';
      default: return 'Escribe tus observaciones aquí...';
    }
  }

  String _getLabelForSubmit() {
     switch (widget.carpeta.id) {
       case 'firmas': return 'Guardar Firma';
       case 'consentimientos': return 'Guardar Consentimiento';
       case 'facturacion': return 'Subir Comprobante';
       default: return 'Subir al Historial';
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
                    setState(() => _selectedCita = null);
                  }
                ) 
              : null,
          ),
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
        "${option.fechaPago.day}/${option.fechaPago.month}/${option.fechaPago.year} - ${option.monto}€ - ${option.concepto}",
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
          final dateStr = "${pago.fechaPago.day}/${pago.fechaPago.month}/${pago.fechaPago.year}";
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
          decoration: InputDecoration(
            labelText: 'Buscar por concepto, monto o fecha',
            prefixIcon: const Icon(Icons.payment_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _selectedPago != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18), 
                  onPressed: () {
                    controller.clear();
                    setState(() => _selectedPago = null);
                  }
                ) 
              : null,
          ),
          validator: (val) {
             if (widget.carpeta.id == 'facturacion' && _selectedPago == null) {
               return 'Debes vincular un pago específico';
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
                    title: Text("${option.fechaPago.day}/${option.fechaPago.month}/${option.fechaPago.year} - ${option.monto}€"),
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
