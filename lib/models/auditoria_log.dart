class AuditoriaLog {
  final int idAuditoria;
  final DateTime fechaHora;
  final String? usernameResponsable;
  final String accion;
  final String entidad;
  final String idEntidad;
  final String? detalles;

  AuditoriaLog({
    required this.idAuditoria,
    required this.fechaHora,
    this.usernameResponsable,
    required this.accion,
    required this.entidad,
    required this.idEntidad,
    this.detalles,
  });

  factory AuditoriaLog.fromJson(Map<String, dynamic> json) {
    return AuditoriaLog(
      idAuditoria: json['idAuditoria'],
      fechaHora: DateTime.parse(json['fechaHora']),
      usernameResponsable: json['usernameResponsable'], 
      accion: json['accion'],
      entidad: json['entidad'],
      idEntidad: json['idEntidad'] ?? '',
      detalles: json['detalles'],
    );
  }
}