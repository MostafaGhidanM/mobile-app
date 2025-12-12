import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration
  // Using ngrok URL for all platforms (mobile and web)
  static String get baseUrl {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://interavailable-heaping-marianela.ngrok-free.dev',
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

