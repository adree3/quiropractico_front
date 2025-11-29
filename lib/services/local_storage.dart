import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences prefs;

  // Inicializamos las preferencias
  static Future<void> configurePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Guardar Token
  static Future<void> saveToken(String token) async {
    await prefs.setString('token', token);
  }

  // Leer Token
  static String? getToken() {
    return prefs.getString('token');
  }

  // Borrar Token (Logout)
  static Future<void> deleteToken() async {
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // Guardar Rol
  static Future<void> saveRole(String role) async {
    await prefs.setString('role', role);
  }

  // Leer Rol
  static String? getRole() {
    return prefs.getString('role');
  }
 
}