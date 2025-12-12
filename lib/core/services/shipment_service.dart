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
}

