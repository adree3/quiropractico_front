class Usuario {
  final int idUsuario;
  final String nombreCompleto;
  final String username;
  final String rol;
  final bool activo;
  final bool cuentaBloqueada;

  Usuario({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.username,
    required this.rol,
    required this.activo,
    required this.cuentaBloqueada,
  });

  Usuario copyWith({
    int? idUsuario,
    String? nombreCompleto,
    String? username,
    String? rol,
    bool? activo,
    bool? cuentaBloqueada,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      username: username ?? this.username,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      cuentaBloqueada: cuentaBloqueada ?? this.cuentaBloqueada,
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
