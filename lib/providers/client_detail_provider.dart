import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cita_conflicto.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/familiar.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class ClientDetailProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  Cliente? cliente;
  List<Cita> historialCitas = [];
  List<Bono> bonos = [];
  List<Familiar> familiares = [];
  
  bool isLoading = true;

  // Helper para headers
  Options get _authOptions => Options(headers: {
    'Authorization': 'Bearer ${LocalStorage.getToken()}'
  });

  Future<void> loadFullData(int idCliente) async {
    isLoading = true;
    notifyListeners();

    try {
      // Cargar Cliente Básico
      final respCliente = await _dio.get('$_baseUrl/clientes/$idCliente', options: _authOptions);
      cliente = Cliente.fromJson(respCliente.data);

      // Cargar Historial Citas
      final respCitas = await _dio.get('$_baseUrl/citas/cliente/$idCliente', options: _authOptions);
      historialCitas = (respCitas.data as List).map((e) => Cita.fromJson(e)).toList();

      // Cargar Bonos
      final respBonos = await _dio.get('$_baseUrl/bonos/cliente/$idCliente', options: _authOptions);
      bonos = (respBonos.data as List).map((e) => Bono.fromJson(e)).toList();

      // Cargar Familia
      final respFamilia = await _dio.get('$_baseUrl/clientes/$idCliente/familiares', options: _authOptions);
      familiares = (respFamilia.data as List).map((e) => Familiar.fromJson(e)).toList();
    } catch (e) {
      print('Error cargando detalle: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> vincularFamiliar(int idBeneficiario, String relacion) async {
    try {
      if (cliente == null) return "No hay cliente seleccionado";
            
      await _dio.post(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares',
        queryParameters: {
          'idBeneficiario': idBeneficiario,
          'relacion': relacion
        },
        options: _authOptions
      );

      await _recargarFamiliares();
      return null;

    }catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Obitiene una lista de las citas pagadas por el grupo familiar que puedan entrar en conflicto
  Future<List<CitaConflicto>> obtenerConflictos(int idGrupo) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/familiares/$idGrupo/conflictos', 
        options: _authOptions
      );

      return (response.data as List).map((e) => CitaConflicto.fromJson(e)).toList();
    } catch (e) {
      print('Error obteniendo conflictos: $e');
      rethrow;
    }
  }

  // Desvincula al familiar indicado y cancela las citas cuyos IDs se pasen en la lista
  Future<String?> desvincularFamiliar(int idGrupo, List<int> idsCitasACancelar) async {
    try {
      final data = {
        "idsCitasACancelar": idsCitasACancelar
      };

      await _dio.post(
        '$_baseUrl/familiares/$idGrupo/desvincular',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer ${LocalStorage.getToken()}',
          'Content-Type': 'application/json',
        })
      );

      await _recargarFamiliares();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Helper para no repetir codigo de la recarga de familiares
  Future<void> _recargarFamiliares() async {
    if (cliente == null) return;
    try {
      final respFamilia = await _dio.get(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares', 
        options: _authOptions
      );
      familiares = (respFamilia.data as List).map((e) => Familiar.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print("Error recargando familiares: $e");
    }
  }
}