class ApiConfig {
  /// URL base para las peticiones HTTP de la API REST.
  /// Por defecto apunta a local (http://localhost:8080/api) para trabajar en tu máquina.
  /// Para producción, se sobreescribe mediante la variable de entorno:
  ///   --dart-define=API_URL=https://medicoxos-api.adrianaloper.es/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// URL de conexión para WebSockets (STOMP), adaptada automáticamente a wss:// o ws://
  static String get wsUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://').replaceAll('/api', '/ws-kiosk');
    }
    return baseUrl.replaceFirst('http://', 'ws://').replaceAll('/api', '/ws-kiosk');
  }
}
