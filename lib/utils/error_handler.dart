import 'package:dio/dio.dart';
import '../models/api_error.dart';

class ErrorHandler {
  static String extractMessage(Object error) {
    if (error is DioException) {
      // Error de respuesta del servidor 400 - 500
      if (error.response != null && error.response?.data != null) {
        try {
          final apiError = ApiError.fromJson(error.response!.data);
          return apiError.displayMessage; 
        } catch (e) {
          return "Error inesperado de red (${error.response?.statusCode})";
        }
      }
      
      // Errores de conexión
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return "No hay conexión con el servidor. Revisa tu internet.";
      }
    }

    // Error desconocido de programación
    return "Ocurrió un error inesperado: $error";
  }
}