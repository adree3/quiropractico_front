import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class DocumentThumbnail extends StatelessWidget {
  final Documento doc;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color baseColor;

  const DocumentThumbnail({
    super.key,
    required this.doc,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.baseColor = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    final mime = doc.mimeType ?? '';
    final isImage = mime.contains('image');
    
    // Icono de representación según el tipo si no es imagen o falla
    IconData repIcon = Icons.insert_drive_file_rounded;
    if (mime.contains('pdf')) {
      repIcon = Icons.picture_as_pdf_rounded;
    } else if (isImage) {
      repIcon = Icons.image_rounded;
    }

    if (!isImage) {
      double iconSize = (width != null && width!.isFinite) ? width! * 0.8 : 48.0;
      return Center(
        child: Icon(repIcon, size: iconSize, color: baseColor.withOpacity(0.75)),
      );
    }

    final token = LocalStorage.prefs.getString('token') ?? '';
    final thumbUrl = '${ApiConfig.baseUrl}/documentos/${doc.idDocumento}/thumbnail?token=$token';

    double placeholderSize = (width != null && width!.isFinite) ? width! * 0.6 : 48.0;

    return CachedNetworkImage(
      imageUrl: thumbUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Center(
        child: Icon(repIcon, size: placeholderSize, color: baseColor.withOpacity(0.3)),
      ),
      errorWidget: (context, url, error) => Center(
        child: Icon(Icons.broken_image_rounded, size: placeholderSize, color: Colors.red.withOpacity(0.3)),
      ),
    );
  }
}
