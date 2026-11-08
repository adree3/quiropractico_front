import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/services/navigation_service.dart';

import 'package:intl/intl.dart';
import 'package:quiropractico_front/models/arqueo_caja_dto.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

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
              Provider.of<AuthProvider>(context, listen: false).logout(context);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  static Dio get dio => _dio;

  static Map<String, String> getAuthHeaders() {
    final token = LocalStorage.getToken();
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  /// Obtiene la URL prefirmada de la factura asociada a un pago
  static Future<String?> obtenerUrlFactura(int idPago) async {
    try {
      final response = await _dio.get('/facturas/pagos/$idPago/url');
      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
      throw Exception('No se recibió una URL válida para la factura.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        String msg = 'Procesando documento en segundo plano...';
        if (e.response?.data != null) {
          if (e.response!.data is Map && e.response!.data['message'] != null) {
            msg = e.response!.data['message'].toString();
          } else if (e.response!.data is String && e.response!.data.toString().isNotEmpty) {
            msg = e.response!.data.toString();
          }
        }
        throw Exception(msg);
      }
      throw Exception(ErrorHandler.extractMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Obtiene el balance agregado diario (arqueo de caja) por método de pago
  static Future<ArqueoCajaDto?> obtenerArqueoDiario({DateTime? fecha}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (fecha != null) {
        queryParams['fecha'] = DateFormat('yyyy-MM-dd').format(fecha);
      }
      final response = await _dio.get(
        '/pagos/arqueo',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return ArqueoCajaDto.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      throw Exception(ErrorHandler.extractMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Reprograma una cita atómicamente (Drag & Drop y Resize)
  static Future<Cita> reprogramarCita(
    int idCita,
    DateTime inicio,
    DateTime fin, {
    int? idQuiropractico,
  }) async {
    try {
      final inicioStr = inicio.toIso8601String().split('.')[0];
      final finStr = fin.toIso8601String().split('.')[0];
      final Map<String, dynamic> data = {
        'fechaHoraInicio': inicioStr,
        'fechaHoraFin': finStr,
        if (idQuiropractico != null) 'idQuiropractico': idQuiropractico,
      };

      final response = await _dio.patch(
        '/citas/$idCita/reprogramar',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Cita.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('No se pudo reprogramar la cita.');
    } on DioException catch (e) {
      throw Exception(ErrorHandler.extractMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Obtiene los huecos disponibles para un profesional, fecha y duración específicos (filtro de duracionMinutos)
  static Future<Response> obtenerHuecosDisponibles({
    required int idQuiro,
    required String fecha,
    int? duracionMinutos,
    int? idCitaExcluir,
  }) async {
    final Map<String, dynamic> params = {
      'idQuiro': idQuiro,
      'fecha': fecha,
      if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
      if (idCitaExcluir != null) 'idCitaExcluir': idCitaExcluir,
    };

    return await _dio.get(
      '/citas/disponibilidad',
      queryParameters: params,
    );
  }
}
