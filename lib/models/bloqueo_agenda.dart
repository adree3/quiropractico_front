class BloqueoAgenda {
  final int idBloqueo;
  final int? idQuiropractico;
  final String nombreQuiropractico;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;

  BloqueoAgenda({
    required this.idBloqueo,
    this.idQuiropractico,
    required this.nombreQuiropractico,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
  });

  factory BloqueoAgenda.fromJson(Map<String, dynamic> json) {
    return BloqueoAgenda(
      idBloqueo: json['idBloqueo'],
      idQuiropractico: json['idQuiropractico'],
      nombreQuiropractico: json['nombreQuiropractico'] ?? 'TODA LA CLÍNICA',
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      motivo: json['motivo'] ?? 'No especificado',
    );
  }
}