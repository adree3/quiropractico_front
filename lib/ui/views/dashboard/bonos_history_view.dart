import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
import 'package:quiropractico_front/providers/bonos_provider.dart';
import 'package:intl/intl.dart';

class BonosHistoryView extends StatefulWidget {
  const BonosHistoryView({super.key});

  @override
  State<BonosHistoryView> createState() => _BonosHistoryViewState();
}

class _BonosHistoryViewState extends State<BonosHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BonosProvider>(context, listen: false).getHistorial(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Provider.of<BonosProvider>(context, listen: false).getHistorial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bonosProvider = Provider.of<BonosProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Historial de Bonos",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (val) => bonosProvider.onSearchChanged(val),
                decoration: InputDecoration(
                  hintText: "Buscar por cliente o servicio...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // TOTAL COUNT CHIP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${bonosProvider.totalElements} bonos registrados",
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // TABLE
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: _buildTable(bonosProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BonosProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.bonos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No se han encontrado registros."),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(0),
      itemCount: provider.bonos.length + (provider.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= provider.bonos.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final bono = provider.bonos[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          onTap: () {
            // Opcional: Navegar al perfil del paciente
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(bono).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.confirmation_num_outlined,
              color: _getStatusColor(bono),
            ),
          ),
          title: Row(
            children: [
              Text(
                bono.nombreCliente,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(bono),
              if (!bono.pagado) ...[
                const SizedBox(width: 8),
                _buildUnpaidBadge(),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(bono.nombreServicio),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy').format(bono.fechaCompra)),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${bono.sesionesRestantes} / ${bono.sesionesTotales}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                "sesiones restantes",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(BonoHistorico bono) {
    if (bono.agotado) return Colors.grey;
    if (bono.caducado) return Colors.red;
    return Colors.green;
  }

  Widget _buildStatusBadge(BonoHistorico bono) {
    String text = "ACTIVO";
    Color color = Colors.green;

    if (bono.agotado) {
      text = "AGOTADO";
      color = Colors.grey;
    } else if (bono.caducado) {
      text = "CADUCADO";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnpaidBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Text(
        "PENDIENTE PAGO",
        style: TextStyle(
          color: Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
