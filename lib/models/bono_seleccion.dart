class BonoSeleccion {
  final int idBonoActivo;
  final String nombreServicio;
  final int sesionesRestantes;
  final String propietarioNombre;
  final bool esPropio;

  BonoSeleccion({required this.idBonoActivo, required this.nombreServicio, required this.sesionesRestantes, required this.propietarioNombre, required this.esPropio});

  factory BonoSeleccion.fromJson(Map<String, dynamic> json) {
    return BonoSeleccion(
      idBonoActivo: json['idBonoActivo'],
      nombreServicio: json['nombreServicio'],
      sesionesRestantes: json['sesionesRestantes'],
      propietarioNombre: json['propietarioNombre'],
      esPropio: json['esPropio'],
    );
  }
}