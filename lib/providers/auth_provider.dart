import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/services/local_storage.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthProvider extends ChangeNotifier {
  
  AuthStatus authStatus = AuthStatus.checking;
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  String? role;

  AuthProvider() {
    isAuthenticated();
  }

  Future<bool> login(String username, String password) async {
    
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'username': username,
          'password': password
        }
      );

      if (response.statusCode == 200) {
        final String token = response.data['token'];
        final String userRole = response.data['rol'];
        await LocalStorage.saveToken(token);
        await LocalStorage.saveRole(userRole);
        
        role = userRole;
        authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
    } catch (e) {
      print('Error CRÍTICO en login: $e');
      if (e is DioException) {
        print('Tipo de error Dio: ${e.type}');
        print('Respuesta del servidor: ${e.response?.data}');
        print('Código de estado: ${e.response?.statusCode}');
      }
    }
    
    authStatus = AuthStatus.notAuthenticated;
    notifyListeners();
    return false;
  }

  Future<void> isAuthenticated() async {
    final token = LocalStorage.getToken();
    final storedRole = LocalStorage.getRole();

    if (token == null) {
      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return;
    }
    role = storedRole;
    authStatus = AuthStatus.authenticated;
    notifyListeners();
  }
  
  // Cerrar sesión
  void logout() {
    LocalStorage.deleteToken();
    authStatus = AuthStatus.notAuthenticated;
    notifyListeners();
  }
}