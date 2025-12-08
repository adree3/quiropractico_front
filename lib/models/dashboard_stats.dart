class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}
class DashboardStats {
  final double ingresosHoy;
  final double ingresosMes;
  final int citasHoyTotal;
  final int citasHoyPendientes;
  final int nuevosClientesMes;
  final int totalClientesActivos;
  final List<ChartData> graficaIngresos;

  DashboardStats({
    required this.ingresosHoy,
    required this.ingresosMes,
    required this.citasHoyTotal,
    required this.citasHoyPendientes,
    required this.nuevosClientesMes,
    required this.totalClientesActivos,
    required this.graficaIngresos,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    var list = json['graficaIngresos'] as List? ?? [];
    List<ChartData> chartDataList = list.map((i) => ChartData(i['label'], i['value'])).toList();
    return DashboardStats(
      ingresosHoy: (json['ingresosHoy'] as num?)?.toDouble() ?? 0.0,
      ingresosMes: (json['ingresosMes'] as num?)?.toDouble() ?? 0.0,
      citasHoyTotal: json['citasHoyTotal'] ?? 0,
      citasHoyPendientes: json['citasHoyPendientes'] ?? 0,
      nuevosClientesMes: json['nuevosClientesMes'] ?? 0,
      totalClientesActivos: json['totalClientesActivos'] ?? 0,
      graficaIngresos: chartDataList,
    );
  }
}