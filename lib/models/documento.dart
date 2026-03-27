class Documento {
  final int idDocumento;
  final int? idCliente;
  final int? idCita;
  final String? notasMedicas;
  final String nombreOriginal;
  final String tipoDocumento;
  final String? mimeType;
  final String estadoSubida;
  final int tamanyoBytes;
  final DateTime fechaSubida;

  Documento({
    required this.idDocumento,
    this.idCliente,
    this.idCita,
    this.notasMedicas,
    required this.nombreOriginal,
    required this.tipoDocumento,
    this.mimeType,
    required this.estadoSubida,
    required this.tamanyoBytes,
    required this.fechaSubida,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      idDocumento: json['idDocumento'] ?? 0,
      idCliente: json['idCliente'],
      idCita: json['idCita'],
      notasMedicas: json['notasMedicas'],
      nombreOriginal: json['nombreOriginal'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? 'OTRO',
      mimeType: json['mimeType'],
      estadoSubida: json['estadoSubida'] ?? 'PENDIENTE',
      tamanyoBytes: json['tamanyoBytes'] ?? 0,
      fechaSubida: json['fechaSubida'] != null
          ? DateTime.parse(json['fechaSubida'])
          : DateTime.now(),
    );
  }
}
