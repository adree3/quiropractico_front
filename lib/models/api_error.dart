class ApiError {
  final String message;
  final String errorType;
  final int status;

  ApiError({
    required this.message,
    required this.errorType,
    required this.status,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Error desconocido',
      errorType: json['errorType'] ?? 'UNKNOWN_ERROR',
      status: json['status'] ?? 500,
    );
  }
}