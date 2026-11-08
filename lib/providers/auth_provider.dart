import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/services/auth_service.dart';
import 'package:quiropractico_front/models/api_error.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/providers/agenda_bloqueo_provider.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/auditoria_provider.dart';
import 'package:quiropractico_front/providers/bonos_provider.dart';
import 'package:quiropractico_front/providers/citas_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/providers/documentos_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:quiropractico_front/providers/stats_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/providers/ventas_provider.dart';

enum AuthStatus { checking, authenticated, notAuthenticated, locked }

class AuthProvider extends ChangeNotifier {
  
  AuthStatus authStatus = AuthStatus.checking;
  String? role;
  
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isQuiropractico => role == 'doctor' || isAdmin;
  bool get isRecepcion => role == 'recepcion' || isAdmin;

  // Aliases for backwards compatibility with UI views that still use old names
  bool get isGestor => isAdmin || isRecepcion;
  bool get isQuiron => isQuiropractico || isAdmin;

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
      if (clinicaId == null) {
        errorMessage = 'Por favor, selecciona un espacio de trabajo primero.';
        isLoginLoading = false;
        notifyListeners();
        return false;
      }
      print('ClinicaId sacado de caché: $clinicaId');
      
      final response = await AuthService.login(username, password, clinicaId);

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
      } else{
        final apiError = ApiError.fromJson(response.data);
        errorMessage = apiError.displayMessage;
        if (apiError.codigo == 'ACCOUNT_LOCKED') {
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
  void logout(BuildContext context) async {
    // 1. Purgado de disco físico
    await LocalStorage.deleteToken();
    role = null;

    // 2. Purgado profundo silencioso de toda la RAM de providers
    try {
      importProviders(context);
    } catch (e) {
      debugPrint('Error purgando providers: $e');
    }

    // 3. Cambio de estado final: expulsa al usuario desmontando el Dashboard de memoria
    authStatus = AuthStatus.notAuthenticated;
    notifyListeners();
  }

  void importProviders(BuildContext context) {
    // Purgado silencioso de la memoria de todos los providers de negocio sin disparar notifyListeners()
    context.read<AgendaProvider>().clearAllData();
    context.read<AgendaBloqueoProvider>().clearAllData();
    context.read<BonosProvider>().clearAllData();
    context.read<CitasProvider>().clearAllData();
    context.read<ClientsProvider>().clearAllData();
    context.read<DocumentosProvider>().clearAllData();
    context.read<HorariosProvider>().clearAllData();
    context.read<PaymentsProvider>().clearAllData();
    context.read<ServicesProvider>().clearAllData();
    context.read<SettingsProvider>().clearAllData();
    context.read<StatsProvider>().clearAllData();
    context.read<UsersProvider>().clearAllData();
    context.read<VentasProvider>().clearAllData();
    context.read<AuditoriaProvider>().clearAllData();
  }

  void refreshGlobalData(BuildContext context) {
    isAuthenticated();
  }
}