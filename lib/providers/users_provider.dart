import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class UsersProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  List<Usuario> usuarios = [];
  bool isLoading = true;
  bool? filterActive = true;

  UsersProvider() {
    getUsers();
  }

  Future<void> getUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final token = LocalStorage.getToken();
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
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      
      final List<dynamic> data = response.data['content'];
      usuarios = data.map((e) => Usuario.fromJson(e)).toList();

    } catch (e) {
      print('Error cargando usuarios: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Filro de activos/inactivos/todos
  void setFilter(bool? active) {
    filterActive = active;
    getUsers();
  }

  // CREAR
  Future<bool> createUser(String nombre, String username, String password, String rol) async {
    try {
      final token = LocalStorage.getToken();
      final data = {
        "nombreCompleto": nombre,
        "username": username,
        "password": password,
        "rol": rol
      };
      await _dio.post('$_baseUrl/usuarios', data: data, options: Options(headers: {'Authorization': 'Bearer $token'}));
      await getUsers();
      return true;
    } catch (e) { return false; }
  }

  // EDITAR
  Future<bool> updateUser(int id, String nombre, String? password, String rol) async {
    try {
      final token = LocalStorage.getToken();
      final data = {
        "nombreCompleto": nombre,
        "rol": rol,
        if (password != null && password.isNotEmpty) "password": password
      };
      await _dio.put('$_baseUrl/usuarios/$id', data: data, options: Options(headers: {'Authorization': 'Bearer $token'}));
      await getUsers();
      return true;
    } catch (e) { return false; }
  }

  // DESACTIVAR
  Future<bool> deleteUser(int id) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.delete('$_baseUrl/usuarios/$id', options: Options(headers: {'Authorization': 'Bearer $token'}));
      await getUsers();
      return true;
    } catch (e) { return false; }
  }

  // REACTIVAR
  Future<bool> recoverUser(int id) async {
    try {
      final token = LocalStorage.getToken();
      await _dio.put('$_baseUrl/usuarios/$id/recuperar', options: Options(headers: {'Authorization': 'Bearer $token'}));
      await getUsers();
      return true;
    } catch (e) { return false; }
  }
}