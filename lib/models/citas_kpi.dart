class CitasKpi {
  final int total;
  final int programadas;
  final int completadas;
  final int canceladas;
  final int ausentes;

  CitasKpi({
    required this.total,
    required this.programadas,
    required this.completadas,
    required this.canceladas,
    required this.ausentes,
  });

  factory CitasKpi.fromJson(Map<String, dynamic> json) {
    return CitasKpi(
      total: json['total'] ?? 0,
      programadas: json['programadas'] ?? 0,
      completadas: json['completadas'] ?? 0,
      canceladas: json['canceladas'] ?? 0,
      ausentes: json['ausentes'] ?? 0,
    );
  }
}
