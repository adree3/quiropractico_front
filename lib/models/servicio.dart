class Servicio {
  final int idServicio;
  final String nombreServicio;
  final double precio;
  final int? sesiones;

  Servicio({
    required this.idServicio,
    required this.nombreServicio,
    required this.precio,
    this.sesiones,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      idServicio: json['idServicio'],
      nombreServicio: json['nombreServicio'],
      precio: (json['precio'] as num).toDouble(),
      sesiones: json['sesionesIncluidas'],
    );
  }
}