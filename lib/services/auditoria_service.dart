import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';

class AuditoriaService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/auditoria';

  static Future<Map<String, dynamic>> getLogs(Map<String, dynamic> query) async {
    try {
      final response = await ApiService.dio.get(
        _baseUrl,
        queryParameters: query,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
