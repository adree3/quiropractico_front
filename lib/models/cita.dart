class Cita {
  final int idCita;
  final int idCliente;
  final String nombreClienteCompleto;
  final String telefonoCliente;
  final int idQuiropractico;
  final String nombreQuiropractico;
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final String estado;
  final String? notas;

  Cita({
    required this.idCita,
    required this.idCliente,
    required this.nombreClienteCompleto,
    required this.telefonoCliente,
    required this.idQuiropractico,
    required this.nombreQuiropractico,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.estado,
    this.notas,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      idCita: json['idCita'],
      idCliente: json['idCliente'],
      nombreClienteCompleto: json['nombreClienteCompleto'] ?? 'Desconocido',
      telefonoCliente: json['telefonoCliente'] ?? '-',
      idQuiropractico: json['idQuiropractico'],
      nombreQuiropractico: json['nombreQuiropractico'] ?? 'Dr.',
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio']),
      fechaHoraFin: DateTime.parse(json['fechaHoraFin']),
      estado: json['estado'],
      notas: json['notasRecepcion'],
    );
  }
}