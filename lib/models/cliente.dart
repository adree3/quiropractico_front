import 'package:quiropractico_front/models/cita.dart';

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

  // Nuevos campos calculados
  final int citasCompletadas;
  final int citasCanceladas;
  final int citasAusentes;
  final double deudaPendiente;
  final int pagosPendientesCount;
  final Cita? proximaCita;

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
    this.citasCompletadas = 0,
    this.citasCanceladas = 0,
    this.citasAusentes = 0,
    this.deudaPendiente = 0.0,
    this.pagosPendientesCount = 0,
    this.proximaCita,
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
      citasCompletadas: json['citasCompletadas'] ?? 0,
      citasCanceladas: json['citasCanceladas'] ?? 0,
      citasAusentes: json['citasAusentes'] ?? 0,
      deudaPendiente: (json['deudaPendiente'] ?? 0.0).toDouble(),
      pagosPendientesCount: json['pagosPendientesCount'] ?? 0,
      proximaCita: json['proximaCita'] != null ? Cita.fromJson(json['proximaCita']) : null,
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
    int? citasCompletadas,
    int? citasCanceladas,
    int? citasAusentes,
    double? deudaPendiente,
    int? pagosPendientesCount,
    Cita? proximaCita,
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
      citasCompletadas: citasCompletadas ?? this.citasCompletadas,
      citasCanceladas: citasCanceladas ?? this.citasCanceladas,
      citasAusentes: citasAusentes ?? this.citasAusentes,
      deudaPendiente: deudaPendiente ?? this.deudaPendiente,
      pagosPendientesCount: pagosPendientesCount ?? this.pagosPendientesCount,
      proximaCita: proximaCita ?? this.proximaCita,
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
      'citasCompletadas': citasCompletadas,
      'citasCanceladas': citasCanceladas,
      'citasAusentes': citasAusentes,
      'deudaPendiente': deudaPendiente,
      'pagosPendientesCount': pagosPendientesCount,
      'proximaCita': proximaCita?.toJson(),
    };
  }
}
