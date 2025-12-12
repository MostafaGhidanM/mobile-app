import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration
  // Using ngrok URL for public access (mobile apps)
  // For web, use localhost to avoid ngrok browser warning
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost to avoid ngrok browser warning page
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:3000',
      );
    }
    // For mobile apps, use localhost
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3000',
    );
  }
  
  static const String apiPrefix = '/api';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'app_language';
  
  // Default Values
  static const String defaultLanguage = 'ar';
  static const int defaultPageSize = 20;
  static const int maxImageSizeMB = 8;
  
  // Image Upload
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
}

