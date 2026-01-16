class Servicio {
  final int idServicio;
  final String nombreServicio;
  final double precio;
  final int? sesiones;
  final bool activo;
  final String tipo;

  Servicio({
    required this.idServicio,
    required this.nombreServicio,
    required this.precio,
    this.sesiones,
    required this.activo,
    required this.tipo,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      idServicio: json['idServicio'],
      nombreServicio: json['nombreServicio'],
      precio: (json['precio'] as num).toDouble(),
      sesiones: json['sesionesIncluidas'],
      activo: json['activo'] ?? true,
      tipo: json['tipo'] ?? 'sesion_unica',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Servicio && other.idServicio == idServicio;
  }

  @override
  int get hashCode => idServicio.hashCode;

  @override
  String toString() => nombreServicio;

  Servicio copyWith({
    int? idServicio,
    String? nombreServicio,
    double? precio,
    int? sesiones,
    bool? activo,
    String? tipo,
  }) {
    return Servicio(
      idServicio: idServicio ?? this.idServicio,
      nombreServicio: nombreServicio ?? this.nombreServicio,
      precio: precio ?? this.precio,
      sesiones: sesiones ?? this.sesiones,
      activo: activo ?? this.activo,
      tipo: tipo ?? this.tipo,
    );
  }
}
