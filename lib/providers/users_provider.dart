import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:file_picker/file_picker.dart';

class UsersProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Usuario> usuarios = [];
  Usuario? currentUser;
  bool isLoading = true;
  bool? filterActive = true;
  int avatarIndex = LocalStorage.getAvatarIndex();

  int _realBlockedCount = 0;
  bool _showBadge = false;

  // Cache buster para la foto de perfil (hace que Flutter refresque la imagen al subir otra)
  int profilePictureVersion = DateTime.now().millisecondsSinceEpoch;

  int blockedCount = 0;

  int currentPage = 0;
  int pageSize = 10;
  int totalElements = 0;
  int totalPages = 0;

  int get blockedCountDisplay => _showBadge ? _realBlockedCount : 0;

  Future<void> getUsers({int page = 0, bool silent = false}) async {
    final token = LocalStorage.getToken();
    if (token == null) return;
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
      await checkBlockedCount();
    } catch (e) {
      debugPrint('Error cargando usuarios: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> checkBlockedCount() async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/usuarios/bloqueados/count',
      );
      _realBlockedCount = response.data;
      blockedCount = _realBlockedCount;

      final int lastSeen = LocalStorage.getLastSeenBlockedCount();

      if (_realBlockedCount > 0 && _realBlockedCount != lastSeen) {
        _showBadge = true;
      } else {
        _showBadge = false;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error comprobando bloqueados: $e');
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
      // Optimistic Update
      final index = usuarios.indexWhere((u) => u.idUsuario == id);
      if (index != -1) {
        if (filterActive == true) {
          usuarios.removeAt(index);
          totalElements--;
        } else {
          usuarios[index] = usuarios[index].copyWith(activo: false);
        }
        notifyListeners();
      }

      await ApiService.dio.delete('$_baseUrl/usuarios/$id');

      // Silent Refresh
      getUsers(page: currentPage, silent: true);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // REACTIVAR
  Future<String?> recoverUser(int id) async {
    try {
      // Optimistic Update
      final index = usuarios.indexWhere((u) => u.idUsuario == id);
      if (index != -1) {
        if (filterActive == false) {
          usuarios.removeAt(index);
          totalElements--;
        } else {
          usuarios[index] = usuarios[index].copyWith(activo: true);
        }
        notifyListeners();
      }

      await ApiService.dio.put('$_baseUrl/usuarios/$id/recuperar');

      // Silent Refresh
      getUsers(page: currentPage, silent: true);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // DESBLOQUEAR
  Future<String?> unlockUser(int id) async {
    try {
      // Optimistic Update
      final index = usuarios.indexWhere((u) => u.idUsuario == id);
      if (index != -1) {
        usuarios[index] = usuarios[index].copyWith(cuentaBloqueada: false);
        notifyListeners();
      }

      await ApiService.dio.put('$_baseUrl/usuarios/$id/desbloquear');

      // Silent Refresh
      getUsers(page: currentPage, silent: true);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // BLOQUEAR (Para deshacer desbloqueo)
  Future<String?> blockUser(int id) async {
    try {
      // Optimistic Update
      final index = usuarios.indexWhere((u) => u.idUsuario == id);
      if (index != -1) {
        usuarios[index] = usuarios[index].copyWith(cuentaBloqueada: true);
        notifyListeners();
      }

      await ApiService.dio.put('$_baseUrl/usuarios/$id/bloquear');

      // Silent Refresh
      getUsers(page: currentPage, silent: true);
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  bool _isFetchingMe = false;

  Future<void> getMe() async {
    final token = LocalStorage.getToken();
    if (token == null) return;
    if (_isFetchingMe) return;
    _isFetchingMe = true;
    isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.dio.get('$_baseUrl/usuarios/me');
      currentUser = Usuario.fromJson(response.data);
    } catch (e) {
      debugPrint('Error al cargar perfil: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      _isFetchingMe = false;
      notifyListeners();
    }
  }

  Future<String?> updateMyPassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/usuarios/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // --- Subida de foto R2 (JIT Proxy) ---
  Future<String?> uploadProfilePicture(PlatformFile file) async {
    if (currentUser == null) return "No hay usuario activo";
    isLoading = true;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!, 
          filename: file.name,
        )
      });
      await ApiService.dio.put(
        '$_baseUrl/usuarios/${currentUser!.idUsuario}/foto-perfil',
        data: formData,
      );
      
      // Actualizamos el flag local y rompemos la caché para que la recargue
      currentUser = currentUser!.copyWith(tieneFotoPerfil: true);
      profilePictureVersion = DateTime.now().millisecondsSinceEpoch;
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar avatar (persiste en localStorage)
  Future<void> updateAvatar(int index) async {
    avatarIndex = index;
    await LocalStorage.saveAvatarIndex(index);
    notifyListeners();
  }

  // Actualizar nombre del usuario en el backend
  Future<String?> updateMyProfile(String nombreCompleto) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/usuarios/me',
        data: {'nombreCompleto': nombreCompleto},
      );
      if (currentUser != null) {
        currentUser = currentUser!.copyWith(nombreCompleto: nombreCompleto);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  void clearAllData() {
    usuarios = [];
    currentUser = null;
    isLoading = false;
    _realBlockedCount = 0;
    _showBadge = false;
    blockedCount = 0;
    currentPage = 0;
    totalElements = 0;
    totalPages = 0;
    notifyListeners();
  }
}
