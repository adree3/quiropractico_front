import 'dart:html' as html;

class DownloadHelper {
  /// Descarga el archivo de forma Zero-Copy.
  /// Al ser una URL prefirmada con 'content-disposition', el navegador gestiona
  /// la descarga directamente sin necesidad de cargar los bytes en la memoria del JS.
  static Future<void> downloadFile(String url, String fileName) async {
    try {
      // Zero-Copy: Usamos un ancla directa. Cloudflare R2 ya devuelve los 
      // headers correctos de descarga porque los incluimos en la firma (Backend).
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
    } catch (e) {
      print("Error en descarga Zero-Copy: $e");
    }
  }

  /// Abre el archivo en una pestaña nueva (Zero-Copy)
  static Future<void> viewFile(String url) async {
    try {
      // Zero-Copy: Abrimos la URL prefirmada en una nueva pestaña.
      // El navegador se encarga de renderizar el PDF o la imagen de forma nativa.
      html.window.open(url, '_blank');
    } catch (e) {
      print("Error en visualización Zero-Copy: $e");
    }
  }
}
