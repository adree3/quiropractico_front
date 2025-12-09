class CitaConflicto {
  final int idCita;
  final DateTime fecha;
  final String nombreBono;

  bool cancelar; 

  CitaConflicto({
    required this.idCita,
    required this.fecha,
    required this.nombreBono,
    this.cancelar = true, 
  });

  factory CitaConflicto.fromJson(Map<String, dynamic> json) {
    return CitaConflicto(
      idCita: json['idCita'],
      fecha: DateTime.parse(json['fecha']),
      nombreBono: json['nombreBonoOriginal'],
    );
  }
}