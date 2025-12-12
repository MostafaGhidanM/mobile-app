import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_response.dart';
import 'endpoints.dart';

class ApiClient {
  late Dio _dio;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Skip ngrok browser warning for mobile apps
          'ngrok-skip-browser-warning': 'true',
        },
        // For web, we might need to handle CORS differently
        validateStatus: (status) => status! < 500,
      ),
    );
    
    debugPrint('[ApiClient] Initialized with baseUrl: ${ApiEndpoints.baseUrl}');

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('[ApiClient] Request: ${options.method} ${options.baseUrl}${options.path}');
          debugPrint('[ApiClient] Headers: ${options.headers}');
          debugPrint('[ApiClient] Data: ${options.data}');
          // Add auth token to headers
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('[ApiClient] Added auth token to headers');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[ApiClient] Response: ${response.statusCode} ${response.statusMessage}');
          debugPrint('[ApiClient] Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[ApiClient] Error: ${error.type}');
          debugPrint('[ApiClient] Error message: ${error.message}');
          debugPrint('[ApiClient] Error response: ${error.response?.data}');
          debugPrint('[ApiClient] Error status code: ${error.response?.statusCode}');
          // Handle errors globally
          if (error.response?.statusCode == 401) {
            // Token expired or invalid - clear token
            _clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, token);
  }

  Future<void> clearToken() async {
    await _clearToken();
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(
          fieldName,
          await MultipartFile.fromFile(filePath),
        ),
      );

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(path, data: formData);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<T>> uploadBytes<T>(
    String path,
    Uint8List bytes, {
    String fieldName = 'file',
    String filename = 'image.jpg',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(
          fieldName,
          MultipartFile.fromBytes(
            bytes,
            filename: filename,
          ),
        ),
      );

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(path, data: formData);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    debugPrint('[ApiClient] _handleError called');
    debugPrint('[ApiClient] Error type: ${error.type}');
    debugPrint('[ApiClient] Error message: ${error.message}');
    debugPrint('[ApiClient] Error response: ${error.response}');
    debugPrint('[ApiClient] Error request options: ${error.requestOptions.uri}');
    
    if (error.response != null) {
      debugPrint('[ApiClient] Response status: ${error.response!.statusCode}');
      debugPrint('[ApiClient] Response data: ${error.response!.data}');
      try {
        return ApiResponse.fromJson(error.response!.data, null);
      } catch (e) {
        debugPrint('[ApiClient] Failed to parse error response: $e');
        return ApiResponse<T>(
          success: false,
          error: ApiError(
            code: 'HTTP_ERROR',
            message: error.response?.statusMessage ?? 'Request failed',
            details: error.response?.data,
          ),
        );
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      debugPrint('[ApiClient] Timeout error');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'TIMEOUT',
          message: 'Connection timeout. Please check your internet connection.',
        ),
      );
    } else if (error.type == DioExceptionType.connectionError) {
      debugPrint('[ApiClient] Connection error - CORS or network issue');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'CONNECTION_ERROR',
          message: 'Cannot connect to server. Please check if the backend is running and CORS is configured.',
          details: error.message,
        ),
      );
    } else {
      debugPrint('[ApiClient] Generic network error: ${error.type}');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network error. Please check your internet connection.',
          details: 'Error type: ${error.type}, Message: ${error.message}',
        ),
      );
    }
  }
}

