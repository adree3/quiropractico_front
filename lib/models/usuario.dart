class Usuario {
  final int idUsuario;
  final String nombreCompleto;
  final String username;
  final String rol;   
  final bool activo;

  Usuario({
    required this.idUsuario, 
    required this.nombreCompleto, 
    required this.username,
    required this.rol,
    required this.activo,
  });
  
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario'],
      nombreCompleto: json['nombreCompleto'],
      username: json['username'],
      rol: json['rol'] ?? 'recepción',
      activo: json['activo'] ?? true,
    );
  }
}