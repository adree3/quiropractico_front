class Bono {
  final int idBonoActivo;
  final String nombreServicio;
  final int sesionesTotales;
  final int sesionesRestantes;
  final DateTime? fechaCaducidad;
  final bool esPagado;
  final DateTime fechaCompra;

  Bono({
    required this.idBonoActivo,
    required this.nombreServicio,
    required this.sesionesTotales,
    required this.sesionesRestantes,
    this.fechaCaducidad,
    this.esPagado = true,
    required this.fechaCompra,
  });

  factory Bono.fromJson(Map<String, dynamic> json) {
    return Bono(
      idBonoActivo: json['idBonoActivo'],
      nombreServicio: json['nombreServicio'] ?? 'Bono Desconocido',
      sesionesTotales: json['sesionesTotales'] ?? 0,
      sesionesRestantes: json['sesionesRestantes'] ?? 0,
      fechaCaducidad:
          json['fechaCaducidad'] != null
              ? DateTime.tryParse(json['fechaCaducidad'])
              : null,
      esPagado: json['esPagado'] ?? true,
      fechaCompra:
          json['fechaCompra'] != null
              ? DateTime.parse(json['fechaCompra'])
              : DateTime.now(), // Fallback
    );
  }
}
