import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class StompService {
  StompService._internal();
  static final StompService _instance = StompService._internal();
  factory StompService() => _instance;
  static StompService get instance => _instance;

  StompClient? _stompClient;
  bool _isActivated = false;

  final List<void Function(Map<String, dynamic>)> _agendaListeners = [];
  StompUnsubscribe? _agendaSubscription;

  bool get isConnected => _stompClient?.connected ?? false;

  /// Inicializa y activa la conexión STOMP hacia el endpoint configurado (/ws-kiosk)
  void connect() {
    if (_isActivated && _stompClient != null) return;

    final token = LocalStorage.getToken();
    final wsUrl = ApiConfig.wsUrl;

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onDisconnect: (_) {
          _agendaSubscription = null;
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        stompConnectHeaders: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        onWebSocketError: (dynamic error) {
          debugPrint('STOMP WebSocket Error: $error');
        },
        onStompError: (StompFrame frame) {
          debugPrint('STOMP Protocol Error: ${frame.body}');
        },
      ),
    );

    _stompClient!.activate();
    _isActivated = true;

    if (kIsWeb) {
      html.window.onBeforeUnload.listen((event) {
        _stompClient?.deactivate();
      });
    }
  }

  void _onConnect(StompFrame frame) {
    _ensureAgendaSubscription();
  }

  void _ensureAgendaSubscription() {
    if (_stompClient == null || !_stompClient!.connected) return;
    if (_agendaSubscription != null || _agendaListeners.isEmpty) return;

    _agendaSubscription = _stompClient!.subscribe(
      destination: '/topic/agenda',
      callback: (StompFrame frame) {
        if (frame.body == null || frame.body!.isEmpty) return;
        try {
          final dynamic decoded = json.decode(frame.body!);
          if (decoded is Map<String, dynamic>) {
            for (final listener
                in List<void Function(Map<String, dynamic>)>.from(_agendaListeners)) {
              listener(decoded);
            }
          }
        } catch (e) {
          debugPrint('Error parseando evento STOMP en /topic/agenda: $e');
        }
      },
    );
  }

  /// Suscribe un callback a `/topic/agenda`.
  /// Devuelve un [VoidCallback] para dar de baja el listener cuando la vista se destruya.
  VoidCallback subscribeToAgenda(void Function(Map<String, dynamic>) onEvent) {
    if (!_agendaListeners.contains(onEvent)) {
      _agendaListeners.add(onEvent);
    }
    if (!_isActivated) {
      connect();
    } else {
      _ensureAgendaSubscription();
    }

    return () {
      _agendaListeners.remove(onEvent);
    };
  }

  void disconnect() {
    _agendaSubscription?.call();
    _agendaSubscription = null;
    _stompClient?.deactivate();
    _stompClient = null;
    _isActivated = false;
  }
}

