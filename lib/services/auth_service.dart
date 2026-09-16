import 'package:dio/dio.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';

class AuthService {
  static final String _baseUrl = ApiConfig.baseUrl;

  static Future<Response> login(String username, String password, int? clinicaId) async {
    return await ApiService.dio.post(
      '$_baseUrl/auth/login',
      data: {
        'username': username,
        'password': password,
        'clinicaId': clinicaId,
      },
      options: Options(validateStatus: (status) => status! < 500),
    );
  }
}
