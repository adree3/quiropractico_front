import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/dashboard_stats.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/stats_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.role ?? "quiropráctico";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SALUDO
        Text(
          'Hola, $user 👋', 
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 5),
        Text(
          'Aquí tienes el resumen de tu clínica hoy.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: statsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : statsProvider.stats == null
                  ? const Center(child: Text("Error"))
                  : SingleChildScrollView(
                      child: Column( // Usamos Column para poner Gráfica debajo de Cards
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TARJETAS DE RESUMEN (Wrap)
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                               // ... (Tus tarjetas _StatCard existentes) ...
                               // Copia aquí tus _StatCard de Ingresos, Citas, etc.
                            ],
                          ),

                          const SizedBox(height: 30),

                          // 2. GRÁFICA DE INGRESOS (NUEVO)
                          // Usamos LayoutBuilder para que no se rompa si la pantalla es pequeña
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SizedBox(
                                width: double.infinity, // Ocupa todo el ancho
                                child: _IncomeChart(data: statsProvider.stats!.graficaIngresos),
                              );
                            }
                          ),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
        ),
        // GRID DE TARJETAS
        Expanded(
          child: statsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : statsProvider.stats == null
                  ? const Center(child: Text("No se pudieron cargar los datos"))
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // FINANZAS 
                          _StatCard(
                            title: "Ingresos Hoy",
                            value: "${statsProvider.stats!.ingresosHoy} €",
                            icon: Icons.attach_money,
                            color: Colors.green,
                            width: 300,
                          ),
                          _StatCard(
                            title: "Ingresos este Mes",
                            value: "${statsProvider.stats!.ingresosMes} €",
                            icon: Icons.calendar_month,
                            color: Colors.teal,
                            width: 300,
                          ),

                          // OPERACIONES 
                          _StatCard(
                            title: "Citas Hoy",
                            value: "${statsProvider.stats!.citasHoyTotal}",
                            subValue: "${statsProvider.stats!.citasHoyPendientes} pendientes",
                            icon: Icons.event_available,
                            color: Colors.blue,
                            width: 300,
                          ),

                          // CRECIMIENTO 
                          _StatCard(
                            title: "Nuevos Pacientes (Mes)",
                            value: "+${statsProvider.stats!.nuevosClientesMes}",
                            icon: Icons.person_add,
                            color: Colors.purple,
                            width: 300,
                          ),
                          _StatCard(
                            title: "Total Pacientes Activos",
                            value: "${statsProvider.stats!.totalClientesActivos}",
                            icon: Icons.groups,
                            color: Colors.orange,
                            width: 300,
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

// TARJETA REUTILIZABLE
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    this.subValue,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 20),
          
          // Valor Grande
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          
          // Título
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),

          // Subvalor opcional
          if (subValue != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(5)
              ),
              child: Text(subValue!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            )
          ]
        ],
      ),
    );
  }
}
class _IncomeChart extends StatelessWidget {
  final List<ChartData> data;

  const _IncomeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Evolución de Ingresos (7 días)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250, // Altura de la gráfica
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 1, color: Colors.grey.shade200, dashArray: <double>[5, 5]),
                axisLine: const AxisLine(width: 0),
                numberFormat: NumberFormat.compactCurrency(symbol: '€'),
              ),
              tooltipBehavior: TooltipBehavior(enable: true, header: '', format: 'point.y€'),
              series: <CartesianSeries>[
                SplineAreaSeries<ChartData, String>(
                  dataSource: data,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.value,
                  // DISEÑO ELEGANTE
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.4), AppTheme.primaryColor.withOpacity(0.01)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: AppTheme.primaryColor,
                  borderWidth: 3,
                  markerSettings: const MarkerSettings(isVisible: true, height: 8, width: 8), // Puntitos
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}