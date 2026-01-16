import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/cliente.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class ClientsProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Cliente> clients = [];
  bool isLoading = true;
  bool isSearching = false;
  bool filterActive = true;
  String? errorMessage;

  String currentSearchTerm = '';
  int currentPage = 0;
  int pageSize = 11;
  int totalPages = 0;
  int totalElements = 0;

  ClientsProvider() {
    getPaginatedClients();
  }

  Future<String?> createClient(
    String nombre,
    String apellidos,
    String telefono,
    String? email,
    String? direccion,
  ) async {
    try {
      final data = {
        "nombre": nombre,
        "apellidos": apellidos,
        "telefono": telefono,
        "email": email,
        "direccion": direccion,
      };

      await ApiService.dio.post('$_baseUrl/clientes', data: data);

      getPaginatedClients(page: 0);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> getPaginatedClients({
    int page = 0,
    bool notifyLoading = true,
  }) async {
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;
    errorMessage = null;

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/clientes',
        queryParameters: {
          'activo': filterActive,
          'page': page,
          'size': pageSize,
          'sort': 'id_cliente,desc',
        },
      );

      final List<dynamic> data = response.data['content'];
      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];

      clients = data.map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      if (isSearching) {
        searchGlobal(currentSearchTerm, page: currentPage + 1);
      } else {
        getPaginatedClients(page: currentPage + 1);
      }
    }
  }

  void prevPage() {
    if (currentPage > 0) {
      if (isSearching) {
        searchGlobal(currentSearchTerm, page: currentPage - 1);
      } else {
        getPaginatedClients(page: currentPage - 1);
      }
    }
  }

  List<Cliente> filterClients(String query) {
    if (query.isEmpty) return clients;
    return clients
        .where(
          (c) =>
              c.nombre.toLowerCase().contains(query.toLowerCase()) ||
              c.apellidos.toLowerCase().contains(query.toLowerCase()) ||
              c.telefono.contains(query),
        )
        .toList();
  }

  Future<List<Cliente>> searchClientesByName(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/clientes/buscar',
        queryParameters: {'texto': query},
      );

      final List<dynamic> data = response.data;

      return data.map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      print('Error buscando clientes: $e');
      return [];
    }
  }

  // Barra de busqueda
  Future<void> searchGlobal(
    String query, {
    int page = 0,
    bool notifyLoading = true,
  }) async {
    if (query.isEmpty) {
      isSearching = false;
      currentSearchTerm = '';
      await getPaginatedClients(page: 0);
      return;
    }

    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    isSearching = true;
    currentSearchTerm = query;
    currentPage = page;

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/clientes/buscar-complejo',
        queryParameters: {'texto': query, 'page': page, 'size': pageSize},
      );

      final List<dynamic> data = response.data['content'];

      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];

      clients = data.map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      print('Error en búsqueda global: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Borrado Lógico
  Future<String?> deleteClient(int idCliente) async {
    try {
      await ApiService.dio.delete('$_baseUrl/clientes/$idCliente');

      final index = clients.indexWhere((c) => c.idCliente == idCliente);
      if (index != -1) {
        if (filterActive) {
          // Si estamos viendo "activos" y se borra uno, lo quitamos de la lista
          clients.removeAt(index);
          totalElements--; // Ajustamos contador visualmente
        } else {
          // Si estamos viendo "inactivos" o "todos", quizás solo cambiamos su estado
          // Pero tu lógica de backend dirá. Asumiendo borrado lógico:
          // Si es "Todos", lo marcamos inactivo. Si es "Inactivos", no debería estar aquí si estaba activo.
          clients[index] = clients[index].copyWith(activo: false);
        }
        notifyListeners();
        // Silent refresh to fill the gap
        _refreshCurrentView(notifyLoading: false);
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  void _refreshCurrentView({bool notifyLoading = true}) {
    if (isSearching) {
      searchGlobal(
        currentSearchTerm,
        page: currentPage,
        notifyLoading: notifyLoading,
      );
    } else {
      getPaginatedClients(page: currentPage, notifyLoading: notifyLoading);
    }
  }

  void toggleFilter(bool isActive) {
    filterActive = isActive;
    getPaginatedClients(page: 0);
  }

  // Editar Cliente
  Future<String?> updateClient(
    int id,
    String nombre,
    String apellidos,
    String telefono,
    String? email,
    String? direccion,
  ) async {
    try {
      final data = {
        "nombre": nombre,
        "apellidos": apellidos,
        "telefono": telefono,
        "email": email,
        "direccion": direccion,
      };

      final response = await ApiService.dio.put(
        '$_baseUrl/clientes/$id',
        data: data,
      );

      final index = clients.indexWhere((c) => c.idCliente == id);
      if (index != -1) {
        clients[index] = Cliente.fromJson(response.data);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> recoverClient(int idCliente) async {
    try {
      await ApiService.dio.put('$_baseUrl/clientes/$idCliente/recuperar');

      final index = clients.indexWhere((c) => c.idCliente == idCliente);
      if (index != -1) {
        if (!filterActive) {
          // Si estamos viendo "eliminados" y se recupera, se va de la lista
          clients.removeAt(index);
          totalElements--;
        } else {
          // Si estamos viendo "todos", se marca activo
          clients[index] = clients[index].copyWith(activo: true);
        }
        notifyListeners();
        // Silent refresh to fill the gap
        _refreshCurrentView(notifyLoading: false);
      } else {
        // Edge case: no está en la lista visible (raro), refrescamos por si acaso
        _refreshCurrentView();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<Cliente?> getClientePorId(int id) async {
    try {
      try {
        return clients.firstWhere((c) => c.idCliente == id);
      } catch (_) {}

      final response = await ApiService.dio.get('$_baseUrl/clientes/$id');

      return Cliente.fromJson(response.data);
    } catch (e) {
      print('Error cargando cliente individual: $e');
      return null;
    }
  }
}
