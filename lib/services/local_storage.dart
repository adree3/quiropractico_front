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

  // Borrar Token y Rol (Logout)
  static Future<void> deleteToken() async {
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // Guardar ID, Nombre y Dirección de Clínica
  static Future<void> saveClinica(int clinicaId, String clinicaNombre, String clinicaDireccion) async {
    await prefs.setInt('clinicaId', clinicaId);
    await prefs.setString('clinicaNombre', clinicaNombre);
    await prefs.setString('clinicaDireccion', clinicaDireccion);
  }

  // Obtener ID de Clínica
  static int? getClinicaId() {
    return prefs.getInt('clinicaId');
  }

  // Obtener Nombre de Clínica
  static String? getClinicaNombre() {
    return prefs.getString('clinicaNombre');
  }

  // Obtener Dirección de Clínica
  static String? getClinicaDireccion() {
    return prefs.getString('clinicaDireccion');
  }

  // Borrar Clínica (Cambiar de Espacio)
  static Future<void> clearClinica() async {
    await prefs.remove('clinicaId');
    await prefs.remove('clinicaNombre');
    await prefs.remove('clinicaDireccion');
  }

  // Guardar Rol
  static Future<void> saveRole(String role) async {
    await prefs.setString('role', role);
  }

  // Leer Rol
  static String? getRole() {
    return prefs.getString('role');
  }

  static Future<void> saveLastSeenBlockedCount(int count) async {
    await prefs.setInt('lastSeenBlockedCount', count);
  }

  static int getLastSeenBlockedCount() {
    return prefs.getInt('lastSeenBlockedCount') ?? -1;
  }

  // Avatar de usuario (índice 0-11)
  static Future<void> saveAvatarIndex(int index) async {
    await prefs.setInt('avatarIndex', index);
  }

  static int getAvatarIndex() {
    return prefs.getInt('avatarIndex') ?? 0;
  }

  // Vista por defecto de la agenda
  static Future<void> saveDefaultAgendaView(String view) async {
    await prefs.setString('defaultAgendaView', view);
  }

  static String getDefaultAgendaView() {
    return prefs.getString('defaultAgendaView') ?? 'day';
  }
}