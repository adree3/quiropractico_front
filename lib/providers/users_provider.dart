import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class UsersProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Usuario> usuarios = [];
  bool isLoading = true;
  bool? filterActive = true;

  int _realBlockedCount = 0;
  bool _showBadge = false;

  int blockedCount = 0;
  final Set<int> _ignoredBlockedUserIds = {};

  int get blockedCountDisplay => _showBadge ? _realBlockedCount : 0;

  UsersProvider() {
    getUsers();
  }

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> getUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> params = {
        'page': 0, 
        'size': 20
      };
      if (filterActive != null) {
        params['activo'] = filterActive;
      }

      final response = await _dio.get(
        '$_baseUrl/usuarios',
        queryParameters: params,
        options: _authOptions
      );
      
      final List<dynamic> data = response.data['content'];
      usuarios = data.map((e) => Usuario.fromJson(e)).toList();
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
      final response = await _dio.get('$_baseUrl/usuarios/bloqueados/count', options: _authOptions);
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
      // 1. Obtenemos la lista real de bloqueados del backend
      // Necesitamos un cambio pequeño aquí: en lugar de solo count, 
      // necesitamos saber QUIÉNES son para poder filtrar los ignorados.
      // PERO, para no complicar el backend ahora, haremos un truco visual:
      
      final response = await _dio.get('$_baseUrl/usuarios/bloqueados/count', options: _authOptions);
      int realCount = response.data;

      // Si tenemos ignorados, restamos (esto es una aproximación visual)
      // Lo ideal sería filtrar en el cliente, pero para el badge sirve.
      blockedCount = (realCount - _ignoredBlockedUserIds.length).clamp(0, 99);
      
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  void ignoreBlockAlert(int userId) {
    _ignoredBlockedUserIds.add(userId);
    checkBlockedCount();
    notifyListeners();
  }

   // Helper para saber si un usuario específico debe mostrar alerta
  bool shouldShowAlertFor(int userId, bool isBlockedInDb) {
    if (!isBlockedInDb) return false;
    if (_ignoredBlockedUserIds.contains(userId)) return false;
    return true;
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
    try {
      final data = {
        "nombreCompleto": nombre,
        "username": username,
        "password": password,
        "rol": rol
      };
      await _dio.post(
        '$_baseUrl/usuarios', 
        data: data, 
        options: _authOptions
      );
      await getUsers();
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
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
      await _dio.put(
        '$_baseUrl/usuarios/$id', 
        data: data, 
        options: _authOptions
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
      await _dio.delete(
        '$_baseUrl/usuarios/$id', 
        options: _authOptions
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
      await _dio.put(
        '$_baseUrl/usuarios/$id/recuperar',
        options: _authOptions
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
      await _dio.put(
        '$_baseUrl/usuarios/$id/desbloquear', 
        options: _authOptions
      );
      await getUsers();      
      return null;
    } catch (e) { 
      return ErrorHandler.extractMessage(e);
    }
  }
}