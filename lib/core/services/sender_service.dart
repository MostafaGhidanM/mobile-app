import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/sender.dart';

class SenderService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Sender>>> getAssignedSenders() async {
    final response = await _apiClient.get<List<Sender>>(
      ApiEndpoints.assignedSenders,
      fromJson: (json) {
        // The API returns { success: true, data: [...] }
        // The fromJson receives the 'data' field which is a List
        if (json is List) {
          return json.map((item) => Sender.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <Sender>[];
      },
    );

    return response;
  }

  Future<ApiResponse<Sender>> createSender(Sender sender) async {
    return await _apiClient.post<Sender>(
      ApiEndpoints.senders,
      data: sender.toCreateJson(),
      fromJson: (json) => Sender.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Sender>> getSenderById(String id) async {
    return await _apiClient.get<Sender>(
      ApiEndpoints.senderById(id),
      fromJson: (json) => Sender.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Sender>> updateSender(String id, Map<String, dynamic> data) async {
    return await _apiClient.put<Sender>(
      ApiEndpoints.senderById(id),
      data: data,
      fromJson: (json) => Sender.fromJson(json as Map<String, dynamic>),
    );
  }
}

