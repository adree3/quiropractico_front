import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/api_error.dart';
import 'package:quiropractico_front/services/local_storage.dart';

enum AuthStatus { checking, authenticated, notAuthenticated, locked }

class AuthProvider extends ChangeNotifier {
  AuthStatus authStatus = AuthStatus.checking;
  final String _baseUrl = ApiConfig.baseUrl;
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
      final response = await ApiService.dio.post(
        '$_baseUrl/auth/login',
        data: {'username': username, 'password': password},
        options: Options(validateStatus: (status) => status! < 500),
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
      } else {
        final apiError = ApiError.fromJson(response.data);
        errorMessage = apiError.message;
        if (apiError.errorType == 'ACCOUNT_LOCKED') {
          authStatus = AuthStatus.locked;
        } else {
          authStatus = AuthStatus.notAuthenticated;
        }
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
