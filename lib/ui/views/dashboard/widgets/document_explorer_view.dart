import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_widgets.dart';
import 'package:quiropractico_front/utils/download_helper.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_folder_grid.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_upload_dialog.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_info_dialog.dart';
import 'package:quiropractico_front/ui/widgets/document_thumbnail.dart';

class DocumentExplorerView extends StatefulWidget {
  final Cliente cliente;
  final CarpetaLogica carpeta;
  final List<Documento> documentos;

  const DocumentExplorerView({
    super.key,
    required this.cliente,
    required this.carpeta,
    required this.documentos,
  });

  @override
  State<DocumentExplorerView> createState() => _DocumentExplorerViewState();
}

class _DocumentExplorerViewState extends State<DocumentExplorerView> {
  bool _isGrid = true;

  Future<void> _descargarDocumento(BuildContext context, Documento doc) async {
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    final url = provider.getDownloadUrl(doc.idDocumento);
    DownloadHelper.downloadFile(url, doc.nombreOriginal);
  }

  Future<void> _verDocumento(BuildContext context, Documento doc) async {
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    final url = await provider.obtenerUrlTemporal(doc.idDocumento, download: false);
    if (url != null) {
      DownloadHelper.viewFile(url);
    }
  }

  void _mostrarFichaDocumento(BuildContext context, Documento doc) {
    showDialog(
      context: context,
      builder: (context) => DocumentInfoDialog(
        doc: doc,
        onOpenFull: () => _verDocumento(context, doc),
      )
    );
  }

  Future<void> _subirDocumento(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentUploadDialog(
        cliente: widget.cliente,
        carpeta: widget.carpeta,
      ),
    );

    if (result == null) return;

    final PlatformFile file = result['file'];
    final String notas = result['notas'];
    final int? idCita = result['idCita'];
    final int? idPago = result['idPago'];
    final String tipoSeleccionado = result['tipo'] ?? widget.carpeta.tiposIncluidos.first;

    if (!context.mounted) return;
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    
    final error = await provider.subirDocumento(
      idCliente: widget.cliente.idCliente,
      bytes: file.bytes!,
      filename: file.name,
      tipoDocumento: tipoSeleccionado,
      idCita: idCita,
      idPago: idPago,
      notas: notas,
    );

    if (!context.mounted) return;
    
    if (error == null) {
      CustomSnackBar.show(context, message: 'Documento subido con éxito', type: SnackBarType.success);
    } else {
      CustomSnackBar.show(context, message: error, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentosProvider>(
      builder: (context, provider, child) {
        final liveDocs = provider.documentos.where((d) => widget.carpeta.matches(d, systemFolders)).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.carpeta.icon, color: widget.carpeta.color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      widget.carpeta.title,
                      style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${widget.cliente.nombre} ${widget.cliente.apellidos}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                tooltip: 'Recargar documentos',
                icon: const Icon(Icons.sync_rounded, color: Colors.blueGrey),
                onPressed: () => provider.loadDocumentos(widget.cliente.idCliente),
              ),
              IconButton(
                tooltip: _isGrid ? 'Cambiar a lista' : 'Cambiar a cuadrícula',
                icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.blueGrey),
                onPressed: () => setState(() => _isGrid = !_isGrid),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: provider.isLoading 
              ? _buildSkeletonGrid()
              : liveDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.snippet_folder_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            "Ningún documento encontrado", 
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)
                          ),
                        ],
                      ),
                    )
                  : (_isGrid 
                      ? _buildGrid(liveDocs, provider.isUploading) 
                      : _buildList(liveDocs, provider.isUploading)),
          floatingActionButton: provider.isUploading ? null : FloatingActionButton.extended(
            onPressed: () => _subirDocumento(context),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text("Subir Archivo"),
            backgroundColor: widget.carpeta.color,
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return !_isGrid 
      ? ListView.builder(
          itemCount: 8,
          itemBuilder: (context, _) => const SkeletonListTile(),
        )
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: 12,
          itemBuilder: (context, _) => const SkeletonDocumentCard(),
        );
  }

  Widget _buildGrid(List<Documento> docs, bool isUploading) {
    final totalCount = docs.length + (isUploading ? 1 : 0);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (isUploading && index == 0) {
          return const SkeletonDocumentCard(label: "Subiendo...");
        }
        final doc = docs[isUploading ? index - 1 : index];
        return Tooltip(
          message: 'Ver detalles',
          child: _SmartMetaIcon(
            doc: doc, 
            color: widget.carpeta.color,
            onTap: () => _mostrarFichaDocumento(context, doc),
            onDownload: () => _descargarDocumento(context, doc),
          ),
        );
      },
    );
  }

  Widget _buildList(List<Documento> docs, bool isUploading) {
    final totalCount = docs.length + (isUploading ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (isUploading && index == 0) {
          return const SkeletonListTile();
        }
        final doc = docs[isUploading ? index - 1 : index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.carpeta.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIconForMime(doc.mimeType), color: widget.carpeta.color),
          ),
          title: Text(doc.nombreOriginal, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text("Subido el ${_formatDate(doc.fechaSubida)} • ${_formatBytes(doc.tamanyoBytes)}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.blueGrey),
                tooltip: 'Descargar imagen',
                onPressed: () => _descargarDocumento(context, doc),
              ),
              const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
            ],
          ),
          onTap: () => _mostrarFichaDocumento(context, doc),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / 1048576).toStringAsFixed(2)} MB";
  }

  IconData _getIconForMime(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('image')) return Icons.image;
    if (mime.contains('video')) return Icons.movie;
    if (mime.contains('audio')) return Icons.audiotrack;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }
}

class _SmartMetaIcon extends StatefulWidget {
  final Documento doc;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _SmartMetaIcon({required this.doc, required this.color, required this.onTap, required this.onDownload});

  @override
  State<_SmartMetaIcon> createState() => _SmartMetaIconState();
}

class _SmartMetaIconState extends State<_SmartMetaIcon> {
  bool _isDownloaded = false;

  void _handleDownload() {
    widget.onDownload();
    setState(() => _isDownloaded = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isDownloaded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DocumentThumbnail(
                  doc: widget.doc,
                  baseColor: widget.color,
                ),
              )
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.doc.nombreOriginal,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: 'Descargar',
                  child: GestureDetector(
                    onTap: _handleDownload,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isDownloaded
                            ? Colors.green.withOpacity(0.1)
                            : widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isDownloaded
                            ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green, key: ValueKey('done'))
                            : Icon(Icons.download_rounded, size: 16, color: widget.color, key: ValueKey('dl')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
