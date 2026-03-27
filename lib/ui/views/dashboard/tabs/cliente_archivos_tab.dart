import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_folder_grid.dart';

class ClienteArchivosTab extends StatefulWidget {
  final Cliente cliente;

  const ClienteArchivosTab({super.key, required this.cliente});

  @override
  State<ClienteArchivosTab> createState() => _ClienteArchivosTabState();
}

class _ClienteArchivosTabState extends State<ClienteArchivosTab> {
  @override
  void initState() {
    super.initState();
    // Invocamos la carga inicial (JIT pointer list) al renderizar la pestaña
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentosProvider>(context, listen: false)
          .loadDocumentos(widget.cliente.idCliente);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentosProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.blueGrey, size: 64),
                const SizedBox(height: 16),
                Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.loadDocumentos(widget.cliente.idCliente),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey.shade50,
          child: DocumentFolderGrid(
            cliente: widget.cliente,
            documentos: provider.documentos,
          ),
        );
      },
    );
  }
}

