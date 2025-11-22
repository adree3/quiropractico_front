class Cliente {
  final int idCliente;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String? email;
  final String? direccion;
  // Podríamos añadir más campos, pero estos son los clave para la lista

  Cliente({
    required this.idCliente,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    this.email,
    this.direccion,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['idCliente'],
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      direccion: json['direccion'],
    );
  }
}