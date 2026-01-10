import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as models;

class PushNotificationService {
  static const String _lastNotificationIdKey = 'last_notification_id';
  static const String _backgroundTaskName = 'checkNotifications';
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService = NotificationService();
  
  static Future<void> initialize() async {
    final service = PushNotificationService();
    await service._initializeLocalNotifications();
    await service._initializeWorkmanager();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to notifications screen if app is open
    // This is handled in the app's navigation logic
  }

  Future<void> _initializeWorkmanager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Register periodic task (runs every 15 minutes minimum)
    await Workmanager().registerPeriodicTask(
      _backgroundTaskName,
      _backgroundTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> checkForNewNotifications({bool showNotification = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationId = prefs.getString(_lastNotificationIdKey);
      
      // Get stored phone number directly from SharedPreferences
      // This is set during login in auth_service.dart
      // Also check userData if phoneNumber key doesn't exist (for existing users)
      String? phoneNumber = prefs.getString('phoneNumber');
      
      // Fallback: try to get from userData JSON if phoneNumber key doesn't exist
      if (phoneNumber == null) {
        final userDataStr = prefs.getString('userData');
        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr) as Map<String, dynamic>?;
            phoneNumber = userData?['phoneNumber'] as String?;
          } catch (e) {
            debugPrint('Failed to parse userData: $e');
          }
        }
      }

      if (phoneNumber == null) {
        debugPrint('No phone number found, skipping notification check');
        return;
      }

      final response = await _notificationService.getNotifications(
        phoneNumber: phoneNumber,
        page: 1,
        pageSize: 10, // Check only recent notifications
      );

      if (response.isSuccess && response.data != null) {
        final List<models.Notification> notifications = response.data!.items;
        
        // Find new unread notifications
        final newNotifications = notifications.where((n) {
          if (n.isRead) return false;
          if (lastNotificationId == null) return true;
          return n.id != lastNotificationId;
        }).toList();

        if (newNotifications.isNotEmpty) {
          // Update last notification ID
          await prefs.setString(_lastNotificationIdKey, newNotifications.first.id);
          
          // Show notifications for new items
          if (showNotification) {
            for (final notification in newNotifications) {
              await _showNotification(notification);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  Future<void> _showNotification(models.Notification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'notifications',
      'Notifications',
      channelDescription: 'Notifications for recycling unit updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.id,
    );
  }

  // Foreground polling - called from app when in foreground
  static void startForegroundPolling() {
    final service = PushNotificationService();
    // Poll every 30 seconds when app is in foreground
    Future.delayed(const Duration(seconds: 30), () {
      service.checkForNewNotifications();
      startForegroundPolling();
    });
  }

  Future<void> stopPolling() async {
    await Workmanager().cancelByUniqueName(_backgroundTaskName);
  }
}

// Background task callback - must be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');
    
    if (task == 'checkNotifications') {
      final service = PushNotificationService();
      await service.checkForNewNotifications(showNotification: true);
      return Future.value(true);
    }
    
    return Future.value(false);
  });
}

