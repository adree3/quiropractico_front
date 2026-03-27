import 'dart:html' as html;

class DownloadHelper {
  /// Descarga el archivo sin abrir pestaña nueva usando un iframe oculto
  static void downloadFile(String url, String fileName) {
    // Creamos un iframe temporal e invisible que navega a la URL de descarga.
    // El servidor responde con Content-Disposition: attachment, lo que hace
    // que el navegador guarde el archivo sin abrir ninguna nueva ventana/pestaña.
    final iframe = html.IFrameElement()
      ..src = url
      ..style.display = 'none';
    html.document.body!.append(iframe);
    // Limpiamos el iframe después de que la descarga haya comenzado
    Future.delayed(const Duration(seconds: 5), () => iframe.remove());
  }

  /// Abre el archivo en una pestaña nueva (Visualización)
  static void viewFile(String url) {
    html.window.open(url, '_blank');
  }
}
