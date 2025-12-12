import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/trade.dart';

class TradeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Trade>>> getTrades({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.trades,
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final items = (data['items'] as List<dynamic>?)
              ?.map((item) => Trade.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<Trade>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<Trade>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }
}
