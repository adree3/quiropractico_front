import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
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
  List<BonoHistorico> bonos = [];
  List<Familiar> familiares = [];
  
  bool isLoading = false;
  bool isLoadingCitas = false;
  bool isLoadingMoreCitas = false;
  bool hasMoreCitas = false;
  int _citasPage = 0;
  
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? filtroEstado;

  void setRangoFechas(DateTime? start, DateTime? end) {
    fechaInicio = start;
    fechaFin = end;
    notifyListeners();
    refreshCitas(silent: true);
  }

  void setFiltroEstado(String? estado) {
    filtroEstado = estado;
    notifyListeners();
    refreshCitas(silent: true);
  }

  Future<void> loadMoreCitas() async {
    if (isLoadingMoreCitas || !hasMoreCitas) return;
    isLoadingMoreCitas = true;
    notifyListeners();
    await refreshCitas(silent: true, isLoadMore: true);
  }

  List<Cita> get filteredCitas {
    return historialCitas.where((cita) {
      bool matchesEstado = true;
      if (filtroEstado != null) {
        matchesEstado = cita.estado.toLowerCase() == filtroEstado!.toLowerCase();
      }

      bool matchesFecha = true;
      if (fechaInicio != null) {
        final citaDate = DateTime(cita.fechaHoraInicio.year, cita.fechaHoraInicio.month, cita.fechaHoraInicio.day);
        final start = DateTime(fechaInicio!.year, fechaInicio!.month, fechaInicio!.day);
        
        if (fechaFin != null) {
          final end = DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day);
          matchesFecha = (citaDate.isAtSameMomentAs(start) || citaDate.isAfter(start)) && 
                         (citaDate.isAtSameMomentAs(end) || citaDate.isBefore(end));
        } else {
          matchesFecha = citaDate.isAtSameMomentAs(start);
        }
      }

      return matchesEstado && matchesFecha;
    }).toList();
  }



  Future<void> refreshCliente({bool silent = true}) async {
    if (cliente == null) return;
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final respCliente = await ApiService.dio.get('$_baseUrl/clientes/${cliente!.idCliente}');
      cliente = Cliente.fromJson(respCliente.data);
    } catch (e) {
      debugPrint('Error refreshCliente: $e');
    } finally {
      if (!silent) isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCitas({bool silent = true, bool isLoadMore = false}) async {
    if (cliente == null) return;
    if (!silent && !isLoadMore) {
      isLoading = true;
      notifyListeners();
    }
    try {
      if (!isLoadMore) {
        _citasPage = 0;
      }
      final Map<String, dynamic> params = {
        'page': _citasPage,
        'size': 15,
        'sort': 'fechaHoraInicio,desc',
      };
      if (filtroEstado != null) params['estado'] = filtroEstado;
      if (fechaInicio != null) params['fechaInicio'] = fechaInicio!.toIso8601String().split('T')[0];
      if (fechaFin != null) params['fechaFin'] = fechaFin!.toIso8601String().split('T')[0];

      final respCitas = await ApiService.dio.get('$_baseUrl/citas/cliente/${cliente!.idCliente}', queryParameters: params);
      
      final dataCitasMap = respCitas.data is Map ? respCitas.data : {};
      final List dataCitas = dataCitasMap['content'] ?? (respCitas.data is List ? respCitas.data : []);
      
      final isLast = dataCitasMap['last'] ?? (dataCitas.length < 15);
      hasMoreCitas = !isLast;

      final nuevasCitas = dataCitas.map((e) => Cita.fromJson(e)).toList();
      
      if (isLoadMore) {
        historialCitas.addAll(nuevasCitas);
      } else {
        historialCitas = nuevasCitas;
      }

      if (!isLast) {
        _citasPage++;
      }

    } catch (e) {
      debugPrint('Error refreshCitas: $e');
    } finally {
      if (!silent) isLoading = false;
      if (isLoadMore) isLoadingMoreCitas = false;
      notifyListeners();
    }
  }

  Future<void> refreshBonos({bool silent = true}) async {
    if (cliente == null) return;
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final respBonos = await ApiService.dio.get('$_baseUrl/bonos/cliente/${cliente!.idCliente}');
      final dataBonos = respBonos.data is Map ? (respBonos.data['content'] ?? []) : respBonos.data;
      bonos = (dataBonos as List).map((e) => BonoHistorico.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error refreshBonos: $e');
    } finally {
      if (!silent) isLoading = false;
      notifyListeners();
      // Refrescamos silenciosamente el cliente para que se sincronicen los KPIs (deuda, bonos activos, etc.)
      refreshCliente(silent: true);
    }
  }

  Future<void> refreshFamiliares({bool silent = true}) async {
    if (cliente == null) return;
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final respFamilia = await ApiService.dio.get('$_baseUrl/clientes/${cliente!.idCliente}/familiares');
      final dataFamilia = respFamilia.data is Map ? (respFamilia.data['content'] ?? []) : respFamilia.data;
      familiares = (dataFamilia as List).map((e) => Familiar.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error refreshFamiliares: $e');
    } finally {
      if (!silent) isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> recoverClient([int? idCliente]) async {
    int targetId = idCliente ?? cliente?.idCliente ?? 0;
    if (targetId == 0) return "No hay cliente";
    try {
      await ApiService.dio.put('$_baseUrl/clientes/$targetId/recuperar');
      await loadFullData(targetId);
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
      await loadFullData(targetId);
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
      // Ejecutar peticiones en paralelo para que sea más rápido
      final responses = await Future.wait([
        ApiService.dio.get('$_baseUrl/clientes/$idCliente'),
        ApiService.dio.get('$_baseUrl/citas/cliente/$idCliente'),
        ApiService.dio.get('$_baseUrl/bonos/cliente/$idCliente'),
        ApiService.dio.get('$_baseUrl/clientes/$idCliente/familiares'),
      ]);

      cliente = Cliente.fromJson(responses[0].data);
      
      final dataCitas = responses[1].data is Map ? (responses[1].data['content'] ?? []) : responses[1].data;
      historialCitas = (dataCitas as List).map((e) => Cita.fromJson(e)).toList();
      
      final dataBonos = responses[2].data is Map ? (responses[2].data['content'] ?? []) : responses[2].data;
      bonos = (dataBonos as List).map((e) => BonoHistorico.fromJson(e)).toList();
      
      final dataFamilia = responses[3].data is Map ? (responses[3].data['content'] ?? []) : responses[3].data;
      familiares = (dataFamilia as List).map((e) => Familiar.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error cargando detalle: ${ErrorHandler.extractMessage(e)}');
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
    await refreshFamiliares();
  }

  /// Solicita la firma del documento LOPD en el Kiosco
  Future<String?> solicitarFirmaLopd(int idCliente) async {
    try {
      await ApiService.dio.post('$_baseUrl/clientes/$idCliente/solicitar-firma-lopd');
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        try {
          await ApiService.dio.post('$_baseUrl/clientes/$idCliente/solicitar-lopd');
          return null;
        } catch (inner) {
          return ErrorHandler.extractMessage(inner);
        }
      }
      return ErrorHandler.extractMessage(e);
    }
  }

  /// Marca localmente la LOPD como firmada de forma reactiva
  void marcarLopdFirmada() {
    if (cliente != null && !cliente!.lopdFirmada) {
      cliente = cliente!.copyWith(lopdFirmada: true);
      notifyListeners();
    }
  }
}