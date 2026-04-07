import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_explorer_view.dart';

// ─── Definición de las carpetas abstractas
class CarpetaLogica {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> tiposIncluidos;
  final bool excludeFotoPerfil;

  CarpetaLogica(this.id, this.title, this.icon, this.color, this.tiposIncluidos, {this.excludeFotoPerfil = false});

  bool matches(Documento d, List<CarpetaLogica> allFolders) {
    if (excludeFotoPerfil && d.tipoDocumento == 'FOTO_PERFIL') return false;
    if (id == 'otros') {
      bool isHandled = false;
      for (var f in allFolders) {
        if (f.id != 'otros' && f.tiposIncluidos.contains(d.tipoDocumento)) isHandled = true;
      }
      return !isHandled;
    }
    return tiposIncluidos.contains(d.tipoDocumento);
  }
}

final List<CarpetaLogica> systemFolders = [
  CarpetaLogica('imagenes', 'Imágenes Médicas', Icons.image_rounded, Colors.purple, ['RADIOGRAFIA', 'RESONANCIA']),
  CarpetaLogica('firmas', 'Citas Firmadas', Icons.draw_rounded, Colors.teal, ['JUSTIFICANTE_ASISTENCIA']),
  CarpetaLogica('consentimientos', 'Consentimientos', Icons.gavel_rounded, Colors.orange, ['CONSENTIMIENTO_LOPD', 'CONSENTIMIENTO_TRATAMIENTO']),
  CarpetaLogica('informes', 'Informes Clínicos', Icons.medical_information_rounded, Colors.blue, ['INFORME_MEDICO']),
  CarpetaLogica('facturacion', 'Facturación', Icons.euro_rounded, Colors.green, ['JUSTIFICANTE_PAGO']),
  CarpetaLogica('otros', 'Otros Archivos', Icons.folder_copy_rounded, Colors.blueGrey, ['OTRO'], excludeFotoPerfil: true),
];

class DocumentFolderGrid extends StatelessWidget {
  final Cliente cliente;
  final List<Documento> documentos;

  const DocumentFolderGrid({super.key, required this.cliente, required this.documentos});

  @override
  Widget build(BuildContext context) {
    final mainFolders = List<CarpetaLogica>.from(systemFolders);
    mainFolders.add(CarpetaLogica('papelera', 'Papelera', Icons.delete_outline, Colors.grey, []));

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemCount: mainFolders.length,
      itemBuilder: (context, index) {
        final carpeta = mainFolders[index];
        final isPapelera = carpeta.id == 'papelera';
        // Distribución inteligente de los documentos a cada carpeta mediante matches()
        final docsEnCarpeta = isPapelera ? <Documento>[] : documentos.where((d) => carpeta.matches(d, systemFolders)).toList();

        // Animación de entrada escalonada: cada carpeta aparece ligeramente tras la anterior
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 260 + index * 55),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _FolderCard(
            carpeta: carpeta,
            count: isPapelera ? -1 : docsEnCarpeta.length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentExplorerView(
                    cliente: cliente,
                    carpeta: carpeta,
                    documentos: docsEnCarpeta,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FolderCard extends StatefulWidget {
  final CarpetaLogica carpeta;
  final int count;
  final VoidCallback onTap;

  const _FolderCard({required this.carpeta, required this.count, required this.onTap});

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering
                  ? widget.carpeta.color.withOpacity(0.35)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.carpeta.color.withOpacity(_hovering ? 0.18 : 0.06),
                blurRadius: _hovering ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: widget.carpeta.color.withOpacity(_hovering ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.carpeta.icon, size: 36, color: widget.carpeta.color),
                      ),
                      if (widget.count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.carpeta.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.count.toString(),
                            style: TextStyle(color: widget.carpeta.color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.carpeta.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.count == -1
                        ? 'Archivos eliminados'
                        : '${widget.count} ${widget.count == 1 ? "archivo" : "archivos"} guardados',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
