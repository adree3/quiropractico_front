import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/cliente.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class ClientsProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Cliente> clients = [];
  bool isLoading = true;
  bool? filterActive = true;
  String? errorMessage;

  String currentSearchTerm = '';
  int currentPage = 0;
  int pageSize = 11;
  int totalPages = 0;
  int totalElements = 0;
  int? lastActivityDays; // null, 7, o 30

  ClientsProvider() {
    loadClients();
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

  // Método unificado para cargar clientes con todos los filtros
  Future<void> loadClients({
    int page = 0,
    bool resetPage = false,
    bool notifyLoading = true,
  }) async {
    if (resetPage) currentPage = 0;
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;
    errorMessage = null;

    try {
      final Map<String, dynamic> params = {
        'page': page,
        'size': pageSize,
        'sort': 'id_cliente,desc',
      };

      if (filterActive != null) params['activo'] = filterActive;
      if (currentSearchTerm.isNotEmpty) params['texto'] = currentSearchTerm;
      if (lastActivityDays != null)
        params['lastActivityDays'] = lastActivityDays;

      final response = await ApiService.dio.get(
        '$_baseUrl/clientes',
        queryParameters: params,
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

  // Método legacy para compatibilidad (ahora usa loadClients)
  Future<void> getPaginatedClients({
    int page = 0,
    bool notifyLoading = true,
  }) async {
    await loadClients(page: page, notifyLoading: notifyLoading);
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      loadClients(page: currentPage + 1);
    }
  }

  void prevPage() {
    if (currentPage > 0) {
      loadClients(page: currentPage - 1);
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

  // Actualiza el término de búsqueda y recarga
  Future<void> searchGlobal(
    String query, {
    int page = 0,
    bool notifyLoading = true,
  }) async {
    currentSearchTerm = query;
    await loadClients(
      page: page,
      resetPage: true,
      notifyLoading: notifyLoading,
    );
  }

  // Nuevos métodos para filtros
  void setActivityFilter(int? days) {
    lastActivityDays = days;
    loadClients(resetPage: true);
  }

  // Borrado Lógico
  Future<String?> deleteClient(int idCliente, {bool undo = false}) async {
    try {
      await ApiService.dio.delete(
        '$_baseUrl/clientes/$idCliente',
        queryParameters: {'undo': undo},
      );

      final index = clients.indexWhere((c) => c.idCliente == idCliente);
      if (index != -1) {
        if (filterActive == true) {
          clients.removeAt(index);
          totalElements--;
        } else {
          clients[index] = clients[index].copyWith(activo: false);
        }
        notifyListeners();
        _refreshCurrentView(notifyLoading: false);
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  void _refreshCurrentView({bool notifyLoading = true}) {
    loadClients(page: currentPage, notifyLoading: notifyLoading);
  }

  void toggleFilter(bool? isActive) {
    filterActive = isActive;
    loadClients(resetPage: true);
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
        queryParameters: {'undo': false}, // Normal update
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

  // Método específico para UNDO UPDATE
  Future<String?> undoUpdateClient(Cliente clienteAntiguo) async {
    try {
      final data = clienteAntiguo.toJson();
      // Aseguramos que solo enviamos los campos necesarios o el objeto entero si el backend lo soporta.
      // El backend espera ClienteRequestDto, asi que extraemos los campos.
      final requestData = {
        "nombre": clienteAntiguo.nombre,
        "apellidos": clienteAntiguo.apellidos,
        "telefono": clienteAntiguo.telefono,
        "email": clienteAntiguo.email,
        "direccion": clienteAntiguo.direccion,
      };

      final response = await ApiService.dio.put(
        '$_baseUrl/clientes/${clienteAntiguo.idCliente}',
        data: requestData,
        queryParameters: {'undo': true},
      );

      final index = clients.indexWhere(
        (c) => c.idCliente == clienteAntiguo.idCliente,
      );
      if (index != -1) {
        clients[index] = Cliente.fromJson(response.data);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> recoverClient(int idCliente, {bool undo = false}) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/clientes/$idCliente/recuperar',
        queryParameters: {'undo': undo},
      );

      final index = clients.indexWhere((c) => c.idCliente == idCliente);
      if (index != -1) {
        if (filterActive == false) {
          clients.removeAt(index);
          totalElements--;
        } else {
          clients[index] = clients[index].copyWith(activo: true);
        }
        notifyListeners();
        _refreshCurrentView(notifyLoading: false);
      } else {
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
