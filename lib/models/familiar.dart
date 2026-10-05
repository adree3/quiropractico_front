class Familiar {
  final int idGrupo;
  final int idFamiliar;
  final String nombreCompleto;
  final String relacion;
  final String? telefono;
  final String? email;
  final bool activo;

  Familiar({
    required this.idGrupo,
    required this.idFamiliar,
    required this.nombreCompleto,
    required this.relacion,
    this.telefono,
    this.email,
    this.activo = true,
  });

  factory Familiar.fromJson(Map<String, dynamic> json) {
    return Familiar(
      idGrupo: json['idGrupo'],
      idFamiliar: json['idFamiliar'],
      nombreCompleto: json['nombreCompleto'] ?? 'Sin Nombre',
      relacion: json['relacion'] ?? 'Familiar',
      telefono: json['telefono'],
      email: json['email'],
      activo: json['activo'] ?? true,
    );
  }
}