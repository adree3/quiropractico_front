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
  });

  factory BonoHistorico.fromJson(Map<String, dynamic> json) {
    return BonoHistorico(
      idBonoActivo: json['idBonoActivo'],
      idCliente: json['idCliente'],
      nombreCliente: json['nombreCliente'],
      nombreServicio: json['nombreServicio'],
      sesionesTotales: json['sesionesTotales'],
      sesionesRestantes: json['sesionesRestantes'],
      fechaCompra: DateTime.parse(json['fechaCompra']),
      fechaCaducidad: json['fechaCaducidad'] != null ? DateTime.parse(json['fechaCaducidad']) : null,
      pagado: json['pagado'] ?? false,
    );
  }

  double get progreso => sesionesTotales > 0 ? (sesionesTotales - sesionesRestantes) / sesionesTotales : 0;
  bool get agotado => sesionesRestantes <= 0;
  bool get caducado => fechaCaducidad != null && fechaCaducidad!.isBefore(DateTime.now());
}
