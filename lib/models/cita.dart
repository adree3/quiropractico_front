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
  final String infoPago;
  final int? idBonoCliente;
  final bool firmada;
  final String? rutaJustificante;

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
    required this.infoPago,
    this.idBonoCliente,
    this.firmada = false,
    this.rutaJustificante,
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
      infoPago: json['infoPago'] ?? 'Desconocido',
      idBonoCliente: json['idBonoCliente'],
      firmada: json['firmada'] ?? false,
      rutaJustificante: json['rutaJustificante'],
    );
  }

  Cita copyWith({
    int? idCita,
    int? idCliente,
    String? nombreClienteCompleto,
    String? telefonoCliente,
    int? idQuiropractico,
    String? nombreQuiropractico,
    DateTime? fechaHoraInicio,
    DateTime? fechaHoraFin,
    String? estado,
    String? notas,
    String? infoPago,
    int? idBonoCliente,
    bool? firmada,
    String? rutaJustificante,
  }) {
    return Cita(
      idCita: idCita ?? this.idCita,
      idCliente: idCliente ?? this.idCliente,
      nombreClienteCompleto: nombreClienteCompleto ?? this.nombreClienteCompleto,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      idQuiropractico: idQuiropractico ?? this.idQuiropractico,
      nombreQuiropractico: nombreQuiropractico ?? this.nombreQuiropractico,
      fechaHoraInicio: fechaHoraInicio ?? this.fechaHoraInicio,
      fechaHoraFin: fechaHoraFin ?? this.fechaHoraFin,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      infoPago: infoPago ?? this.infoPago,
      idBonoCliente: idBonoCliente ?? this.idBonoCliente,
      firmada: firmada ?? this.firmada,
      rutaJustificante: rutaJustificante ?? this.rutaJustificante,
    );
  }
}
