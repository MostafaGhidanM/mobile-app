// Background task: fetch notifications and show locally when app is closed.
// No FCM or paid service – uses Workmanager (periodic, ~15 min min on Android).
// iOS: add task ID to Info.plist (BGTaskSchedulerPermittedIdentifiers) and
// register in AppDelegate if using iOS 13+; see workmanager package iOS_SETUP.md.
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

/// Task name used for Workmanager registration.
const String notificationCheckTaskName = 'notification-check';
const String _taskName = notificationCheckTaskName;
const String _lastNotificationIdKey = 'last_notification_id';
const String _apiBaseUrlKey = 'api_base_url';
const String _accessTokenKey = 'access_token';
const String _phoneNumberKey = 'phoneNumber';
const String _userDataKey = 'userData';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return false;
    try {
      await _runNotificationCheck();
      return true;
    } catch (_) {
      return false;
    }
  });
}

Future<void> _runNotificationCheck() async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString(_apiBaseUrlKey);
  final token = prefs.getString(_accessTokenKey);
  String? phoneNumber = prefs.getString(_phoneNumberKey);
  if (phoneNumber == null) {
    final userDataStr = prefs.getString(_userDataKey);
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>?;
        phoneNumber = userData?['phoneNumber'] as String?;
      } catch (_) {}
    }
  }
  if (baseUrl == null || token == null || phoneNumber == null) return;

  final uri = Uri.parse('$baseUrl/notifications').replace(
    queryParameters: {'page': '1', 'pageSize': '10', 'phoneNumber': phoneNumber},
  );
  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  if (response.statusCode != 200) return;

  final body = jsonDecode(response.body) as Map<String, dynamic>?;
  if (body?['success'] != true) return;
  final data = body?['data'] as Map<String, dynamic>?;
  final items = data?['items'] as List<dynamic>?;
  if (items == null || items.isEmpty) return;

  final lastId = prefs.getString(_lastNotificationIdKey);
  final newList = <Map<String, dynamic>>[];
  for (final item in items) {
    final map = item as Map<String, dynamic>?;
    if (map == null) continue;
    if (map['isRead'] == true) continue;
    final id = map['id'] as String?;
    if (id == null) continue;
    if (lastId != null && id == lastId) break;
    newList.add(map);
  }
  if (newList.isEmpty) return;

  final firstId = newList.first['id'] as String? ?? '';
  await prefs.setString(_lastNotificationIdKey, firstId);

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'notifications',
      'Notifications',
      channelDescription: 'Notifications for recycling unit updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  for (final map in newList) {
    final id = map['id'] as String? ?? '';
    final title = map['title'] as String? ?? '';
    final message = map['message'] as String? ?? '';
    await plugin.show(id.hashCode, title, message, details, payload: id);
  }
}
