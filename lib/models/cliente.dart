class Cliente {
  final int idCliente;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String? email;
  final String? direccion;
  final bool activo;

  // Campos extendidos para vista de lista
  final int? citasPendientes;
  final int? bonosActivos;
  final bool tieneFamiliares;
  final DateTime? ultimaCita;

  Cliente({
    required this.idCliente,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    this.email,
    this.direccion,
    this.activo = true,
    this.citasPendientes,
    this.bonosActivos,
    this.tieneFamiliares = false,
    this.ultimaCita,
  });
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['idCliente'],
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      direccion: json['direccion'],
      activo: json['activo'] ?? true,
      citasPendientes: json['citasPendientes'],
      bonosActivos: json['bonosActivos'],
      tieneFamiliares: json['tieneFamiliares'] ?? false,
      ultimaCita:
          json['ultimaCita'] != null
              ? DateTime.parse(json['ultimaCita'])
              : null,
    );
  }

  Cliente copyWith({
    int? idCliente,
    String? nombre,
    String? apellidos,
    String? telefono,
    String? email,
    String? direccion,
    bool? activo,
    int? citasPendientes,
    int? bonosActivos,
    bool? tieneFamiliares,
    DateTime? ultimaCita,
  }) {
    return Cliente(
      idCliente: idCliente ?? this.idCliente,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
      citasPendientes: citasPendientes ?? this.citasPendientes,
      bonosActivos: bonosActivos ?? this.bonosActivos,
      tieneFamiliares: tieneFamiliares ?? this.tieneFamiliares,
      ultimaCita: ultimaCita ?? this.ultimaCita,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCliente': idCliente,
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'activo': activo,
      'citasPendientes': citasPendientes,
      'bonosActivos': bonosActivos,
      'tieneFamiliares': tieneFamiliares,
      'ultimaCita': ultimaCita?.toIso8601String(),
    };
  }
}
