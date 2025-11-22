import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class ClientsProvider extends ChangeNotifier {
  
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<Cliente> clients = [];
  bool isLoading = true;

  ClientsProvider() {
    getClients(); 
  }

  Future<void> getClients() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/clientes',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      final List<dynamic> data = response.data;
      clients = data.map((json) => Cliente.fromJson(json)).toList();

    } catch (e) {
      print('Error cargando clientes: $e');
      // Aquí podrías manejar errores (mostrar mensaje, etc.)
    } finally {
      isLoading = false;
      notifyListeners();
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
}