import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/bono.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/cita_conflicto.dart';
import 'package:quiropractico_front/models/cliente.dart';
import 'package:quiropractico_front/models/familiar.dart';

import 'package:quiropractico_front/utils/error_handler.dart';

class ClientDetailProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  Cliente? cliente;
  List<Cita> historialCitas = [];
  List<Bono> bonos = [];
  List<Familiar> familiares = [];

  // Carga inicial de toda la pantalla
  bool isLoading = true;
  // Recarga solo de citas
  bool isLoadingCitas = false;
  // Recarga solo datos del cliente
  bool isReloadingCliente = false;

  // Paginación Citas
  int citasPage = 0;
  final int citasPageSize = 15;
  bool hasMoreCitas = true;
  bool isLoadingMoreCitas = false;

  // Filtros
  String? filtroEstado;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  void setFiltroEstado(String? estado) {
    if (filtroEstado != estado) {
      filtroEstado = estado;
      loadCitas(resetPage: true);
    }
  }

  void setRangoFechas(DateTime? inicio, DateTime? fin) {
    fechaInicio = inicio;
    fechaFin = fin;
    loadCitas(resetPage: true);
  }

  /// Calcula la próxima cita futura confirmada (ordenada por fecha ascendente)
  Cita? get proximaCita {
    if (historialCitas.isEmpty) return null;

    final now = DateTime.now();
    // Filtramos citas futuras que no estén canceladas
    final futuras =
        historialCitas.where((c) {
          return c.fechaHoraInicio.isAfter(now) && c.estado != 'cancelada';
        }).toList();

    if (futuras.isEmpty) return null;

    // Ordenamos por fecha ascendente (la más próxima primero)
    futuras.sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

    return futuras.first;
  }

  /// Carga inicial de toda la pantalla
  Future<void> loadFullData(int idCliente) async {
    // Si ya tenemos datos de este cliente, no mostramos loading global
    if (cliente == null || cliente!.idCliente != idCliente) {
      isLoading = true;
      notifyListeners();
    }

    try {
      // Cliente
      await _fetchCliente(idCliente);

      // Citas (primera pagina)
      await loadCitas(resetPage: true, notify: false);

      // Bonos
      final respBonos = await ApiService.dio.get(
        '$_baseUrl/bonos/cliente/$idCliente',
      );
      bonos = (respBonos.data as List).map((e) => Bono.fromJson(e)).toList();

      // Familia
      await _recargarFamiliares(notify: false);
    } catch (e) {
      print('Error cargando detalle: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga solo los datos del cliente
  Future<void> refreshClient() async {
    if (cliente == null) return;
    isReloadingCliente = true;
    notifyListeners();

    try {
      await _fetchCliente(cliente!.idCliente);
    } catch (e) {
      print("Error refrescando cliente: $e");
    } finally {
      isReloadingCliente = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCliente(int id) async {
    final respCliente = await ApiService.dio.get('$_baseUrl/clientes/$id');
    cliente = Cliente.fromJson(respCliente.data);
  }

  /// Carga/Recarga la lista de citas
  /// [resetPage] true para volver a la página 0
  /// [notify] false si queremos evitar rebuilds intermedios
  Future<void> loadCitas({bool resetPage = true, bool notify = true}) async {
    if (cliente == null) return;

    if (notify) {
      isLoadingCitas = true;
      notifyListeners();
    }

    try {
      if (resetPage) {
        citasPage = 0;
        hasMoreCitas = true;
        historialCitas = [];
      }

      final Map<String, dynamic> queryParams = {
        'page': citasPage,
        'size': citasPageSize,
        'sort': 'fechaHoraInicio,desc',
      };

      if (filtroEstado != null && filtroEstado!.isNotEmpty) {
        queryParams['estado'] = filtroEstado;
      }

      if (fechaInicio != null) {
        queryParams['fechaInicio'] = DateFormat(
          'yyyy-MM-dd',
        ).format(fechaInicio!);
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = DateFormat('yyyy-MM-dd').format(fechaFin!);
      }

      final respCitas = await ApiService.dio.get(
        '$_baseUrl/citas/cliente/${cliente!.idCliente}',
        queryParameters: queryParams,
      );

      final List<dynamic> datosCitas =
          (respCitas.data is Map && respCitas.data.containsKey('content'))
              ? respCitas.data['content']
              : (respCitas.data is List ? respCitas.data : []);

      final nuevas = datosCitas.map((e) => Cita.fromJson(e)).toList();

      if (resetPage) {
        historialCitas = nuevas;
      } else {
        historialCitas.addAll(nuevas);
      }

      if (nuevas.length < citasPageSize) {
        hasMoreCitas = false;
      }
    } catch (e) {
      print("Error cargando citas: $e");
    } finally {
      if (notify) {
        isLoadingCitas = false;
        notifyListeners();
      }
    }
  }

  // Obitiene una lista de las citas pagadas por el grupo familiar que puedan entrar en conflicto
  Future<List<CitaConflicto>> obtenerConflictos(int idGrupo) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/familiares/$idGrupo/conflictos',
      );

      return (response.data as List)
          .map((e) => CitaConflicto.fromJson(e))
          .toList();
    } catch (e) {
      print('Error obteniendo conflictos: $e');
      rethrow;
    }
  }

  // Desvincula al familiar indicado y cancela las citas cuyos IDs se pasen en la lista
  Future<String?> desvincularFamiliar(
    int idGrupo,
    List<int> idsCitasACancelar, {
    bool undo = false,
  }) async {
    try {
      final data = {"idsCitasACancelar": idsCitasACancelar};

      await ApiService.dio.post(
        '$_baseUrl/familiares/$idGrupo/desvincular?undo=$undo',
        data: data,
      );

      await _recargarFamiliares();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Modificado: ahora acepta undo y devuelve String? error
  Future<String?> vincularFamiliar(
    int idFamiliar,
    String relacion, {
    bool undo = false,
    List<int>? idsCitasARestaurar,
  }) async {
    try {
      if (cliente == null) throw Exception("Cliente no cargado");

      final Map<String, dynamic> queryParams = {
        "idBeneficiario": idFamiliar,
        "relacion": relacion,
        "undo": undo,
      };

      if (idsCitasARestaurar != null && idsCitasARestaurar.isNotEmpty) {
        queryParams["idsCitasARestaurar"] = idsCitasARestaurar.join(",");
      }

      await ApiService.dio.post(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares',
        queryParameters: queryParams,
      );
      await _recargarFamiliares();
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  // Helper para no repetir codigo de la recarga de familiares
  Future<void> _recargarFamiliares({bool notify = true}) async {
    if (cliente == null) return;
    try {
      final respFamilia = await ApiService.dio.get(
        '$_baseUrl/clientes/${cliente!.idCliente}/familiares',
      );
      familiares =
          (respFamilia.data as List).map((e) => Familiar.fromJson(e)).toList();
      if (notify) notifyListeners();
    } catch (e) {
      print("Error recargando familiares: $e");
    }
  }

  Future<void> loadMoreCitas() async {
    if (cliente == null || isLoadingMoreCitas || !hasMoreCitas) return;

    isLoadingMoreCitas = true;
    notifyListeners();

    try {
      final nextPage = citasPage + 1;

      final Map<String, dynamic> queryParams = {
        'page': nextPage,
        'size': citasPageSize,
        'sort': 'fechaHoraInicio,desc',
      };

      if (filtroEstado != null && filtroEstado!.isNotEmpty) {
        queryParams['estado'] = filtroEstado;
      }

      if (fechaInicio != null) {
        queryParams['fechaInicio'] = DateFormat(
          'yyyy-MM-dd',
        ).format(fechaInicio!);
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = DateFormat('yyyy-MM-dd').format(fechaFin!);
      }

      final respCitas = await ApiService.dio.get(
        '$_baseUrl/citas/cliente/${cliente!.idCliente}',
        queryParameters: queryParams,
      );

      final List<dynamic> nuevosDatos =
          (respCitas.data is Map && respCitas.data.containsKey('content'))
              ? respCitas.data['content']
              : (respCitas.data is List ? respCitas.data : []);

      final nuevasCitas = nuevosDatos.map((e) => Cita.fromJson(e)).toList();

      if (nuevasCitas.isNotEmpty) {
        historialCitas.addAll(nuevasCitas);
        citasPage = nextPage;
      }

      if (nuevasCitas.length < citasPageSize) {
        hasMoreCitas = false;
      }
    } catch (e) {
      print('Error cargando más citas: $e');
    } finally {
      isLoadingMoreCitas = false;
      notifyListeners();
    }
  }

  // Borrado Lógico
  Future<String?> deleteClient(int idCliente, {bool undo = false}) async {
    try {
      await ApiService.dio.delete(
        '$_baseUrl/clientes/$idCliente',
        queryParameters: {'undo': undo},
      );
      if (cliente != null && cliente!.idCliente == idCliente) {
        cliente = cliente!.copyWith(activo: false);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }

  Future<String?> recoverClient(int idCliente, {bool undo = false}) async {
    try {
      await ApiService.dio.put(
        '$_baseUrl/clientes/$idCliente/recuperar',
        queryParameters: {'undo': undo},
      );
      if (cliente != null && cliente!.idCliente == idCliente) {
        cliente = cliente!.copyWith(activo: true);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return ErrorHandler.extractMessage(e);
    }
  }
}
