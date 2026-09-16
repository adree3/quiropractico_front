import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cita_conflicto.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/familiar.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class ClientDetailProvider extends ChangeNotifier {
  
  final String _baseUrl = ApiConfig.baseUrl;

  Cliente? cliente;
  List<Cita> historialCitas = [];
  List<Bono> bonos = [];
  List<Familiar> familiares = [];
  
  bool isLoading = false;
  bool isLoadingCitas = false;
  bool isLoadingMoreCitas = false;
  bool hasMoreCitas = false;
  
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? filtroEstado;

  void setRangoFechas(DateTime? start, DateTime? end) {
    fechaInicio = start;
    fechaFin = end;
    notifyListeners();
  }

  void setFiltroEstado(String? estado) {
    filtroEstado = estado;
    notifyListeners();
  }

  Future<void> loadMoreCitas() async {
    isLoadingMoreCitas = false;
    notifyListeners();
  }

  Cita? get proximaCita {
    if (historialCitas.isEmpty) return null;
    return historialCitas.firstWhere((c) => c.fechaHoraInicio.isAfter(DateTime.now()), orElse: () => historialCitas.first);
  }

  Future<void> refreshClient() async {
    if (cliente != null) {
      await loadFullData(cliente!.idCliente);
    }
  }

  Future<String?> recoverClient([int? idCliente]) async {
    int targetId = idCliente ?? cliente?.idCliente ?? 0;
    if (targetId == 0) return "No hay cliente";
    try {
      await ApiService.dio.put('$_baseUrl/clientes/$targetId/recuperar');
      await refreshClient();
      return null;
    } catch (e) {
      debugPrint("Error al recuperar cliente: $e");
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> deleteClient([int? idCliente]) async {
    int targetId = idCliente ?? cliente?.idCliente ?? 0;
    if (targetId == 0) return "No hay cliente";
    try {
      await ApiService.dio.delete('$_baseUrl/clientes/$targetId');
      await refreshClient();
      return null;
    } catch (e) {
      debugPrint("Error al borrar cliente: $e");
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<void> loadFullData(int idCliente) async {
    isLoading = true;
    notifyListeners();

    try {
      // Cargar Cliente Básico
      final respCliente = await ApiService.dio.get('$_baseUrl/clientes/$idCliente');
      cliente = Cliente.fromJson(respCliente.data);

      // Cargar Historial Citas
      final respCitas = await ApiService.dio.get('$_baseUrl/citas/cliente/$idCliente');
      final dataCitas = respCitas.data is Map ? (respCitas.data['content'] ?? []) : respCitas.data;
      historialCitas = (dataCitas as List).map((e) => Cita.fromJson(e)).toList();

      // Cargar Bonos
      final respBonos = await ApiService.dio.get('$_baseUrl/bonos/cliente/$idCliente');
      final dataBonos = respBonos.data is Map ? (respBonos.data['content'] ?? []) : respBonos.data;
      bonos = (dataBonos as List).map((e) => Bono.fromJson(e)).toList();

      // Cargar Familia
      final respFamilia = await ApiService.dio.get('$_baseUrl/clientes/$idCliente/familiares');
      final dataFamilia = respFamilia.data is Map ? (respFamilia.data['content'] ?? []) : respFamilia.data;
      familiares = (dataFamilia as List).map((e) => Familiar.fromJson(e)).toList();
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
            
      await ApiService.dio.post(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares',
        queryParameters: {
          'idBeneficiario': idBeneficiario,
          'relacion': relacion
        }
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
      final response = await ApiService.dio.get(
        '$_baseUrl/familiares/$idGrupo/conflictos'
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

      await ApiService.dio.post(
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
      final respFamilia = await ApiService.dio.get(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares'
      );
      final dataFamilia = respFamilia.data is Map ? (respFamilia.data['content'] ?? []) : respFamilia.data;
      familiares = (dataFamilia as List).map((e) => Familiar.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print("Error recargando familiares: $e");
    }
  }
}