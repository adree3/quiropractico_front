class Pago {
  final int idPago;
  final int idCliente;
  final String nombreCliente;
  final String concepto;
  final double monto;
  final String metodoPago;
  final DateTime? fechaPago;
  final bool pagado;
  final String? cobradoPor;
  final bool anulado;
  final DateTime? fechaAnulacion;
  final String? motivoAnulacion;

  Pago({
    required this.idPago,
    required this.idCliente,
    required this.nombreCliente,
    required this.concepto,
    required this.monto,
    required this.metodoPago,
    this.fechaPago,
    required this.pagado,
    this.cobradoPor,
    this.anulado = false,
    this.fechaAnulacion,
    this.motivoAnulacion,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      idPago: json['idPago'],
      idCliente: json['idCliente'],
      nombreCliente: json['nombreCliente'] ?? 'Desconocido',
      concepto: json['concepto'] ?? '',
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : 0.0,
      metodoPago: json['metodoPago'] ?? '',
      fechaPago: json['fechaPago'] != null ? DateTime.tryParse(json['fechaPago']) : null,
      pagado: json['pagado'] ?? false,
      cobradoPor: json['cobradoPor'],
      anulado: json['anulado'] ?? false,
      fechaAnulacion: json['fechaAnulacion'] != null ? DateTime.tryParse(json['fechaAnulacion']) : null,
      motivoAnulacion: json['motivoAnulacion'],
    );
  }
}
