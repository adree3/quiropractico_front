class Pago {
  final int idPago;
  final String nombreCliente;
  final String concepto;
  final double monto;
  final String metodoPago;
  final DateTime fechaPago;
  final bool pagado;

  Pago({required this.idPago, required this.nombreCliente, required this.concepto, required this.monto, required this.metodoPago, required this.fechaPago, required this.pagado});

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      idPago: json['idPago'],
      nombreCliente: json['nombreCliente'],
      concepto: json['concepto'],
      monto: (json['monto'] as num).toDouble(),
      metodoPago: json['metodoPago'],
      fechaPago: DateTime.parse(json['fechaPago']),
      pagado: json['pagado'],
    );
  }
}