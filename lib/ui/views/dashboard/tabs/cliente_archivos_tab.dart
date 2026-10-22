import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/models/tipo_documento.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_upload_dialog.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_info_dialog.dart';
import 'package:quiropractico_front/ui/widgets/document_thumbnail.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/widgets/delete_confirm_dialog.dart';
import 'package:quiropractico_front/utils/download_helper.dart';

class ClienteArchivosTab extends StatefulWidget {
  final Cliente cliente;

  const ClienteArchivosTab({super.key, required this.cliente});

  @override
  State<ClienteArchivosTab> createState() => _ClienteArchivosTabState();
}

class _ClienteArchivosTabState extends State<ClienteArchivosTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isThumbnailGrid = true;
  bool _viendoPapelera = false;
  List<Documento>? _papeleraDocs;
  bool _isLoadingPapelera = false;
  String? _errorPapelera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentosProvider>(context, listen: false)
          .loadDocumentos(widget.cliente.idCliente, silent: false);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _cargarPapelera() async {
    setState(() {
      _isLoadingPapelera = true;
      _errorPapelera = null;
    });
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    try {
      final docs = await provider.obtenerPapelera(widget.cliente.idCliente);
      if (mounted) {
        setState(() {
          _papeleraDocs = docs;
          _isLoadingPapelera = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPapelera = 'No se pudo cargar la papelera.';
          _isLoadingPapelera = false;
        });
      }
    }
  }

  Future<void> _descargarDocumento(BuildContext context, Documento doc) async {
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    final url = await provider.obtenerUrlTemporal(doc.idDocumento, download: true);
    if (url != null) {
      DownloadHelper.downloadFile(url, doc.nombreOriginal);
    }
  }

  Future<void> _verDocumento(BuildContext context, Documento doc) async {
    final provider = Provider.of<DocumentosProvider>(context, listen: false);
    final url = await provider.obtenerUrlTemporal(doc.idDocumento, download: false);
    if (url != null) {
      DownloadHelper.viewFile(url);
    }
  }

  void _mostrarFichaDocumento(BuildContext context, Documento doc, {bool isPapelera = false}) {
    showDialog<bool>(
      context: context,
      builder: (context) => DocumentInfoDialog(
        doc: doc,
        isPapelera: isPapelera,
        onOpenFull: () => _verDocumento(context, doc),
      ),
    ).then((changed) {
      if (changed == true && mounted) {
        if (_viendoPapelera) {
          _cargarPapelera();
        }
        Provider.of<DocumentosProvider>(context, listen: false)
            .loadDocumentos(widget.cliente.idCliente, silent: true);
      }
    });
  }

  Future<void> _confirmarEliminacion(BuildContext context, Documento doc) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteConfirmDialog(
        title: 'Eliminar Documento',
        content: '¿Estás seguro de que deseas mover este archivo a la papelera?',
        confirmText: 'Eliminar',
        confirmColor: Colors.deepOrange,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirmar == true && context.mounted) {
      final provider = Provider.of<DocumentosProvider>(context, listen: false);
      final error = await provider.eliminarDocumento(doc.idDocumento);
      if (context.mounted) {
        if (error == null) {
          CustomSnackBar.show(context, message: 'Documento movido a la papelera', type: SnackBarType.success);
        } else {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        }
      }
    }
  }

  Future<void> _restaurarDocumento(BuildContext context, Documento doc) async {
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

    if (confirmar == true && context.mounted) {
      final provider = Provider.of<DocumentosProvider>(context, listen: false);
      final error = await provider.restaurarDocumento(doc.idDocumento);
      if (context.mounted) {
        if (error == null) {
          CustomSnackBar.show(context, message: 'Documento restaurado', type: SnackBarType.success);
          _cargarPapelera();
          provider.loadDocumentos(widget.cliente.idCliente, silent: true);
        } else {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        }
      }
    }
  }

  Future<void> _abrirModalSubida(BuildContext context, DocumentosProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentUploadDialog(
        cliente: widget.cliente,
        initialTipo: provider.carpetaSeleccionada,
      ),
    );

    if (result == true && context.mounted) {
      CustomSnackBar.show(context, message: 'Documento subido con éxito', type: SnackBarType.success);
    }
  }

  Widget _buildSkeletonGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DocumentosProvider provider) {
    if (_viendoPapelera) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => setState(() => _viendoPapelera = false),
              tooltip: 'Volver a Archivos Activos',
            ),
            const SizedBox(width: 12),
            const Icon(Icons.delete_sweep_rounded, color: Colors.deepOrange, size: 26),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Papelera de Reciclaje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                Text(
                  '${_papeleraDocs?.length ?? 0} archivos eliminados lógicamente',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Spacer(),
            // Toggle Cuadrícula / Lista en papelera
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.grid_view_rounded, size: 16),
                  tooltip: 'Cuadrícula con miniaturas',
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.view_list_rounded, size: 16),
                  tooltip: 'Lista detallada',
                ),
              ],
              selected: {_isThumbnailGrid},
              onSelectionChanged: (set) => setState(() => _isThumbnailGrid = set.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refrescar Papelera',
              onPressed: _cargarPapelera,
            ),
          ],
        ),
      );
    }

    final bool enCarpeta = provider.viewMode == DocumentViewMode.folders && provider.carpetaSeleccionada != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          if (enCarpeta) ...[
            IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => provider.salirCarpeta(),
              tooltip: 'Volver a carpetas',
            ),
            const SizedBox(width: 12),
            Icon(provider.carpetaSeleccionada!.icono, color: provider.carpetaSeleccionada!.color, size: 26),
            const SizedBox(width: 8),
            Text(
              provider.carpetaSeleccionada!.nombreLegible,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: provider.carpetaSeleccionada!.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.documentosEnCarpetaActual.length}',
                style: TextStyle(
                  color: provider.carpetaSeleccionada!.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.folder_shared_rounded, color: Colors.blueGrey, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expediente Documental',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${provider.documentos.length} archivos registrados',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
          const Spacer(),
          // Selector Material 3: Carpetas / Lista Plana
          SegmentedButton<DocumentViewMode>(
            segments: const [
              ButtonSegment<DocumentViewMode>(
                value: DocumentViewMode.folders,
                icon: Icon(Icons.folder_outlined, size: 18),
                label: Text('Carpetas'),
              ),
              ButtonSegment<DocumentViewMode>(
                value: DocumentViewMode.flatList,
                icon: Icon(Icons.view_list_rounded, size: 18),
                label: Text('Lista Plana'),
              ),
            ],
            selected: {provider.viewMode},
            onSelectionChanged: (newSelection) {
              provider.setViewMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          // Toggle interno: Cuadrícula con miniaturas vs Tabla/Lista (visible si estamos dentro de una carpeta o en Lista Plana)
          if (enCarpeta || provider.viewMode == DocumentViewMode.flatList) ...[
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.grid_view_rounded, size: 16),
                  tooltip: 'Cuadrícula con miniaturas',
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.view_list_rounded, size: 16),
                  tooltip: 'Lista detallada',
                ),
              ],
              selected: {_isThumbnailGrid},
              onSelectionChanged: (set) => setState(() => _isThumbnailGrid = set.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
          const SizedBox(width: 10),
          // Botón Papelera
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _viendoPapelera = true);
              _cargarPapelera();
            },
            icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.deepOrange),
            label: const Text('Papelera', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.deepOrange.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _abrirModalSubida(context, provider),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Subir Archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── GRID DE CARPETAS VIRTUALES ──
  Widget _buildCarpetasGrid(BuildContext context, DocumentosProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: TipoDocumento.values.length,
      itemBuilder: (context, index) {
        final tipo = TipoDocumento.values[index];
        final count = provider.documentos.where((d) => d.tipo == tipo).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => provider.entrarCarpeta(tipo),
              hoverColor: tipo.color.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tipo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(tipo.icono, color: tipo.color, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: count > 0 ? tipo.color.withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count ${count == 1 ? 'archivo' : 'archivos'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: count > 0 ? tipo.color : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipo.nombreLegible,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Click para explorar',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── CUADRÍCULA RICA CON MINATURAS (DocumentThumbnail) ──
  Widget _buildThumbnailGrid(List<Documento> docs, {required bool isPapelera, String? emptyMsg}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMsg ?? (isPapelera ? 'La papelera está vacía' : 'No hay documentos registrados'),
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final tipo = doc.tipo;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _mostrarFichaDocumento(context, doc, isPapelera: isPapelera),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Área de miniatura
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: tipo.color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DocumentThumbnail(
                                doc: doc,
                                baseColor: tipo.color,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Chip de Tipo en la esquina superior izquierda
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tipo.color.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tipo.nombreLegible,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Chip de Etiqueta (si existe) en la esquina superior derecha o inferior
                          if (doc.etiqueta != null && doc.etiqueta!.isNotEmpty)
                            Positioned(
                              bottom: 6,
                              left: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade700.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  doc.etiqueta!,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nombre del archivo y acción
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.nombreOriginal,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPapelera)
                          IconButton(
                            icon: const Icon(Icons.restore_rounded, size: 18, color: Colors.green),
                            tooltip: 'Restaurar documento',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _restaurarDocumento(context, doc),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.download_rounded, size: 18, color: Colors.blueGrey),
                            tooltip: 'Descargar archivo',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _descargarDocumento(context, doc),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd/MM/yy').format(doc.fechaSubida),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 4),
                        Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          _formatBytes(doc.tamanyoBytes),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                        if (doc.idCita != null) ...[
                          const Spacer(),
                          Text('#${doc.idCita}', style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── LISTA / TABLA DETALLADA DE DOCUMENTOS ──
  Widget _buildDetailedList(List<Documento> docs, {required bool isPapelera, String? emptyMsg}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMsg ?? (isPapelera ? 'La papelera está vacía' : 'No hay documentos registrados'),
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final tipo = doc.tipo;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () => _mostrarFichaDocumento(context, doc, isPapelera: isPapelera),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tipo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DocumentThumbnail(
                  doc: doc,
                  width: 44,
                  height: 44,
                  baseColor: tipo.color,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    doc.nombreOriginal,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (doc.etiqueta != null && doc.etiqueta!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      doc.etiqueta!,
                      style: TextStyle(color: Colors.purple.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (doc.idCita != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cita #${doc.idCita}',
                      style: TextStyle(color: Colors.teal.shade800, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text(
                    tipo.nombreLegible,
                    style: TextStyle(color: tipo.color, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(doc.fechaSubida),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Text(
                    _formatBytes(doc.tamanyoBytes),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (doc.notasMedicas != null && doc.notasMedicas!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.notasMedicas!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPapelera) ...[
                  IconButton(
                    icon: const Icon(Icons.restore_rounded, size: 20, color: Colors.green),
                    tooltip: 'Restaurar documento',
                    onPressed: () => _restaurarDocumento(context, doc),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blueGrey),
                    tooltip: 'Visualizar',
                    onPressed: () => _verDocumento(context, doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20, color: Colors.blueGrey),
                    tooltip: 'Descargar',
                    onPressed: () => _descargarDocumento(context, doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    tooltip: 'Eliminar a papelera',
                    onPressed: () => _confirmarEliminacion(context, doc),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 20, color: Colors.blueGrey),
                  tooltip: 'Detalles / Ficha',
                  onPressed: () => _mostrarFichaDocumento(context, doc, isPapelera: isPapelera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<DocumentosProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !_viendoPapelera) {
          return _buildSkeletonGrid();
        }

        if (provider.errorMessage != null && !_viendoPapelera) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.blueGrey, size: 64),
                const SizedBox(height: 16),
                Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.loadDocumentos(widget.cliente.idCliente),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        Widget content;

        if (_viendoPapelera) {
          if (_isLoadingPapelera) {
            content = const Center(child: CircularProgressIndicator());
          } else if (_errorPapelera != null) {
            content = Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorPapelera!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _cargarPapelera, child: const Text('Reintentar')),
                ],
              ),
            );
          } else {
            content = _isThumbnailGrid
                ? _buildThumbnailGrid(_papeleraDocs ?? [], isPapelera: true)
                : _buildDetailedList(_papeleraDocs ?? [], isPapelera: true);
          }
        } else {
          final mostrarCarpetas = provider.viewMode == DocumentViewMode.folders && provider.carpetaSeleccionada == null;

          if (mostrarCarpetas) {
            content = _buildCarpetasGrid(context, provider);
          } else {
            final docs = provider.documentosEnCarpetaActual;
            final emptyMsg = provider.carpetaSeleccionada != null
                ? 'No hay documentos en "${provider.carpetaSeleccionada!.nombreLegible}"'
                : 'No hay documentos registrados para este paciente';

            content = _isThumbnailGrid
                ? _buildThumbnailGrid(docs, isPapelera: false, emptyMsg: emptyMsg)
                : _buildDetailedList(docs, isPapelera: false, emptyMsg: emptyMsg);
          }
        }

        return Column(
          children: [
            _buildHeader(context, provider),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
