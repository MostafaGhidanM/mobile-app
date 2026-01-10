import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/user.dart';
import '../models/recycling_unit.dart';
import '../utils/storage.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<LoginResponse>> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'mobile': mobile,
        'password': password,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final loginData = LoginResponse.fromJson(response.data!);
      
      // Store token
      if (loginData.accessToken.isNotEmpty) {
        await _apiClient.setToken(loginData.accessToken);
        await StorageService.setString(
          AppConstants.accessTokenKey,
          loginData.accessToken,
        );
        
        // Store user/unit data
        if (loginData.user != null) {
          await StorageService.setJson(
            AppConstants.userDataKey,
            loginData.user!.toJson(),
          );
        } else if (loginData.recyclingUnit != null) {
          await StorageService.setJson(
            AppConstants.userDataKey,
            loginData.recyclingUnit!.toJson(),
          );
          // Store phoneNumber separately for background notification tasks
          await StorageService.setString(
            'phoneNumber',
            loginData.recyclingUnit!.phoneNumber,
          );
        }
      }
      
      return ApiResponse<LoginResponse>(
        success: true,
        message: response.message,
        data: loginData,
      );
    }

    return ApiResponse<LoginResponse>(
      success: false,
      message: response.message,
      error: response.error,
    );
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    await StorageService.remove(AppConstants.accessTokenKey);
    await StorageService.remove(AppConstants.userDataKey);
    await StorageService.remove('phoneNumber');
  }

  Future<String?> getStoredToken() async {
    return await StorageService.getString(AppConstants.accessTokenKey);
  }

  Future<Map<String, dynamic>?> getStoredUserData() async {
    return await StorageService.getJson(AppConstants.userDataKey);
  }

  bool isAuthenticated() {
    final token = StorageService.getString(AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }
}

class LoginResponse {
  final User? user;
  final RecyclingUnit? recyclingUnit;
  final String accessToken;

  LoginResponse({
    this.user,
    this.recyclingUnit,
    required this.accessToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      recyclingUnit: json['recyclingUnit'] != null
          ? RecyclingUnit.fromJson(json['recyclingUnit'])
          : null,
      accessToken: json['accessToken'] ?? '',
    );
  }

  bool get isRecyclingUnit => recyclingUnit != null;
  bool get isUser => user != null;
}

