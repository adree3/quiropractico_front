import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/ventas_provider.dart';

class VentaBonoModal extends StatefulWidget {
  final Cliente cliente;

  const VentaBonoModal({super.key, required this.cliente});

  @override
  State<VentaBonoModal> createState() => _VentaBonoModalState();
}

class _VentaBonoModalState extends State<VentaBonoModal> {
  final _formKey = GlobalKey<FormState>();
  
  Servicio? selectedBono;
  String selectedMetodo = 'transferencia';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VentasProvider>(context, listen: false).loadBonos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = Provider.of<VentasProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.green),
          const SizedBox(width: 10),
          Text('Venta para ${widget.cliente.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SELECTOR DE BONO
              DropdownButtonFormField<Servicio>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Bono',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                ),
                value: selectedBono,
                items: ventasProvider.bonosDisponibles.map((servicio) {
                  return DropdownMenuItem(
                    value: servicio,
                    child: Text("${servicio.nombreServicio} - ${servicio.precio}€"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedBono = val),
                validator: (val) => val == null ? 'Selecciona un producto' : null,
              ),
              
              const SizedBox(height: 20),

              // MÉTODO DE PAGO 
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                value: selectedMetodo,
                items: const [
                  DropdownMenuItem(value: 'tarjeta', child: Text("Tarjeta")),
                  DropdownMenuItem(value: 'efectivo', child: Text("Efectivo")),
                  DropdownMenuItem(value: 'transferencia', child: Text("Transferencia")),
                ],
                onChanged: (val) => setState(() => selectedMetodo = val!),
              ),

              const SizedBox(height: 30),

              // RESUMEN TOTAL
              if (selectedBono != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL A COBRAR:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "${selectedBono!.precio} €", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: ventasProvider.isLoading 
            ? null 
            : () async {
              if (_formKey.currentState!.validate()) {
                final success = await ventasProvider.venderBono(
                  widget.cliente.idCliente,
                  selectedBono!.idServicio,
                  selectedMetodo
                );

                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context, true); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Venta realizada con éxito'), backgroundColor: Colors.green)
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error en la venta'), backgroundColor: Colors.red)
                    );
                  }
                }
              }
            },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: ventasProvider.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Confirmar Venta'),
        ),
      ],
    );
  }
}