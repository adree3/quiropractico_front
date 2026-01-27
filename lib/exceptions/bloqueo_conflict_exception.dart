class BloqueoConflictException implements Exception {
  final String code;
  final String message;

  BloqueoConflictException(this.code, this.message);

  @override
  String toString() => message;
}
