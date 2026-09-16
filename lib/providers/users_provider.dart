import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/config/api_config.dart';

class UsersProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Usuario> usuarios = [];
  bool isLoading = false;
  bool hasError = false;
  Usuario? currentUser;
  bool? filterActive = true;

  int _realBlockedCount = 0;
  bool _showBadge = false;

  int blockedCount = 0;

  int get blockedCountDisplay => _showBadge ? _realBlockedCount : 0;

  int currentPage = 0;
  int pageSize = 10;
  int totalElements = 0;
  int profilePictureVersion = 0;

  UsersProvider() {
    getUsers();
  }

  Future<String?> blockUser(int id) async {
    try {
      await ApiService.dio.put('$_baseUrl/usuarios/$id/bloquear', );
      await getUsers();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> uploadProfilePicture(dynamic file, [int? userId]) async {
    try {
      int targetId = userId ?? currentUser?.idUsuario ?? 0;
      if (targetId == 0) return "No hay usuario activo";
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: file.name)
      });
      await ApiService.dio.put('$_baseUrl/usuarios/$targetId/foto-perfil', data: formData, );
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> updateMyProfile(String newName, [String? newApellidos, String? currentPassword]) async {
    try {
      int targetId = currentUser?.idUsuario ?? 0;
      if (targetId == 0) return "No hay usuario activo";
      
      String fullName = newApellidos != null && newApellidos.isNotEmpty 
          ? "$newName $newApellidos" 
          : newName;

      final data = {
        "nombreCompleto": fullName,
        "username": currentUser?.username ?? '',
        "rol": currentUser?.rol ?? 'recepción',
      };
      
      await ApiService.dio.put('$_baseUrl/usuarios/$targetId', data: data, );
      await getMe();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> updateMyPassword(String currentPassword, String newPassword) async {
    try {
      final data = {
        "currentPassword": currentPassword,
        "newPassword": newPassword
      };
      await ApiService.dio.put('$_baseUrl/usuarios/me/password', data: data, );
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> getMe() async {
    isLoading = true;
    hasError = false;
    notifyListeners();
    try {
      final response = await ApiService.dio.get('$_baseUrl/usuarios/me');
      currentUser = Usuario.fromJson(response.data);
    } catch (e) {
      hasError = true;
      debugPrint('Error en getMe: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUsers({int page = 0}) async {
    isLoading = true;
    currentPage = page;
    notifyListeners();
    try {
      final Map<String, dynamic> params = {
        'page': currentPage, 
        'size': pageSize
      };
      if (filterActive != null) {
        params['activo'] = filterActive;
      }

      final response = await ApiService.dio.get('$_baseUrl/usuarios',
          queryParameters: params);

      final List<dynamic> data = response.data['content'];
      usuarios = data.map((e) => Usuario.fromJson(e)).toList();
      totalElements = response.data['totalElements'] ?? 0;
      await _checkNotifications();

    } catch (e) {
      print('Error cargando usuarios: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkNotifications() async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/usuarios/bloqueados/count');
      _realBlockedCount = response.data;

      final int lastSeen = LocalStorage.getLastSeenBlockedCount();

      if (_realBlockedCount > 0 && _realBlockedCount != lastSeen) {
        _showBadge = true;
      } else {
        _showBadge = false;
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> checkBlockedCount() async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/usuarios/bloqueados/count', );
      blockedCount = response.data;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> markAsSeen() async {
    if (_showBadge) {
      _showBadge = false;
      await LocalStorage.saveLastSeenBlockedCount(_realBlockedCount); 
      notifyListeners();
    }
  }

  // Filro de activos/inactivos/todos
  void setFilter(bool? active) {
    filterActive = active;
    getUsers();
  }

  // CREAR
  Future<String?> createUser(String nombre, String username, String password, String rol) async {
    isLoading = true;
    try {
      final data = {
        "nombreCompleto": nombre,
        "username": username,
        "password": password,
        "rol": rol
      };
      await ApiService.dio.post(
        '$_baseUrl/usuarios', 
        data: data, 
        
      );
      await getUsers();
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data['message'] ?? "Error al guardar";
      }
      return "Error de conexión";
    } catch (e) {
      return "Error inesperado";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // EDITAR
  Future<String?> updateUser(int id, String nombre, String? password, String rol) async {
    try {
      final data = {
        "nombreCompleto": nombre,
        "rol": rol,
        if (password != null && password.isNotEmpty) "password": password
      };
      await ApiService.dio.put(
        '$_baseUrl/usuarios/$id', 
        data: data, 
        
        );
      await getUsers();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }

  // DESACTIVAR
  Future<String?> deleteUser(int id) async {
    try {
      await ApiService.dio.delete(
        '$_baseUrl/usuarios/$id', 
        
      );
      await getUsers();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }

  // REACTIVAR
  Future<String?> recoverUser(int id) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/usuarios/$id/recuperar',
        
        );
      await getUsers();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }

  // DESBLOQUEAR
  Future<String?> unlockUser(int id) async {
    try {
      await ApiService.dio.put('$_baseUrl/usuarios/$id/desbloquear');
      await getUsers();      
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }

  void clearAllData() {
    usuarios = [];
    currentUser = null;
    isLoading = false;
    hasError = false;
    _realBlockedCount = 0;
    _showBadge = false;
    blockedCount = 0;
    currentPage = 0;
    totalElements = 0;
    notifyListeners();
  }
}
