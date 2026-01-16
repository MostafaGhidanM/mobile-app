import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import 'upload_service.dart';

class RegistrationService {
  final ApiClient _apiClient = ApiClient();
  final UploadService _uploadService = UploadService();

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String fullName,
    required String mobile,
    File? nationalIdFront,
    File? nationalIdBack,
    Uint8List? nationalIdFrontBytes,
    Uint8List? nationalIdBackBytes,
    required List<String> activityTypeIds,
  }) async {
    // Upload images first
    final frontImageData = kIsWeb ? nationalIdFrontBytes : nationalIdFront;
    final frontUploadResponse = await _uploadService.uploadImage(frontImageData!);
    if (!frontUploadResponse.isSuccess || frontUploadResponse.data == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: frontUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload front ID image',
        ),
      );
    }
    final frontImageUrl = frontUploadResponse.data!.url;

    final backImageData = kIsWeb ? nationalIdBackBytes : nationalIdBack;
    final backUploadResponse = await _uploadService.uploadImage(backImageData!);
    if (!backUploadResponse.isSuccess || backUploadResponse.data == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: backUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload back ID image',
        ),
      );
    }
    final backImageUrl = backUploadResponse.data!.url;

    // Submit registration
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.registrationCreate,
      data: {
        'fullName': fullName,
        'mobile': mobile,
        'nationalIdFront': frontImageUrl,
        'nationalIdBack': backImageUrl,
        'activityTypeIds': activityTypeIds,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    return response;
  }
}

