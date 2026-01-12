import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/services/navigation_service.dart';

class ApiService {
  static final Dio _dio = Dio();

  static Future<void> configureDio() async {
    // Cache Setup
    String? storagePath;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      storagePath = dir.path;
    }

    final cacheOptions = CacheOptions(
      store: HiveCacheStore(storagePath),
      policy: CachePolicy.refreshForceCache,
      hitCacheOnErrorExcept: [401, 403],
      priority: CachePriority.normal,
      maxStale: const Duration(days: 7),
    );

    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Cache Interceptor
    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

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
