import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/pago.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  String _filtroSeleccionado = 'HOY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarFiltro('HOY');
    });
  }

  void _aplicarFiltro(String filtro) {
    setState(() => _filtroSeleccionado = filtro);
    
    final now = DateTime.now();
    DateTime inicio;
    DateTime fin = now;

    switch (filtro) {
      case 'SEMANA':
        inicio = now.subtract(Duration(days: now.weekday - 1));
        inicio = DateTime(inicio.year, inicio.month, inicio.day);
        break;
      case 'MES':
        inicio = DateTime(now.year, now.month, 1);
        fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'SIEMPRE':
        inicio = DateTime(2020); // CAMBIAR
        fin = DateTime(2100);
        break;

      case 'HOY':
      default:
        inicio = DateTime(now.year, now.month, now.day);
        fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    Provider.of<PaymentsProvider>(context, listen: false).loadData(inicio, fin);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final rol = authProvider.role ?? '';
    final esJefe = rol == 'admin' || rol == 'quiropráctico';

    final int cantidadVentas = provider.historial.where((p) => p.pagado).length;
    final int cantidadPendientes = provider.pendientes.length;
    String textoCobrado;
    String textoPendiente;

    if (esJefe) {
      textoCobrado = "${provider.totalCobrado.toStringAsFixed(2)} €\n($cantidadVentas ventas)";
      textoPendiente = "${provider.totalPendiente.toStringAsFixed(2)} €\n($cantidadPendientes pendientes)";
    } else {
      textoCobrado = "$cantidadVentas ventas";
      textoPendiente = "$cantidadPendientes pendientes";
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Pagos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Botones de Filtro
              Wrap(
                spacing: 10,
                children: [
                  _FilterChip(label: "Hoy", isSelected: _filtroSeleccionado == 'HOY', onTap: () => _aplicarFiltro('HOY')),
                  _FilterChip(label: "Esta Semana", isSelected: _filtroSeleccionado == 'SEMANA', onTap: () => _aplicarFiltro('SEMANA')),
                  _FilterChip(label: "Este Mes", isSelected: _filtroSeleccionado == 'MES', onTap: () => _aplicarFiltro('MES')),
                  _FilterChip(label: "Histórico Total", isSelected: _filtroSeleccionado == 'SIEMPRE', onTap: () => _aplicarFiltro('SIEMPRE')),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 20),

          // TARJETAS
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: esJefe ? "Total Cobrado" : "Ventas Realizadas",
                  valueText: textoCobrado,
                  color: Colors.green,
                  icon: Icons.attach_money,
                  isMoney: esJefe,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _KpiCard(
                  title: esJefe ? "Pendiente de Cobro" : "Bonos sin Confirmar",
                  valueText: textoPendiente,
                  color: Colors.orange,
                  icon: Icons.pending_actions,
                  isMoney: esJefe,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PESTAÑAS
          const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Historial de Movimientos", icon: Icon(Icons.list_alt)),
              Tab(text: "Pagos Pendientes (Deudas)", icon: Icon(Icons.warning_amber_rounded)),
            ],
          ),
          
          const SizedBox(height: 10),

          // LISTAS
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _PaymentsList(pagos: provider.historial, showActions: false),
                      
                      _PaymentsList(pagos: provider.pendientes, showActions: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// WIDGETS 
class _PaymentsList extends StatelessWidget {
  final List<Pago> pagos;
  final bool showActions;

  const _PaymentsList({required this.pagos, required this.showActions});

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return const Center(child: Text("No hay movimientos en este periodo", style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(5),
      itemCount: pagos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final pago = pagos[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: pago.pagado ? Colors.green.shade100 : Colors.orange.shade100,
            child: Icon(
              pago.pagado ? Icons.check : Icons.access_time, 
              color: pago.pagado ? Colors.green : Colors.orange
            ),
          ),
          title: Text(pago.nombreCliente, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${pago.concepto} • ${DateFormat('dd/MM HH:mm').format(pago.fechaPago)} • ${pago.metodoPago.toUpperCase()}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${pago.monto} €", 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16, 
                  color: pago.pagado ? Colors.black87 : Colors.orange
                )
              ),
              if (showActions && !pago.pagado) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    // Confirmar Pago
                    final String? error = await Provider.of<PaymentsProvider>(context, listen: false).confirmarPago(pago.idPago);
                      
                      if (context.mounted) {
                        if (error == null) {
                          CustomSnackBar.show(context, 
                            message: "Pago confirmado", 
                            type: SnackBarType.error
                          );
                        } else {
                          CustomSnackBar.show(context, 
                            message: error, 
                            type: SnackBarType.error
                          );
                        }
                      }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Confirmar"),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String valueText;
  final Color color;
  final IconData icon;
  final bool isMoney;

  const _KpiCard({required this.title, required this.valueText, required this.color, required this.icon, required this.isMoney});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    valueText, 
                    style: TextStyle(
                      fontSize: isMoney ? 22 : 24,
                      fontWeight: FontWeight.w900, 
                      color: color
                    )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      checkmarkColor: Colors.white,
    );
  }
}