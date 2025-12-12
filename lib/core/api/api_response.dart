class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    if (json['success'] == true) {
      return ApiResponse<T>(
        success: true,
        message: json['message'],
        data: fromJsonT != null && json['data'] != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
        error: null,
      );
    } else {
      return ApiResponse<T>(
        success: false,
        message: json['message'],
        data: null,
        error: json['error'] != null
            ? ApiError.fromJson(json['error'])
            : null,
      );
    }
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}

class ApiError {
  final String code;
  final String message;
  final dynamic details;

  ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'An error occurred',
      details: json['details'],
    );
  }
}

