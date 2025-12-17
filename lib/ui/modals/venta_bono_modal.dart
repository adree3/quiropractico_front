import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/servicio.dart';
import 'package:quiropractico_front/providers/ventas_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class VentaBonoModal extends StatefulWidget {
  final Cliente cliente;

  const VentaBonoModal({super.key, required this.cliente});

  @override
  State<VentaBonoModal> createState() => _VentaBonoModalState();
}

class _VentaBonoModalState extends State<VentaBonoModal> {
  final _formKey = GlobalKey<FormState>();
  
  Servicio? selectedServicio;
  String selectedMetodo = 'transferencia';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VentasProvider>(context, listen: false).loadServiciosDisponibles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = Provider.of<VentasProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shopping_cart, color: Colors.green),
          ),
          const SizedBox(width: 10),
          const Text('Nueva Venta', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cliente: ${widget.cliente.nombre} ${widget.cliente.apellidos}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              // SELECTOR DE BONO
              DropdownButtonFormField<Servicio>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Servicio',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                ),
                value: selectedServicio,
                items: ventasProvider.listaServicios.map((servicio) {
                  final texto = "${servicio.nombreServicio}  |  ${servicio.precio}€";
                  return DropdownMenuItem(
                    value: servicio,
                    child: Text(
                      texto,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedServicio = val),
                validator: (val) => val == null ? 'Selecciona un producto' : null,
                hint: ventasProvider.listaServicios.isEmpty 
                    ? const Text("Cargando...") 
                    : (ventasProvider.listaServicios.isEmpty 
                        ? const Text("No hay servicios activos", style: TextStyle(color: Colors.red))
                        : const Text("Selecciona una opción")),
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
              if (selectedServicio != null)
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
                        "${selectedServicio!.precio} €", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(20),
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
                final String? error = await ventasProvider.venderBono(
                  widget.cliente.idCliente,
                  selectedServicio!.idServicio,
                  selectedMetodo
                );

                if (context.mounted) {
                  if (error == null) {
                    Navigator.pop(context, true); 
                    CustomSnackBar.show(context, 
                      message: 'Venta realizada con éxito', 
                      type: SnackBarType.success
                    );
                  } else {
                    CustomSnackBar.show(context, 
                      message: error, 
                      type: SnackBarType.error
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