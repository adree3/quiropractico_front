import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/services/navigation_service.dart';

class ApiService {
  static final Dio _dio = Dio();

  static Future<void> configureDio() async {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Auth & Error Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Token vencido o invalido -> Logout forzado
            final context = NavigationService.navigatorKey.currentContext;
            if (context != null) {
              // Usamos false en listen porque estamos fuera del arbol de widgets
              Provider.of<AuthProvider>(context, listen: false).logout();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  static Dio get dio => _dio;
}
