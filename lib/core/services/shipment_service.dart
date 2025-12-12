import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/shipment.dart';

class ShipmentService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<ShipmentListResponse>> listShipments({
    int page = 1,
    int pageSize = 20,
    String? senderId,
    String? wasteTypeId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (senderId != null) queryParams['senderId'] = senderId;
    if (wasteTypeId != null) queryParams['wasteTypeId'] = wasteTypeId;

    return await _apiClient.get<ShipmentListResponse>(
      ApiEndpoints.shipments,
      queryParameters: queryParams,
      fromJson: (json) => ShipmentListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<RawMaterialShipmentReceived>> getShipmentById(String id) async {
    return await _apiClient.get<RawMaterialShipmentReceived>(
      ApiEndpoints.shipmentById(id),
      fromJson: (json) => RawMaterialShipmentReceived.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<RawMaterialShipmentReceived>> createShipment({
    required String shipmentImage,
    required String wasteTypeId,
    required double weight,
    required String senderId,
    String? shipmentNumber,
    String? receiptImage,
  }) async {
    return await _apiClient.post<RawMaterialShipmentReceived>(
      ApiEndpoints.shipments,
      data: {
        'shipmentImage': shipmentImage,
        'wasteTypeId': wasteTypeId,
        'weight': weight,
        'senderId': senderId,
        if (shipmentNumber != null) 'shipmentNumber': shipmentNumber,
        if (receiptImage != null) 'receiptImage': receiptImage,
      },
      fromJson: (json) => RawMaterialShipmentReceived.fromJson(json as Map<String, dynamic>),
    );
  }

  // Processed Material Shipment Methods
  Future<ApiResponse<ProcessedMaterialShipment>> createProcessedMaterialShipment({
    required String shipmentImage,
    required String materialTypeId,
    required double weight,
    required String carId,
    required String carPlateNumber,
    required String driverFirstName,
    required String driverSecondName,
    required String driverThirdName,
    required String receiverId,
    required String tradeId,
    required int sentPalletsNumber,
    required DateTime dateOfSending,
    String? shipmentNumber,
    String? receiptFromPress,
    String status = 'SENT_TO_FACTORY',
  }) async {
    return await _apiClient.post<ProcessedMaterialShipment>(
      ApiEndpoints.processedMaterialShipmentsSent,
      data: {
        'shipmentImage': shipmentImage,
        'materialTypeId': materialTypeId,
        'weight': weight,
        'carId': carId,
        'carPlateNumber': carPlateNumber,
        'driverFirstName': driverFirstName,
        'driverSecondName': driverSecondName,
        'driverThirdName': driverThirdName,
        'receiverId': receiverId,
        'tradeId': tradeId,
        'sentPalletsNumber': sentPalletsNumber,
        'dateOfSending': dateOfSending.toIso8601String(),
        if (shipmentNumber != null) 'shipmentNumber': shipmentNumber,
        if (receiptFromPress != null) 'receiptFromPress': receiptFromPress,
        'status': status,
      },
      fromJson: (json) => ProcessedMaterialShipment.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ProcessedMaterialShipmentListResponse>> listProcessedMaterialShipments({
    int page = 1,
    int pageSize = 20,
    String? materialTypeId,
    String? status,
    String? shipmentNumber,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (materialTypeId != null) queryParams['materialTypeId'] = materialTypeId;
    if (status != null) queryParams['status'] = status;
    if (shipmentNumber != null) queryParams['shipmentNumber'] = shipmentNumber;

    return await _apiClient.get<ProcessedMaterialShipmentListResponse>(
      ApiEndpoints.processedMaterialShipmentsSent,
      queryParameters: queryParams,
      fromJson: (json) => ProcessedMaterialShipmentListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ProcessedMaterialShipment>> getProcessedMaterialShipmentById(String id) async {
    return await _apiClient.get<ProcessedMaterialShipment>(
      ApiEndpoints.processedMaterialShipmentById(id),
      fromJson: (json) => ProcessedMaterialShipment.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ProcessedMaterialShipment>> receiveProcessedMaterialShipment({
    required String shipmentId,
    required String factoryUnitId,
    required double receivedWeight,
    required double emptyCarWeight,
    required double plenty,
    String? carCheckImage,
    String? receiptImage,
    String plentyReason = 'هالك',
  }) async {
    return await _apiClient.post<ProcessedMaterialShipment>(
      ApiEndpoints.processedMaterialShipmentReceive(shipmentId),
      data: {
        'factoryUnitId': factoryUnitId,
        'receivedWeight': receivedWeight,
        'emptyCarWeight': emptyCarWeight,
        'plenty': plenty,
        'plentyReason': plentyReason,
        if (carCheckImage != null) 'carCheckImage': carCheckImage,
        if (receiptImage != null) 'receiptImage': receiptImage,
      },
      fromJson: (json) => ProcessedMaterialShipment.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<ProcessedMaterialShipment>>> getPendingReceiptShipments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.processedMaterialShipmentsPendingReceipt,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List<dynamic>?)
              ?.map((item) => ProcessedMaterialShipment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<ProcessedMaterialShipment>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<ProcessedMaterialShipment>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }

  Future<ApiResponse<List<ProcessedMaterialShipment>>> getReceivedShipments() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.processedMaterialShipmentsReceived,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final items = (data['data'] as List<dynamic>?)
              ?.map((item) => ProcessedMaterialShipment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<ProcessedMaterialShipment>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<ProcessedMaterialShipment>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }
}

