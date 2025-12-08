import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class ClientsProvider extends ChangeNotifier {
  
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<Cliente> clients = [];
  bool isLoading = true;
  bool isSearching = false; 
  bool filterActive = true;

  String currentSearchTerm = '';

  int currentPage = 0;
  int pageSize = 10;
  int totalPages = 0;
  int totalElements = 0;

  ClientsProvider() {
    getPaginatedClients(); 
  }
  Future<bool> createClient(String nombre, String apellidos, String telefono, String? email, String? direccion) async {
    try {
      final token = LocalStorage.getToken();
      
      final data = {
        "nombre": nombre,
        "apellidos": apellidos,
        "telefono": telefono,
        "email": email,
        "direccion": direccion
      };

      final response = await _dio.post(
        '$_baseUrl/clientes',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 201) {
        getPaginatedClients(page: 0);
        return true;
      }
      return false;

    } catch (e) {
      print('Error creando cliente: $e');
      return false;
    }
  }
  Future<void> getPaginatedClients({int page = 0}) async {
    isLoading = true;
    currentPage = page;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/clientes',
        queryParameters: {
          'activo': filterActive,
          'page': page,
          'size': pageSize,
          'sort': 'id_cliente,desc' 
        },
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data['content'];
      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];

      clients = data.map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando clientes: $e');
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
      final token = LocalStorage.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/clientes/buscar',
        queryParameters: {'texto': query}, 
        options: Options(headers: {'Authorization': 'Bearer $token'})
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
      await getPaginatedClients(page: 0);
      return;
    }

    isLoading = true;
    isSearching = true;
    currentSearchTerm = query;
    currentPage = page;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/clientes/buscar-complejo',
        queryParameters: {
          'texto': query,
          'page': page,     
          'size': pageSize, 
        },
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data['content'];
      
      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];
      
      clients = data.map((json) => Cliente.fromJson(json)).toList();

    } catch (e) {
      print('Error en búsqueda global: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Borrado Lógico
  Future<bool> deleteClient(int idCliente) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.delete(
        '$_baseUrl/clientes/$idCliente', 
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      if (isSearching) {
        searchGlobal(currentSearchTerm, page: currentPage);
      } else {
        getPaginatedClients(page: currentPage);
      }
      return true;
    } catch (e) {
      print('Error borrando cliente: $e');
      return false;
    }
  }

  void toggleFilter(bool isActive) {
    filterActive = isActive;
    getPaginatedClients(page: 0);
  }
  
  // Editar Cliente
  Future<bool> updateClient(int id, String nombre, String apellidos, String telefono, String? email, String? direccion) async {
    try {
      final token = LocalStorage.getToken();
      final data = { "nombre": nombre, "apellidos": apellidos, "telefono": telefono, "email": email, "direccion": direccion };

      final response = await _dio.put( 
        '$_baseUrl/clientes/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 200) {
        final index = clients.indexWhere((c) => c.idCliente == id);
        if (index != -1) {
           clients[index] = Cliente.fromJson(response.data);
           notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error editando: $e');
      return false;
    }
  }

  Future<bool> recoverClient(int idCliente) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.put(
        '$_baseUrl/clientes/$idCliente/recuperar', 
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      if (isSearching) {
        searchGlobal(currentSearchTerm, page: currentPage);
      } else {
        getPaginatedClients(page: currentPage);
      }
      return true;
    } catch (e) {
      print('Error recuperando cliente: $e');
      return false;
    }
  }

  Future<Cliente?> getClientePorId(int id) async {
    try {
      try {
        return clients.firstWhere((c) => c.idCliente == id);
      } catch (_) {
      }

      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/clientes/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      return Cliente.fromJson(response.data);
    } catch (e) {
      print('Error cargando cliente individual: $e');
      return null;
    }
  }
}