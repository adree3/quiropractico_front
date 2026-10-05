import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/ui/views/dashboard/widgets/document_folder_grid.dart';

class ClienteArchivosTab extends StatefulWidget {
  final Cliente cliente;

  const ClienteArchivosTab({super.key, required this.cliente});

  @override
  State<ClienteArchivosTab> createState() => _ClienteArchivosTabState();
}

class _ClienteArchivosTabState extends State<ClienteArchivosTab> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Carga inicial inteligente (no recarga si ya están en memoria por _currentClienteId)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentosProvider>(context, listen: false)
          .loadDocumentos(widget.cliente.idCliente, silent: false);
    });
  }

  Widget _buildSkeletonGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.35,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    return Consumer<DocumentosProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildSkeletonGrid();
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
          color: Colors.transparent, // Hereda el Flat Desktop F8FAFC del TabBarView
          child: DocumentFolderGrid(
            cliente: widget.cliente,
            documentos: provider.documentos,
          ),
        );
      },
    );
  }
}
