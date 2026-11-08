class ArqueoCajaDto {
  final double efectivo;
  final double tarjeta;
  final double transferencia;
  final double total;
  final int cantidadOperaciones;

  const ArqueoCajaDto({
    required this.efectivo,
    required this.tarjeta,
    required this.transferencia,
    required this.total,
    required this.cantidadOperaciones,
  });

  factory ArqueoCajaDto.fromJson(Map<String, dynamic> json) {
    return ArqueoCajaDto(
      efectivo: json['efectivo'] != null ? (json['efectivo'] as num).toDouble() : 0.0,
      tarjeta: json['tarjeta'] != null ? (json['tarjeta'] as num).toDouble() : 0.0,
      transferencia: json['transferencia'] != null ? (json['transferencia'] as num).toDouble() : 0.0,
      total: json['total'] != null ? (json['total'] as num).toDouble() : 0.0,
      cantidadOperaciones: json['cantidadOperaciones'] != null ? (json['cantidadOperaciones'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'efectivo': efectivo,
      'tarjeta': tarjeta,
      'transferencia': transferencia,
      'total': total,
      'cantidadOperaciones': cantidadOperaciones,
    };
  }
}
