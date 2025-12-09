import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cita_conflicto.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/familiar.dart';
import 'package:quiropractico_front/services/local_storage.dart';

class ClientDetailProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api';

  Cliente? cliente;
  List<Cita> historialCitas = [];
  List<Bono> bonos = [];
  List<Familiar> familiares = [];
  
  bool isLoading = true;

  Future<void> loadFullData(int idCliente) async {
    isLoading = true;
    notifyListeners();

    try {
      final token = LocalStorage.getToken();
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      // Cargar Cliente Básico
      final respCliente = await _dio.get('$_baseUrl/clientes/$idCliente', options: options);
      cliente = Cliente.fromJson(respCliente.data);

      // Cargar Historial Citas
      final respCitas = await _dio.get('$_baseUrl/citas/cliente/$idCliente', options: options);
      historialCitas = (respCitas.data as List).map((e) => Cita.fromJson(e)).toList();

      // Cargar Bonos
      final respBonos = await _dio.get('$_baseUrl/bonos/cliente/$idCliente', options: options);
      bonos = (respBonos.data as List).map((e) => Bono.fromJson(e)).toList();

      // Cargar Familia
      final respFamilia = await _dio.get('$_baseUrl/clientes/$idCliente/familiares', options: options);
      familiares = (respFamilia.data as List).map((e) => Familiar.fromJson(e)).toList();

    } catch (e) {
      print('Error cargando detalle: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> vincularFamiliar(int idBeneficiario, String relacion) async {
    try {
      if (cliente == null) return false;
      
      final token = LocalStorage.getToken();
      
      await _dio.post(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares',
        queryParameters: {
          'idBeneficiario': idBeneficiario,
          'relacion': relacion
        },
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      await _recargarFamiliares(token!);
      
      return true;

    } catch (e) {
      print('Error vinculando familiar: $e');
      return false;
    }
  }

  // Obitiene una lista de las citas pagadas por el grupo familiar que puedan entrar en conflicto
  Future<List<CitaConflicto>> obtenerConflictos(int idGrupo) async {
    try {
      final token = LocalStorage.getToken();
      final response = await _dio.get(
        '$_baseUrl/familiares/$idGrupo/conflictos', 
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return (response.data as List).map((e) => CitaConflicto.fromJson(e)).toList();
    } catch (e) {
      print('Error obteniendo conflictos: $e');
      rethrow;
    }
  }

  // Desvincula al familiar indicado y cancela las citas cuyos IDs se pasen en la lista
  Future<bool> desvincularFamiliar(int idGrupo, List<int> idsCitasACancelar) async {
    try {
      final token = LocalStorage.getToken();

      final data = {
        "idsCitasACancelar": idsCitasACancelar
      };

      await _dio.post(
        '$_baseUrl/familiares/$idGrupo/desvincular',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
      );

      await _recargarFamiliares(token!);
      
      return true;
    } catch (e) {
      print('Error desvinculando: $e');
      return false;
    }
  }

  // Helper para no repetir codigo de la recarga de familiares
  Future<void> _recargarFamiliares(String token) async {
     if (cliente == null) return;
     final respFamilia = await _dio.get(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares', 
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      familiares = (respFamilia.data as List).map((e) => Familiar.fromJson(e)).toList();
      notifyListeners();
  }
}