import 'package:quiropractico_front/models/bono.dart';

class BonoHistorico {
  final int idBonoActivo;
  final int idCliente;
  final String nombreCliente;
  final String nombreServicio;
  final int sesionesTotales;
  final int sesionesRestantes;
  final DateTime fechaCompra;
  final DateTime? fechaCaducidad;
  final bool pagado;
  final bool tieneProximaCita;
  final int? idPago;
  final double? monto;
  final String? metodoPago;

  BonoHistorico({
    required this.idBonoActivo,
    required this.idCliente,
    required this.nombreCliente,
    required this.nombreServicio,
    required this.sesionesTotales,
    required this.sesionesRestantes,
    required this.fechaCompra,
    this.fechaCaducidad,
    required this.pagado,
    this.tieneProximaCita = false,
    this.idPago,
    this.monto,
    this.metodoPago,
  });

  factory BonoHistorico.fromJson(Map<String, dynamic> json) {
    return BonoHistorico(
      idBonoActivo: json['idBonoActivo'] ?? 0,
      idCliente: json['idCliente'] ?? 0,
      nombreCliente: json['nombreCliente'] ?? '',
      nombreServicio: json['nombreServicio'] ?? '',
      sesionesTotales: json['sesionesTotales'] ?? 0,
      sesionesRestantes: json['sesionesRestantes'] ?? 0,
      fechaCompra: json['fechaCompra'] != null
          ? DateTime.parse(json['fechaCompra'])
          : DateTime.now(),
      fechaCaducidad: json['fechaCaducidad'] != null
          ? DateTime.parse(json['fechaCaducidad'])
          : null,
      pagado: json['pagado'] ?? false,
      tieneProximaCita: json['tieneProximaCita'] ?? false,
      idPago: json['idPago'],
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : null,
      metodoPago: json['metodoPago'],
    );
  }

  double get progreso =>
      sesionesTotales > 0 ? (sesionesTotales - sesionesRestantes) / sesionesTotales : 0;
  bool get agotado => sesionesRestantes <= 0;
  bool get caducado =>
      fechaCaducidad != null && fechaCaducidad!.isBefore(DateTime.now());

  Bono toBono() {
    return Bono(
      idBonoActivo: idBonoActivo,
      nombreServicio: nombreServicio,
      sesionesTotales: sesionesTotales,
      sesionesRestantes: sesionesRestantes,
      fechaCaducidad: fechaCaducidad,
      esPagado: pagado,
      fechaCompra: fechaCompra,
      tieneProximaCita: tieneProximaCita,
    );
  }

  BonoHistorico copyWith({
    int? idBonoActivo,
    int? idCliente,
    String? nombreCliente,
    String? nombreServicio,
    int? sesionesTotales,
    int? sesionesRestantes,
    DateTime? fechaCompra,
    DateTime? fechaCaducidad,
    bool? pagado,
    bool? tieneProximaCita,
    int? idPago,
    double? monto,
    String? metodoPago,
  }) {
    return BonoHistorico(
      idBonoActivo: idBonoActivo ?? this.idBonoActivo,
      idCliente: idCliente ?? this.idCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      nombreServicio: nombreServicio ?? this.nombreServicio,
      sesionesTotales: sesionesTotales ?? this.sesionesTotales,
      sesionesRestantes: sesionesRestantes ?? this.sesionesRestantes,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaCaducidad: fechaCaducidad ?? this.fechaCaducidad,
      pagado: pagado ?? this.pagado,
      tieneProximaCita: tieneProximaCita ?? this.tieneProximaCita,
      idPago: idPago ?? this.idPago,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }
}

