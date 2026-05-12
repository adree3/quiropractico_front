import 'dart:math';

/// Utilidades de formateo para la aplicación.
class FormatUtils {
  /// Convierte una cantidad de bytes en un formato legible (KB, MB, GB, etc.)
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    
    // Asegurarse de no exceder los sufijos definidos
    if (i >= suffixes.length) i = suffixes.length - 1;
    
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }
}
