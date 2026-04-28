class ClinicaSearchResult {
  final int idClinica;
  final String nombre;
  final String direccion;

  ClinicaSearchResult({
    required this.idClinica, 
    required this.nombre,
    required this.direccion,
  });

  factory ClinicaSearchResult.fromJson(Map<String, dynamic> json) {
    print('Procesando Clinica JSON: $json');
    return ClinicaSearchResult(
      idClinica: json['id_clinica'] ?? json['idClinica'] ?? json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
    );
  }
}
