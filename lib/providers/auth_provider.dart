import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/services/local_storage.dart';

enum AuthStatus { checking, authenticated, notAuthenticated, locked }

class AuthProvider extends ChangeNotifier {
  
  AuthStatus authStatus = AuthStatus.checking;
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';
  String? role;

  String? errorMessage;
  bool isLoginLoading = false;

  AuthProvider() {
    isAuthenticated();
  }

  Future<bool> login(String username, String password) async {
    isLoginLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'username': username,
          'password': password
        },
        options: Options(validateStatus: (status) => status! < 500)
      );

      if (response.statusCode == 200) {
        final String token = response.data['token'];
        final String userRole = response.data['rol'];
        await LocalStorage.saveToken(token);
        await LocalStorage.saveRole(userRole);
        
        role = userRole;
        authStatus = AuthStatus.authenticated;
        isLoginLoading = false;
        notifyListeners();
        return true;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        String msg = response.data['message'] ?? response.data['error'] ?? 'Error de autenticación';        
        if (msg.toLowerCase().contains("bloqueada")|| response.statusCode == 423) {
          errorMessage = "Cuenta bloqueada, contacta con un administrador.";
          authStatus = AuthStatus.locked;
        } else {
          errorMessage = msg;
          authStatus = AuthStatus.notAuthenticated;
        }
      } else {
        errorMessage = 'Error desconocido: ${response.statusCode}';
        authStatus = AuthStatus.notAuthenticated;
      }
    } on DioException catch (e) {
      authStatus = AuthStatus.notAuthenticated;
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu red.';
      } else {
        errorMessage = 'Error del servidor: ${e.message}';
      }
    } catch (e) {
      errorMessage = 'Error inesperado: $e';
      authStatus = AuthStatus.notAuthenticated;
    }
    
    isLoginLoading = false;
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