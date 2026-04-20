import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class CitaCompletarDialog extends StatefulWidget {
  final Cita cita;

  const CitaCompletarDialog({super.key, required this.cita});

  @override
  State<CitaCompletarDialog> createState() => _CitaCompletarDialogState();
}

class _CitaCompletarDialogState extends State<CitaCompletarDialog> {
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;
  String? _error;
  bool _isSigned = false;
  bool _showReloadFeedback = false;

  @override
  void initState() {
    super.initState();
    _isSigned = widget.cita.firmada;
    
    // Escuchar cambios en el provider para detectar la firma vía WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CitasProvider>(context, listen: false).addListener(_handleProviderUpdate);
      }
    });

    // Disparamos la firma en la tablet automáticamente al abrir
    if (!_isSigned) {
      _solicitarFirmaTablet();
    }
  }

  @override
  void dispose() {
    // Es vital remover el listener para evitar fugas de memoria
    try {
      Provider.of<CitasProvider>(context, listen: false).removeListener(_handleProviderUpdate);
    } catch (_) {}
    super.dispose();
  }

  void _handleProviderUpdate() {
    if (!mounted) return;
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    
    // Primero intentamos buscar en la lista (paginada) por si acaso
    Cita? citaEnLista;
    try {
      citaEnLista = citasProvider.citas.firstWhere((c) => c.idCita == widget.cita.idCita);
    } catch (_) {}

    // Pero LA VERDAD DEFINITIVA la tiene el set de firmas recibidas por WS
    final estaFirmadaPorWS = citasProvider.isCitaFirmadaRecientemente(widget.cita.idCita);
    final estaFirmadaEnLista = citaEnLista?.firmada ?? false;

    if ((estaFirmadaEnLista || estaFirmadaPorWS) && !_isSigned) {
      setState(() => _isSigned = true);
    }
  }

  Future<void> _solicitarFirmaTablet() async {
    setState(() => _showReloadFeedback = true);
    final provider = Provider.of<CitasProvider>(context, listen: false);
    await provider.solicitarFirma(widget.cita.idCita);
    
    // Feedback visual breve
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showReloadFeedback = false);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      if (result.files.any((f) => f.size > 15 * 1024 * 1024)) {
        setState(() => _error = 'Alguna imagen supera los 15MB');
        return;
      }
      setState(() {
        _selectedFiles = [..._selectedFiles, ...result.files];
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle_outline, color: _isSigned ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text('Finalizar Sesión #${widget.cita.idCita}')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paciente: ${widget.cita.nombreClienteCompleto}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 30),
  
              // SECCIÓN TABLET / FIRMA
              _buildTabletStatus(),
  
              const SizedBox(height: 25),
  
              // SECCIÓN IMÁGENES
              const Text(
                'Imágenes de la Sesión',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              
              _buildModernUploadZone(),
  
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    actions: [
        Row(
          children: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            const Spacer(),
            if (!_isSigned && !_isSubmitting)
               TextButton.icon(
                icon: const Icon(Icons.no_accounts_rounded, size: 18, color: Colors.orange),
                label: const Text('Finalizar sin firma', style: TextStyle(color: Colors.orange)),
                onPressed: () => _confirmarFinalizarSinFirma(),
              ),
            const SizedBox(width: 8),
            if (_selectedFiles.isEmpty)
              TextButton.icon(
                icon: const Icon(Icons.forward_rounded, size: 18),
                label: const Text('Omitir imágenes'),
                onPressed: _isSubmitting ? null : () => _finalizarSesion(),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSubmitting ? 'Guardando...' : 'Guardar imágenes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : () => _finalizarSesion(),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmarFinalizarSinFirma() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar sin firma?'),
        content: const Text('Se completará la sesión sin la firma digital del paciente. Esta acción quedará registrada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, finalizar', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _finalizarSesion();
    }
  }

  Widget _buildTabletStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSigned ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isSigned ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isSigned ? Icons.verified_rounded : (_showReloadFeedback ? Icons.sync : Icons.tablet_android_rounded),
              key: ValueKey(_isSigned ? 'signed' : (_showReloadFeedback ? 'sync' : 'tablet')),
              color: _isSigned ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSigned ? '¡Firma del paciente recibida!' : 'Esperando firma en Tablet...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _isSigned ? Colors.green.shade800 : Colors.orange.shade800
                  ),
                ),
                if (!_isSigned)
                  const Text('El paciente verá el panel automáticamente.', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (!_isSigned)
            IconButton(
              tooltip: 'Reenviar señal',
              icon: Icon(
                _showReloadFeedback ? Icons.check_circle : Icons.refresh, 
                size: 20, 
                color: _showReloadFeedback ? Colors.green : Colors.blueGrey
              ),
              onPressed: _showReloadFeedback ? null : _solicitarFirmaTablet,
            )
        ],
      ),
    );
  }

  Widget _buildModernUploadZone() {
    final bool hasFiles = _selectedFiles.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFiles ? AppTheme.primaryColor.withOpacity(0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFiles ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: hasFiles 
        ? Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedFiles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedFiles.length) {
                    return _buildAddMoreButton();
                  }
                  
                  final file = _selectedFiles[index];
                  return _buildGridThumbnail(file, index);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_selectedFiles.length} imágenes seleccionadas',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          )
        : InkWell(
            onTap: _pickFiles,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Haz clic para adjuntar archivos',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Formatos: JPG, PNG • Máx 15MB',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildGridThumbnail(PlatformFile file, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            image: DecorationImage(
              image: MemoryImage(file.bytes!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: () => setState(() => _selectedFiles.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), topRight: Radius.circular(8))
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      onTap: _pickFiles,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor, size: 28),
      ),
    );
  }

  Future<void> _finalizarSesion() async {
    setState(() => _isSubmitting = true);

    try {
      final docProvider = Provider.of<DocumentosProvider>(context, listen: false);
      final citasProvider = Provider.of<CitasProvider>(context, listen: false);

      // 1. Subir imágenes en paralelo para mayor rapidez
      if (_selectedFiles.isNotEmpty) {
        await Future.wait(_selectedFiles.map((file) => docProvider.subirDocumento(
          idCliente: widget.cita.idCliente,
          bytes: file.bytes!,
          filename: file.name,
          tipoDocumento: 'RADIOGRAFIA', 
          idCita: widget.cita.idCita,
          notas: 'Imagen capturada durante la sesión del ${widget.cita.fechaHoraInicio}',
        )));
      }

      // 2. Cambiar el estado de la cita a COMPLETADA (si no lo está ya)
      await citasProvider.changeCitaState(widget.cita.idCita, 'completada');

      if (mounted) {
        Navigator.pop(context, true);
        CustomSnackBar.show(
          context,
          message: 'Sesión finalizada correctamente',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al finalizar: $e';
          _isSubmitting = false;
        });
      }
    }
  }
}

