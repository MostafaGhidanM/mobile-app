import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/recycling_unit.dart';
import 'upload_service.dart';

class RecyclingUnitService {
  final ApiClient _apiClient = ApiClient();
  final UploadService _uploadService = UploadService();

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String unitName,
    required String phoneNumber,
    required String unitOwnerName,
    required String password,
    required String confirmPassword,
    required String gender, // MALE or FEMALE
    required String unitAddress,
    required String wasteTypeId,
    required String unitType, // PRESS, SHREDDER, or WASHING_LINE
    required int workersCount,
    required int machinesCount,
    required double stationCapacity,
    // ID Card Images
    File? idCardFrontFile,
    Uint8List? idCardFrontBytes,
    File? idCardBackFile,
    Uint8List? idCardBackBytes,
    // Conditional Images
    File? rentalContractFile,
    Uint8List? rentalContractBytes,
    File? commercialRegisterFile,
    Uint8List? commercialRegisterBytes,
    File? taxCardFile,
    Uint8List? taxCardBytes,
    // Optional
    Map<String, double>? geoLocation,
  }) async {
    // Upload ID card front image
    final frontImageData = kIsWeb ? idCardFrontBytes : idCardFrontFile;
    if (frontImageData == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiError(
          code: 'VALIDATION_ERROR',
          message: 'ID card front image is required',
        ),
      );
    }
    final frontUploadResponse = await _uploadService.uploadImage(frontImageData);
    if (!frontUploadResponse.isSuccess || frontUploadResponse.data == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: frontUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload ID card front image',
        ),
      );
    }
    final idCardFrontImage = frontUploadResponse.data!.url;

    // Upload ID card back image
    final backImageData = kIsWeb ? idCardBackBytes : idCardBackFile;
    if (backImageData == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiError(
          code: 'VALIDATION_ERROR',
          message: 'ID card back image is required',
        ),
      );
    }
    final backUploadResponse = await _uploadService.uploadImage(backImageData);
    if (!backUploadResponse.isSuccess || backUploadResponse.data == null) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: backUploadResponse.error ?? ApiError(
          code: 'UPLOAD_ERROR',
          message: 'Failed to upload ID card back image',
        ),
      );
    }
    final idCardBackImage = backUploadResponse.data!.url;

    // Upload conditional images based on unit type
    String? rentalContractImage;
    String? commercialRegisterImage;
    String? taxCardImage;

    if (unitType == 'PRESS') {
      // PRESS requires rental contract
      if (rentalContractFile == null && rentalContractBytes == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: ApiError(
            code: 'VALIDATION_ERROR',
            message: 'Rental contract image is required for PRESS units',
          ),
        );
      }
      final rentalData = kIsWeb ? rentalContractBytes : rentalContractFile;
      final rentalResponse = await _uploadService.uploadImage(rentalData!);
      if (!rentalResponse.isSuccess || rentalResponse.data == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: rentalResponse.error ?? ApiError(
            code: 'UPLOAD_ERROR',
            message: 'Failed to upload rental contract image',
          ),
        );
      }
      rentalContractImage = rentalResponse.data!.url;
    } else if (unitType == 'WASHING_LINE' || unitType == 'SHREDDER') {
      // WASHING_LINE and SHREDDER require commercial register and tax card
      if (commercialRegisterFile == null && commercialRegisterBytes == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: ApiError(
            code: 'VALIDATION_ERROR',
            message: 'Commercial register image is required for $unitType units',
          ),
        );
      }
      if (taxCardFile == null && taxCardBytes == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: ApiError(
            code: 'VALIDATION_ERROR',
            message: 'Tax card image is required for $unitType units',
          ),
        );
      }

      final commercialData = kIsWeb ? commercialRegisterBytes : commercialRegisterFile;
      final commercialResponse = await _uploadService.uploadImage(commercialData!);
      if (!commercialResponse.isSuccess || commercialResponse.data == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: commercialResponse.error ?? ApiError(
            code: 'UPLOAD_ERROR',
            message: 'Failed to upload commercial register image',
          ),
        );
      }
      commercialRegisterImage = commercialResponse.data!.url;

      final taxData = kIsWeb ? taxCardBytes : taxCardFile;
      final taxResponse = await _uploadService.uploadImage(taxData!);
      if (!taxResponse.isSuccess || taxResponse.data == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: taxResponse.error ?? ApiError(
            code: 'UPLOAD_ERROR',
            message: 'Failed to upload tax card image',
          ),
        );
      }
      taxCardImage = taxResponse.data!.url;
    }

    // Prepare registration data
    final registrationData = <String, dynamic>{
      'unitName': unitName,
      'phoneNumber': phoneNumber,
      'unitOwnerName': unitOwnerName,
      'password': password,
      'confirmPassword': confirmPassword,
      'idCardFrontImage': idCardFrontImage,
      'idCardBackImage': idCardBackImage,
      'gender': gender,
      'unitAddress': unitAddress,
      'wasteTypeId': wasteTypeId,
      'unitType': unitType,
      'workersCount': workersCount,
      'machinesCount': machinesCount,
      'stationCapacity': stationCapacity,
    };

    if (rentalContractImage != null) {
      registrationData['rentalContractImage'] = rentalContractImage;
    }
    if (commercialRegisterImage != null) {
      registrationData['commercialRegisterImage'] = commercialRegisterImage;
    }
    if (taxCardImage != null) {
      registrationData['taxCardImage'] = taxCardImage;
    }
    if (geoLocation != null) {
      registrationData['geoLocation'] = geoLocation;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.recyclingUnitsRegister,
      data: registrationData,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    return response;
  }

  Future<ApiResponse<List<RecyclingUnit>>> getRecyclingUnits({
    String? unitType,
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (unitType != null) {
      queryParams['unitType'] = unitType;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.recyclingUnits,
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      // Handle different response formats:
      // 1. Paginated: { items: [...], total: X }
      // 2. Direct array in data: { data: [...] }
      List<dynamic>? itemsList;
      if (data.containsKey('items')) {
        // Paginated response
        itemsList = data['items'] as List<dynamic>?;
      } else if (data.containsKey('data')) {
        // Response with data wrapper
        final dataField = data['data'];
        if (dataField is List) {
          itemsList = dataField;
        }
      }
      
      final items = itemsList
              ?.map((item) => RecyclingUnit.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<RecyclingUnit>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<RecyclingUnit>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }

  Future<ApiResponse<RecyclingUnit>> getCurrentUnit() async {
    // Try to get current unit from auth check endpoint
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/check',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    // If that doesn't work, we'll need to fetch from recycling units list
    // For now, return error and let the caller handle it
    if (response.isSuccess && response.data != null) {
      // The check endpoint might not return full unit data
      // We'll need to fetch from the recycling units endpoint with the current unit ID
      // This is a placeholder - the actual implementation depends on available endpoints
    }

    return ApiResponse<RecyclingUnit>(
      success: false,
      error: ApiError(
        code: 'NOT_IMPLEMENTED',
        message: 'Getting current unit details not yet implemented',
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCredit() async {
    return await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.recyclingUnitsCredit,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getPoints() async {
    return await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.recyclingUnitsPoints,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

