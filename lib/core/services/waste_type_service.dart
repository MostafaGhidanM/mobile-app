import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/waste_type.dart';

class WasteTypeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<WasteType>>> getWasteTypes() async {
    final response = await _apiClient.get<List<WasteType>>(
      ApiEndpoints.wasteTypes,
      fromJson: (json) {
        // The API returns { success: true, data: [...] }
        // The fromJson receives the 'data' field which is a List
        if (json is List) {
          return json.map((item) => WasteType.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <WasteType>[];
      },
    );

    return response;
  }
}

