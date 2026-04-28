import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/api_error.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/stats_provider.dart';

enum AuthStatus { checking, authenticated, notAuthenticated, locked }

class AuthProvider extends ChangeNotifier {
  AuthStatus authStatus = AuthStatus.checking;
  final String _baseUrl = ApiConfig.baseUrl;
  String? role;

  // Helpers de permisos
  bool get isSuperAdmin => role?.toLowerCase() == 'super_admin';
  bool get isAdmin => role?.toLowerCase() == 'admin' || isSuperAdmin;
  bool get isGestor => isAdmin || role?.toLowerCase() == 'quiropráctico';

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
      final clinicaId = LocalStorage.getClinicaId();
      print('ClinicaId sacado de caché: $clinicaId');
      
      final response = await ApiService.dio.post(
        '$_baseUrl/auth/login',
        data: {
          'username': username, 
          'password': password,
          'clinicaId': clinicaId,
        },
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
  void logout(BuildContext context) {
    // 1. Cambiamos el estado y NOTIFICAMOS inmediatamente.
    // Esto hace que el GoRouter redirija a /login y destruya el DashboardLayout/Sidebar
    // ANTES de que borremos el token o purguemos la RAM.
    authStatus = AuthStatus.notAuthenticated;
    notifyListeners();

    // 2. Purgar toda la RAM de los providers de negocio (ahora que ya no hay widgets escuchando)
    try {
      importProviders(context);
    } catch (e) {
      debugPrint('Error purgando providers: $e');
    }

    // 3. Limpiar almacenamiento físico
    LocalStorage.deleteToken();
  }

  void importProviders(BuildContext context) {
    // Purgamos la memoria de todos los providers de negocio
    context.read<CitasProvider>().clearAllData();
    context.read<UsersProvider>().clearAllData();
    context.read<ClientsProvider>().clearAllData();
    context.read<PaymentsProvider>().clearAllData();
    context.read<ServicesProvider>().clearAllData();
    context.read<HorariosProvider>().clearAllData();
    context.read<StatsProvider>().clearAllData();
  }

  /// Refresca contadores globales (badges) que deben estar listos al entrar a la app
  void refreshGlobalData(BuildContext context) {
    // Estas llamadas no bloquean la UI (corren en segundo plano)
    context.read<PaymentsProvider>().checkPendingCount();
    context.read<UsersProvider>().checkBlockedCount();
  }
}
