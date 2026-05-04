import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';

class ClinicaSettingsService {
  final String _baseUrl = ApiConfig.baseUrl;

  /// Obtiene la configuración de la clínica desde el backend
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/clinicas/settings');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error en la respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar la configuración de la clínica: $e');
    }
  }

  /// Actualiza la configuración de la clínica en el backend
  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.put(
        '$_baseUrl/clinicas/settings',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al guardar la configuración: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al guardar la configuración: $e');
    }
  }
}
