class ApiError {
  final int status;
  final String? codigo;
  final String? mensaje;
  final String? detalles;

  ApiError({
    required this.status,
    this.codigo,
    this.mensaje,
    this.detalles,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      status: json['status'] ?? 500,
      codigo: json['codigo'],
      mensaje: json['mensaje'] ?? json['message'], // fallback a 'message'
      detalles: json['detalles'],
    );
  }

  String get displayMessage {
    final baseMsg = mensaje ?? 'Error inesperado de red';
    if (detalles != null && detalles!.isNotEmpty) {
      return "$baseMsg: $detalles";
    }
    return baseMsg;
  }
}