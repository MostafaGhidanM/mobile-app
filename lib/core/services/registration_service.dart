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
    debugPrint('[RegistrationService] Uploading national ID front image...');
    final frontImageData = kIsWeb ? nationalIdFrontBytes : nationalIdFront;
    final frontUploadResponse = await _uploadService.uploadImage(frontImageData!);
    if (!frontUploadResponse.isSuccess || frontUploadResponse.data == null) {
      debugPrint('[RegistrationService] Failed to upload front image: ${frontUploadResponse.error?.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: frontUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload front ID image',
        ),
      );
    }
    final frontImageUrl = frontUploadResponse.data!.url;
    debugPrint('[RegistrationService] Front image uploaded: $frontImageUrl');

    debugPrint('[RegistrationService] Uploading national ID back image...');
    final backImageData = kIsWeb ? nationalIdBackBytes : nationalIdBack;
    final backUploadResponse = await _uploadService.uploadImage(backImageData!);
    if (!backUploadResponse.isSuccess || backUploadResponse.data == null) {
      debugPrint('[RegistrationService] Failed to upload back image: ${backUploadResponse.error?.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: backUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload back ID image',
        ),
      );
    }
    final backImageUrl = backUploadResponse.data!.url;
    debugPrint('[RegistrationService] Back image uploaded: $backImageUrl');

    // Submit registration
    debugPrint('[RegistrationService] Submitting registration...');
    debugPrint('[RegistrationService] Full Name: $fullName');
    debugPrint('[RegistrationService] Mobile: $mobile');
    debugPrint('[RegistrationService] Activity Type IDs: $activityTypeIds');

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

    debugPrint('[RegistrationService] Registration response: ${response.isSuccess}');
    if (!response.isSuccess) {
      debugPrint('[RegistrationService] Registration error: ${response.error?.message}');
    }

    return response;
  }
}

