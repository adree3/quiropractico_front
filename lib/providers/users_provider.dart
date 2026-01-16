import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class UsersProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Usuario> usuarios = [];
  bool isLoading = true;
  bool? filterActive = true;

  int _realBlockedCount = 0;
  bool _showBadge = false;

  int blockedCount = 0;

  int currentPage = 0;
  int pageSize = 11;
  int totalElements = 0;
  int totalPages = 0;

  int get blockedCountDisplay => _showBadge ? _realBlockedCount : 0;

  UsersProvider() {
    getUsers();
  }

  Future<void> getUsers({int page = 0, bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;
    try {
      final Map<String, dynamic> params = {'page': page, 'size': pageSize};
      if (filterActive != null) {
        params['activo'] = filterActive;
      }

      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios',
        queryParameters: params,
      );

      final List<dynamic> data = response.data['content'];
      totalElements = response.data['totalElements'];
      totalPages = response.data['totalPages'];

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
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/bloqueados/count',
      );
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
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/bloqueados/count',
      );
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
  Future<String?> createUser(
    String nombre,
    String username,
    String password,
    String rol,
  ) async {
    isLoading = true;
    try {
      final data = {
        "nombreCompleto": nombre,
        "username": username,
        "password": password,
        "rol": rol,
      };
      await ApiService.dio.post('$_baseUrl/usuarios', data: data);
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
  Future<String?> updateUser(
    int id,
    String nombre,
    String? password,
    String rol,
  ) async {
    try {
      final data = {
        "nombreCompleto": nombre,
        "rol": rol,
        if (password != null && password.isNotEmpty) "password": password,
      };
      await ApiService.dio.put('$_baseUrl/usuarios/$id', data: data);
      await getUsers();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // DESACTIVAR
  Future<String?> deleteUser(int id) async {
    try {
      await ApiService.dio.delete('$_baseUrl/usuarios/$id');
      await getUsers();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // REACTIVAR
  Future<String?> recoverUser(int id) async {
    try {
      await ApiService.dio.put('$_baseUrl/usuarios/$id/recuperar');
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
}
