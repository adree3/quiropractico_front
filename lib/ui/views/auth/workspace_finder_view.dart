import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/workspace_provider.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class WorkspaceFinderView extends StatefulWidget {
  const WorkspaceFinderView({super.key});

  @override
  State<WorkspaceFinderView> createState() => _WorkspaceFinderViewState();
}

class _WorkspaceFinderViewState extends State<WorkspaceFinderView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WorkspaceProvider>().searchClinicas(query);
    });
  }

  void _selectClinica(int id, String nombre, String direccion) async {
    // Purgar RAM de otros tenants antes de entrar al nuevo
    // (Útil para super_admin que cambia de clínica sin cerrar sesión)
    context.read<AuthProvider>().importProviders(context);
    
    await LocalStorage.saveClinica(id, nombre, direccion);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450, minHeight: 600, maxHeight: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Encuentra tu clínica',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el nombre del espacio de trabajo para continuar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Ej. Quiropráctica Valladolid',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              context.read<WorkspaceProvider>().clearSearch();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Consumer<WorkspaceProvider>(
                    builder: (context, workspaceProvider, child) {
                      if (workspaceProvider.isLoading) {
                        return _buildSkeletons();
                      }

                      if (workspaceProvider.errorMessage != null && workspaceProvider.hasSearched) {
                        return Center(
                          child: Text(
                            workspaceProvider.errorMessage!,
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (workspaceProvider.searchResults.isEmpty && workspaceProvider.hasSearched) {
                        return ListView(
                          children: [
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.search_off, color: Colors.orange),
                                ),
                                title: const Text(
                                  'Sin coincidencias',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                subtitle: const Text(
                                  'Busca por otro nombre.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        itemCount: workspaceProvider.searchResults.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final clinica = workspaceProvider.searchResults[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.storefront, color: AppTheme.primaryColor),
                              ),
                              title: Text(
                                clinica.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                clinica.direccion,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => _selectClinica(clinica.idClinica, clinica.nombre, clinica.direccion),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
