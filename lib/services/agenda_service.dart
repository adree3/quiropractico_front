import 'package:dio/dio.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';

class AgendaService {
  static final String _baseUrl = ApiConfig.baseUrl;

  static Future<Response> getCitasDelDia(Map<String, dynamic> params) async {
    return await ApiService.dio.get(
      '$_baseUrl/citas/agenda', 
      queryParameters: params
    );
  }

  static Future<Response> getCitasPorRango(Map<String, dynamic> params) async {
    return await ApiService.dio.get(
      '$_baseUrl/citas/rango', 
      queryParameters: params
    );
  }

  static Future<Response> crearCita(Map<String, dynamic> data) async {
    return await ApiService.dio.post(
      '$_baseUrl/citas', 
      data: data
    );
  }

  static Future<Response> getQuiropracticosActivos() async {
    return await ApiService.dio.get(
      '$_baseUrl/usuarios/quiros-activos'
    );
  }

  static Future<Response> cambiarEstadoCita(int idCita, String nuevoEstado) async {
    return await ApiService.dio.patch(
      '$_baseUrl/citas/$idCita/estado', 
      queryParameters: {'nuevoEstado': nuevoEstado}
    );
  }

  static Future<Response> cancelarCita(int idCita) async {
    return await ApiService.dio.put(
      '$_baseUrl/citas/$idCita/cancelar'
    );
  }

  static Future<Response> solicitarFirma(int idCita) async {
    return await ApiService.dio.post(
      '$_baseUrl/citas/$idCita/solicitar-firma'
    );
  }

  static Future<Response> editarCita(int idCita, Map<String, dynamic> data) async {
    return await ApiService.dio.put(
      '$_baseUrl/citas/$idCita', 
      data: data
    );
  }

  static Future<Response> getDisponibilidad(Map<String, dynamic> params) async {
    return await ApiService.dio.get(
      '$_baseUrl/citas/disponibilidad', 
      queryParameters: params
    );
  }
}
