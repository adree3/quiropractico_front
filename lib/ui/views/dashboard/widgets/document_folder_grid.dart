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
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320, // Celda mucho más ancha para evitar overflow de texto
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.35, // Las tarjetas serán más anchas que altas (Formato sobre)
      ),
      itemCount: systemFolders.length,
      itemBuilder: (context, index) {
        final carpeta = systemFolders[index];
        // Distribución inteligente de los documentos a cada carpeta mediante matches()
        final docsEnCarpeta = documentos.where((d) => carpeta.matches(d, systemFolders)).toList();

        return _FolderCard(
          carpeta: carpeta,
          count: docsEnCarpeta.length,
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
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  final CarpetaLogica carpeta;
  final int count;
  final VoidCallback onTap;

  const _FolderCard({required this.carpeta, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: carpeta.color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: carpeta.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(carpeta.icon, size: 36, color: carpeta.color),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: carpeta.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(color: carpeta.color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              carpeta.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '$count ${count == 1 ? "archivo" : "archivos"} guardados',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
