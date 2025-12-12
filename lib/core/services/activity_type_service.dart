import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/activity_type.dart';

class ActivityTypeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<ActivityType>>> getActivityTypes() async {
    final response = await _apiClient.get<List<ActivityType>>(
      ApiEndpoints.activityTypes,
      fromJson: (json) {
        // The API returns { success: true, data: [...] }
        // The fromJson receives the 'data' field which is a List
        if (json is List) {
          return json.map((item) => ActivityType.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <ActivityType>[];
      },
    );

    return response;
  }
}

