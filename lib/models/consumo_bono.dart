class ConsumoBono {
  final int idConsumo;
  final DateTime fechaConsumo;
  final int sesionesRestantesSnapshot;
  final int? idCita;
  final int? idPaciente;
  final DateTime? fechaCita;
  final String? nombreQuiropractico;
  final String? nombrePaciente;
  final String? estadoCita;

  ConsumoBono({
    required this.idConsumo,
    required this.fechaConsumo,
    required this.sesionesRestantesSnapshot,
    this.idCita,
    this.idPaciente,
    this.fechaCita,
    this.nombreQuiropractico,
    this.nombrePaciente,
    this.estadoCita,
  });

  factory ConsumoBono.fromJson(Map<String, dynamic> json) {
    return ConsumoBono(
      idConsumo: json['idConsumo'],
      fechaConsumo: DateTime.parse(json['fechaConsumo']),
      sesionesRestantesSnapshot: json['sesionesRestantesSnapshot'],
      idCita: json['idCita'],
      idPaciente: json['idPaciente'],
      fechaCita:
          json['fechaCita'] != null ? DateTime.parse(json['fechaCita']) : null,
      nombreQuiropractico: json['nombreQuiropractico'],
      nombrePaciente: json['nombrePaciente'],
      estadoCita: json['estadoCita'],
    );
  }
}
