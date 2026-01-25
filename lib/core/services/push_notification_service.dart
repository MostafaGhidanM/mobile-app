import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as models;
import '../../localization/app_localizations.dart';
import '../utils/storage.dart';

class PushNotificationService {
  static const String _lastNotificationIdKey = 'last_notification_id';
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService = NotificationService();
  Timer? _foregroundPollTimer;
  
  PushNotificationService._();
  
  static Future<void> initialize() async {
    final service = PushNotificationService.instance;
    await service._initializeLocalNotifications();
    service._startForegroundPolling();
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
    // Navigate to notifications screen if app is open
    // This is handled in the app's navigation logic
  }

  void _startForegroundPolling() {
    // Poll every 30 seconds when app is in foreground
    // For background, we rely on the app resuming and checking immediately
    _foregroundPollTimer?.cancel();
    final service = this;
    _foregroundPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      service.checkForNewNotifications();
    });
  }

  void stopPolling() {
    _foregroundPollTimer?.cancel();
    _foregroundPollTimer = null;
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
            // Ignore parse errors
          }
        }
      }

      if (phoneNumber == null) {
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
      // Ignore errors
    }
  }

  Future<void> _showNotification(models.Notification notification) async {
    // Use localized title/message when available (matches notification dropdown and in-app list)
    String title = notification.title;
    String message = notification.message;
    try {
      final lang = StorageService.getString('app_language') ?? 'ar';
      final loc = await AppLocalizations.delegate.load(Locale(lang));
      title = loc.getNotificationTitle(notification.type, notification.meta) ?? title;
      message = loc.getNotificationMessage(notification.type, notification.meta) ?? message;
    } catch (_) {
      // Keep raw title/message on any error (e.g. assets not loaded)
    }

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
      title,
      message,
      details,
      payload: notification.id,
    );
  }

  // Called when app comes to foreground to check for new notifications immediately
  static Future<void> checkOnAppResume() async {
    final service = PushNotificationService.instance;
    await service.checkForNewNotifications();
  }
}

