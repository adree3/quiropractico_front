class Familiar {
  final int idGrupo;
  final int idFamiliar;
  final String nombreCompleto;
  final String relacion;

  Familiar({
    required this.idGrupo,
    required this.idFamiliar,
    required this.nombreCompleto,
    required this.relacion,
  });

  factory Familiar.fromJson(Map<String, dynamic> json) {
    return Familiar(
      idGrupo: json['idGrupo'],
      idFamiliar: json['idFamiliar'],
      nombreCompleto: json['nombreCompleto'] ?? 'Sin Nombre',
      relacion: json['relacion'] ?? 'Familiar',
    );
  }
}