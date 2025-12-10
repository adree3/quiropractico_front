import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class ClientsProvider extends ChangeNotifier {
  
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<Cliente> clients = [];
  bool isLoading = true;
  bool isSearching = false; 
  bool filterActive = true;
  String? errorMessage;

  String currentSearchTerm = '';
  int currentPage = 0;
  int pageSize = 10;
  int totalPages = 0;
  int totalElements = 0;

  ClientsProvider() {
    getPaginatedClients(); 
  }

  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<String?> createClient(String nombre, String apellidos, String telefono, String? email, String? direccion) async {
    try {
      
      final data = {
        "nombre": nombre,
        "apellidos": apellidos,
        "telefono": telefono,
        "email": email,
        "direccion": direccion
      };

      await _dio.post(
        '$_baseUrl/clientes',
        data: data,
        options: _authOptions
      );

      getPaginatedClients(page: 0);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
  Future<void> getPaginatedClients({int page = 0}) async {
    isLoading = true;
    currentPage = page;
    errorMessage = null;
    notifyListeners();

    try {
      
      final response = await _dio.get(
        '$_baseUrl/clientes',
        queryParameters: {
          'activo': filterActive,
          'page': page,
          'size': pageSize,
          'sort': 'id_cliente,desc' 
        },
        options: _authOptions
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
    return clients.where((c) => 
      c.nombre.toLowerCase().contains(query.toLowerCase()) ||
      c.apellidos.toLowerCase().contains(query.toLowerCase()) ||
      c.telefono.contains(query)
    ).toList();
  }

  Future<List<Cliente>> searchClientesByName(String query) async {
    if (query.isEmpty) return [];

    try {      
      final response = await _dio.get(
        '$_baseUrl/clientes/buscar',
        queryParameters: {'texto': query}, 
        options: _authOptions
      );

      final List<dynamic> data = response.data; 
      
      return data.map((json) => Cliente.fromJson(json)).toList();

    } catch (e) {
      print('Error buscando clientes: $e');
      return [];
    }
  }

  // Barra de busqueda
  Future<void> searchGlobal(String query, {int page = 0}) async {
    if (query.isEmpty) {
      isSearching = false;
      currentSearchTerm = '';
      await getPaginatedClients(page: 0);
      return;
    }

    isLoading = true;
    isSearching = true;
    currentSearchTerm = query;
    currentPage = page;
    notifyListeners();

    try {
      
      final response = await _dio.get(
        '$_baseUrl/clientes/buscar-complejo',
        queryParameters: {
          'texto': query,
          'page': page,     
          'size': pageSize, 
        },
        options: _authOptions
        
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
      await _dio.delete(
        '$_baseUrl/clientes/$idCliente', 
        options: _authOptions
      );
      
      _refreshCurrentView();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  void _refreshCurrentView() {
      if (isSearching) {
        searchGlobal(currentSearchTerm, page: currentPage);
      } else {
        getPaginatedClients(page: currentPage);
      }
  }

  void toggleFilter(bool isActive) {
    filterActive = isActive;
    getPaginatedClients(page: 0);
  }
  
  // Editar Cliente
  Future<String?> updateClient(int id, String nombre, String apellidos, String telefono, String? email, String? direccion) async {
    try {
      final data = { "nombre": nombre, "apellidos": apellidos, "telefono": telefono, "email": email, "direccion": direccion };

      final response = await _dio.put( 
        '$_baseUrl/clientes/$id',
        data: data,
        options: _authOptions
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
      await _dio.put(
        '$_baseUrl/clientes/$idCliente/recuperar', 
        options: _authOptions
      );
      
      _refreshCurrentView();
      return null;
    } catch (e) {
      return  ErrorHandler.extractMessage(e);
    }
  }

  Future<Cliente?> getClientePorId(int id) async {
    try {
      try {
        return clients.firstWhere((c) => c.idCliente == id);
      } catch (_) {
      }

      final response = await _dio.get(
        '$_baseUrl/clientes/$id',
        options: _authOptions
      );

      return Cliente.fromJson(response.data);
    } catch (e) {
      print('Error cargando cliente individual: $e');
      return null;
    }
  }
}