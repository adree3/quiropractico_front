class Usuario {
  final int idUsuario;
  final String nombreCompleto;
  final String username;

  Usuario({required this.idUsuario, required this.nombreCompleto, required this.username});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario'],
      nombreCompleto: json['nombreCompleto'],
      username: json['username'],
    );
  }
}