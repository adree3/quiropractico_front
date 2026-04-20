import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/citas_kpi.dart';
import 'package:quiropractico_front/utils/error_handler.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import 'package:quiropractico_front/services/local_storage.dart';

class CitasProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<Cita> citas = [];
  CitasKpi? kpis;
  StompClient? _stompClient;

  bool isLoading = true;
  String? errorMessage;
  
  // Rastreo de firmas recibidas por WebSocket para evitar problemas de paginación
  final Set<int> _idCitasFirmadasRecientemente = {};

  String currentSearchTerm = '';
  String?
  filterEstado; // null, 'programada', 'completada', 'cancelada', 'ausente'
  DateTime? filterFechaInicio;
  DateTime? filterFechaFin;

  int currentPage = 0;
  int pageSize = 10;
  int totalPages = 0;
  int totalElements = 0;

  CitasProvider() {
    loadCitas(page: 0);
    _initWebSocket();
  }

  void _initWebSocket() {
    final String wsUrl = ApiConfig.baseUrl
        .replaceFirst('http', 'ws')
        .replaceAll('/api', '/ws-kiosk');

    final String? token = LocalStorage.getToken();

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          _stompClient?.subscribe(
            destination: '/topic/citas',
            callback: (frame) {
              if (frame.body != null) {
                final data = json.decode(frame.body!);
                
                if (data['action'] == 'CITA_FIRMADA') {
                  final idFirma = data['idCita'] is int ? data['idCita'] : int.tryParse(data['idCita'].toString());
                  if (idFirma != null) {
                    _idCitasFirmadasRecientemente.add(idFirma);
                    
                    // Actualización local en la lista si existe
                    final index = citas.indexWhere((c) => c.idCita == idFirma);
                    if (index != -1) {
                      citas[index] = citas[index].copyWith(firmada: true);
                    }
                    
                    notifyListeners();
                    // Refrescar la lista del servidor silenciosamente
                    loadCitas(page: currentPage, notifyLoading: false);
                  }
                }
              }
            },
          );
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onWebSocketError: (error) => print('WS Error en CitasProvider: $error'),
      ),
    );
    _stompClient?.activate();
  }

  bool isCitaFirmadaRecientemente(int idCita) {
    return _idCitasFirmadasRecientemente.contains(idCita);
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }

  Future<void> loadCitas({
    int page = 0,
    bool resetPage = false,
    bool notifyLoading = true,
  }) async {
    if (resetPage) currentPage = 0;
    if (notifyLoading) {
      isLoading = true;
      notifyListeners();
    }
    currentPage = page;
    errorMessage = null;

    try {
      final Map<String, dynamic> params = {
        'page': page,
        'size': pageSize,
        'sort': 'fechaHoraInicio,desc',
      };

      if (currentSearchTerm.isNotEmpty) params['search'] = currentSearchTerm;
      if (filterEstado != null) params['estado'] = filterEstado;
      if (filterFechaInicio != null)
        params['fechaInicio'] =
            filterFechaInicio!.toIso8601String().split('T')[0];
      if (filterFechaFin != null)
        params['fechaFin'] = filterFechaFin!.toIso8601String().split('T')[0];

      final response = await ApiService.dio.get(
        '$_baseUrl/citas',
        queryParameters: params,
      );

      final List<dynamic> data = response.data['content'];
      totalPages = response.data['totalPages'];
      totalElements = response.data['totalElements'];

      citas = data.map((json) => Cita.fromJson(json)).toList();

      // Load KPIs silently
      loadKpis();
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadKpis() async {
    try {
      final Map<String, dynamic> params = {};
      if (currentSearchTerm.isNotEmpty) params['search'] = currentSearchTerm;
      if (filterEstado != null) params['estado'] = filterEstado;
      if (filterFechaInicio != null)
        params['fechaInicio'] =
            filterFechaInicio!.toIso8601String().split('T')[0];
      if (filterFechaFin != null)
        params['fechaFin'] = filterFechaFin!.toIso8601String().split('T')[0];

      final response = await ApiService.dio.get(
        '$_baseUrl/citas/kpis',
        queryParameters: params,
      );

      kpis = CitasKpi.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando KPIs de Citas: $e');
    }
  }

  void setSearchTerm(String term) {
    currentSearchTerm = term;
    loadCitas(page: 0, resetPage: true);
  }

  void setFilterEstado(String? estado) {
    filterEstado = estado;
    loadCitas(page: 0, resetPage: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    filterFechaInicio = start;
    filterFechaFin = end;
    loadCitas(page: 0, resetPage: true);
  }

  void setPage(int newPage) {
    if (newPage >= 0 && newPage < totalPages) {
      loadCitas(page: newPage);
    }
  }

  Future<bool> changeCitaState(int idCita, String nuevoEstado) async {
    try {
      await ApiService.dio.patch(
        '$_baseUrl/citas/$idCita/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
      );
      await loadCitas(page: currentPage, notifyLoading: false);
      return true;
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> solicitarFirma(int idCita) async {
    try {
      await ApiService.dio.post('$_baseUrl/citas/$idCita/solicitar-firma');
      return true;
    } catch (e) {
      errorMessage = ErrorHandler.extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Recupera la URL pre-firmada del justificante de una cita
  Future<String?> obtenerUrlJustificante(int idCita) async {
    try {
      final response = await ApiService.dio.get('$_baseUrl/citas/$idCita/justificante');
      return response.data['url'];
    } catch (e) {
      debugPrint('Error obteniendo URL justificante: $e');
      return null;
    }
  }

  /// Recupera el historial plano de citas para cruce relacional (Ej: asociar documentos)
  Future<List<Cita>> fetchCitasCliente(int idCliente) async {
    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/citas/cliente/$idCliente',
        queryParameters: {'size': 500, 'sort': 'fechaHoraInicio,desc'},
      );
      final List<dynamic> data = response.data['content'];
      return data.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading client citas: $e');
      return [];
    }
  }
}
