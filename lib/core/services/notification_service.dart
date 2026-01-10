import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/notification.dart';
import '../utils/storage.dart';
import '../utils/constants.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<NotificationListResponse>> getNotifications({
    String? phoneNumber,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    
    if (phoneNumber != null) {
      queryParams['phoneNumber'] = phoneNumber;
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.notifications}?$queryString',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final items = (data['items'] as List<dynamic>?)
              ?.map((item) => Notification.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final total = data['total'] as int? ?? 0;

      return ApiResponse<NotificationListResponse>(
        success: true,
        message: response.message,
        data: NotificationListResponse(
          items: items,
          total: total,
        ),
      );
    }

    return ApiResponse<NotificationListResponse>(
      success: false,
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<int>> getUnreadCount({String? phoneNumber}) async {
    final queryParams = <String, String>{};
    
    if (phoneNumber != null) {
      queryParams['phoneNumber'] = phoneNumber;
    }

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.notificationsUnreadCount}$queryString',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final count = response.data!['count'] as int? ?? 0;
      return ApiResponse<int>(
        success: true,
        message: response.message,
        data: count,
      );
    }

    return ApiResponse<int>(
      success: false,
      message: response.message,
      error: response.error,
      data: 0,
    );
  }

  Future<ApiResponse<Notification>> markAsRead(String notificationId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.notificationMarkRead(notificationId),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return ApiResponse<Notification>(
        success: true,
        message: response.message,
        data: Notification.fromJson(response.data!),
      );
    }

    return ApiResponse<Notification>(
      success: false,
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<void>> markAllAsRead({String? phoneNumber}) async {
    // This endpoint doesn't exist yet in the backend, but we can mark each notification individually
    // For now, we'll fetch all unread notifications and mark them one by one
    // This is not optimal but works until we have a bulk mark-as-read endpoint
    
    final notificationsResponse = await getNotifications(
      phoneNumber: phoneNumber,
      page: 1,
      pageSize: 100, // Get all notifications
    );

    if (notificationsResponse.isSuccess && notificationsResponse.data != null) {
      final unreadNotifications = notificationsResponse.data!.items
          .where((n) => !n.isRead)
          .toList();

      // Mark all unread notifications as read
      for (final notification in unreadNotifications) {
        await markAsRead(notification.id);
      }

      return ApiResponse<void>(
        success: true,
        message: 'All notifications marked as read',
      );
    }

    return ApiResponse<void>(
      success: false,
      message: notificationsResponse.message,
      error: notificationsResponse.error,
    );
  }
}

class NotificationListResponse {
  final List<Notification> items;
  final int total;

  NotificationListResponse({
    required this.items,
    required this.total,
  });
}

