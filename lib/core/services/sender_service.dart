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

  /// Self-registration (no unit assignment). Call POST /api/senders/register. No auth required.
  Future<ApiResponse<Map<String, dynamic>>> registerSender(Sender sender, String password) async {
    final data = {...sender.toCreateJson(), 'password': password};
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.sendersRegister,
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (response.isSuccess && response.data != null) {
      final senderData = response.data!['sender'];
      if (senderData != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.message,
          data: Map<String, dynamic>.from(senderData as Map),
        );
      }
    }
    return ApiResponse<Map<String, dynamic>>(
      success: response.isSuccess,
      message: response.message,
      error: response.error,
    );
  }

  /// Sender credit (stock): approved raw − processed splits. Auth: SENDER.
  Future<ApiResponse<Map<String, dynamic>>> getMyCredit() async {
    return await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.sendersMeCredit,
      fromJson: (json) => json as Map<String, dynamic>,
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

