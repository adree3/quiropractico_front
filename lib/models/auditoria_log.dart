class AuditoriaLog {
  final int idAuditoria;
  final DateTime fechaHora;
  final int? idUsuarioResponsable;
  final String? usernameResponsable;
  final String accion;
  final String entidad;
  final String idEntidad;
  final String? resumen;
  final String? detalles;

  AuditoriaLog({
    required this.idAuditoria,
    required this.fechaHora,
    this.idUsuarioResponsable,
    this.usernameResponsable,
    required this.accion,
    required this.entidad,
    required this.idEntidad,
    this.resumen,
    this.detalles,
  });

  factory AuditoriaLog.fromJson(Map<String, dynamic> json) {
    return AuditoriaLog(
      idAuditoria: json['idAuditoria'],
      fechaHora: DateTime.parse(json['fechaHora']),
      idUsuarioResponsable: json['idUsuarioResponsable'],
      usernameResponsable: json['usernameResponsable'],
      accion: json['accion'],
      entidad: json['entidad'],
      idEntidad: json['idEntidad'] ?? '',
      resumen: json['resumen'],
      detalles: json['detalles'],
    );
  }
}