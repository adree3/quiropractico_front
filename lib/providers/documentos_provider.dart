import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/documento.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class DocumentosProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Documento> documentos = [];
  bool isLoading = false;
  bool isUploading = false;
  String? errorMessage;

  /// Carga la lista de documentos de un cliente (sin URLs temporales)
  Future<void> loadDocumentos(int idCliente) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.dio.get('$_baseUrl/documentos/clientes/$idCliente');
      final data = response.data as List;
      documentos = data.map((e) => Documento.fromJson(e)).toList();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      debugPrint('Error cargando documentos: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Obtiene los documentos vinculados a una cita específica
  Future<List<Documento>> getDocumentosCita(int idCita) async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/documentos/citas/$idCita');
      final data = response.data as List;
      return data.map((e) => Documento.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error obteniendo documentos de cita: ${ErrorHandler.extractMessage(e)}');
      return [];
    }
  }

  /// Sube un documento a R2 utilizando la llamada Multipart. 
  /// Soporta envío de bytes directo para compatibilidad con Web y Desktop.
  Future<String?> subirDocumento({
    required int idCliente,
    required List<int> bytes,
    required String filename,
    required String tipoDocumento,
    int? idCita,
    int? idPago,
    String? notas,
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      // El tipo y los meta-datos relacionales se pasan como query parameters
      String url = '$_baseUrl/documentos/clientes/$idCliente?tipo=$tipoDocumento';
      if (idCita != null) url += '&idCita=$idCita';
      if (idPago != null) url += '&idPago=$idPago';
      if (notas != null && notas.isNotEmpty) url += '&notas=${Uri.encodeComponent(notas)}';

      final response = await ApiService.dio.post(url, data: formData);
      
      if (response.statusCode == 200) {
        final nuevoDoc = Documento.fromJson(response.data);
        // Insertamos el más reciente arriba
        documentos.insert(0, nuevoDoc);
        return null; // OK
      }
      return 'Error desconocido al subir archivo.';
    } catch (e) {
      final msg = ErrorHandler.extractMessage(e);
      return msg;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<String?> obtenerUrlTemporal(int idDocumento, {bool download = false}) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/documentos/$idDocumento/url',
        queryParameters: {'download': download},
      );
      // Aseguramos que se devuelve como un String limpio
      return response.data.toString();
    } catch (e) {
      debugPrint('Error obteniendo URL JIT: ${ErrorHandler.extractMessage(e)}');
      return null;
    }
  }

  /// Realiza el borrado lógico del documento
  Future<String?> eliminarDocumento(int idDocumento) async {
    try {
      await ApiService.dio.delete('$_baseUrl/documentos/$idDocumento');
      // Lo eliminamos localmente de la lista para actualizar la UI sin recargar
      documentos.removeWhere((d) => d.idDocumento == idDocumento);
      notifyListeners();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  /// Actualiza notas, cita y/o pago de un documento
  Future<String?> actualizarMetadatos(int idDocumento, {int? idCita, int? idPago, String? notas}) async {
    try {
      String url = '$_baseUrl/documentos/$idDocumento';
      Map<String, dynamic> params = {};
      if (idCita != null) params['idCita'] = idCita;
      if (idPago != null) params['idPago'] = idPago;
      if (notas != null) params['notas'] = notas;

      final response = await ApiService.dio.patch(url, queryParameters: params);
      
      if (response.statusCode == 200) {
        final docActualizado = Documento.fromJson(response.data);
        final index = documentos.indexWhere((d) => d.idDocumento == idDocumento);
        if (index != -1) {
          documentos[index] = docActualizado;
          notifyListeners();
        }
        return null;
      }
      return 'Error al actualizar el documento.';
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  /// RESTAURA un documento eliminado lógicamente devolviéndolo a activo=true
  Future<String?> restaurarDocumento(int idDocumento) async {
    try {
      String url = '$_baseUrl/documentos/$idDocumento/restaurar';
      final response = await ApiService.dio.patch(url);

      if (response.statusCode == 200) {
        final docActualizado = Documento.fromJson(response.data);
        documentos.insert(0, docActualizado);
        notifyListeners();
        return null;
      }
      return 'Error al restaurar el documento.';
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  /// Obtiene de forma asíncrona todos los documentos en papelera (activo=false)
  Future<List<Documento>> obtenerPapelera(int idCliente) async {
    final response = await ApiService.dio.get('$_baseUrl/documentos/clientes/$idCliente/papelera');
    final data = response.data as List;
    return data.map((e) => Documento.fromJson(e)).toList();
  }
}
