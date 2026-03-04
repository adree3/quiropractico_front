class Usuario {
  final int idUsuario;
  final String nombreCompleto;
  final String username;
  final String rol;
  final bool activo;
  final bool cuentaBloqueada;
  final DateTime? ultimaConexion;

  Usuario({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.username,
    required this.rol,
    required this.activo,
    required this.cuentaBloqueada,
    this.ultimaConexion,
  });

  Usuario copyWith({
    int? idUsuario,
    String? nombreCompleto,
    String? username,
    String? rol,
    bool? activo,
    bool? cuentaBloqueada,
    DateTime? ultimaConexion,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      username: username ?? this.username,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      cuentaBloqueada: cuentaBloqueada ?? this.cuentaBloqueada,
      ultimaConexion: ultimaConexion ?? this.ultimaConexion,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario'],
      nombreCompleto: json['nombreCompleto'],
      username: json['username'],
      rol: json['rol'] ?? 'recepción',
      activo: (json['activo'] == 1 || json['activo'] == true),
      cuentaBloqueada:
          (json['cuentaBloqueada'] == 1 || json['cuentaBloqueada'] == true),
      ultimaConexion:
          json['ultimaConexion'] != null
              ? DateTime.tryParse(json['ultimaConexion'].toString())
              : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.idUsuario == idUsuario;
  }

  @override
  int get hashCode => idUsuario.hashCode;
}
