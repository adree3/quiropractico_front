import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/bono_seleccion.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/ventas_provider.dart';
import 'package:quiropractico_front/ui/modals/venta_bono_modal.dart';

class PaymentSelectionModal extends StatefulWidget {
  final Cliente cliente;
  const PaymentSelectionModal({super.key, required this.cliente});

  @override
  State<PaymentSelectionModal> createState() => _PaymentSelectionModalState();
}

class _PaymentSelectionModalState extends State<PaymentSelectionModal> {
  BonoSeleccion? selectedBono;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VentasProvider>(context, listen: false);
      await provider.cargarBonosUsables(widget.cliente.idCliente);
      
      if (provider.bonosUsables.isNotEmpty) {
        setState(() => selectedBono = provider.bonosUsables.first);
      }
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VentasProvider>(context);
    final tieneBonos = provider.bonosUsables.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Confirmar Pago", style: TextStyle(fontWeight: FontWeight.bold)),
      
      content: SizedBox(
        width: 500,
        height: 350,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (tieneBonos) ...[
                    const Text("Selecciona el bono a consumir:", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: provider.bonosUsables.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final bono = provider.bonosUsables[i];
                          final isSelected = selectedBono?.idBonoActivo == bono.idBonoActivo;
                          
                          return RadioListTile<BonoSeleccion>(
                            value: bono,
                            groupValue: selectedBono,
                            onChanged: (val) => setState(() => selectedBono = val),
                            activeColor: AppTheme.primaryColor,
                            title: Text(bono.nombreServicio, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${bono.propietarioNombre} • Quedan ${bono.sesionesRestantes}"),
                            secondary: Icon(
                              bono.esPropio ? Icons.account_circle : Icons.family_restroom,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: isSelected ? const BorderSide(color: AppTheme.primaryColor) : BorderSide.none
                            ),
                            selected: isSelected,
                            selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _abrirVenta(context),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text("¿El cliente quiere comprar otro bono?"),
                    )
                  ] else ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 70, color: Colors.orange.shade300),
                          const SizedBox(height: 20),
                          Text(
                            "${widget.cliente.nombre} no tiene sesiones disponibles.",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Debes realizar una venta para poder asignar la cita.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar')
        ),

        tieneBonos
            ? ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedBono?.idBonoActivo),
                child: const Text('Confirmar y Agendar'),
              )
            : ElevatedButton.icon(
                onPressed: () => _abrirVenta(context),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Comprar Bono Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)
                ),
              ),
      ],
    );
  }

  Future<void> _abrirVenta(BuildContext context) async {
    final ventaExitosa = await showDialog<bool>(
      context: context,
      builder: (_) => VentaBonoModal(cliente: widget.cliente)
    );

    if (ventaExitosa == true && mounted) {
       Provider.of<VentasProvider>(context, listen: false).cargarBonosUsables(widget.cliente.idCliente);
    }
  }
}