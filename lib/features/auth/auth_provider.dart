import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../../core/models/recycling_unit.dart';
import '../../core/utils/storage.dart';
import '../../core/utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  RecyclingUnit? _recyclingUnit;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  RecyclingUnit? get recyclingUnit => _recyclingUnit;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _recyclingUnit != null;
  bool get isRecyclingUnit => _recyclingUnit != null;

  Future<bool> login(String mobile, String password) async {
    debugPrint('[AuthProvider] Starting login process');
    debugPrint('[AuthProvider] Mobile: $mobile');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] Calling auth service login...');
      final response = await _authService.login(mobile: mobile, password: password);
      debugPrint('[AuthProvider] Login response received');
      debugPrint('[AuthProvider] Response success: ${response.isSuccess}');
      debugPrint('[AuthProvider] Response data: ${response.data}');
      debugPrint('[AuthProvider] Response error: ${response.error}');
      
      if (response.isSuccess && response.data != null) {
        debugPrint('[AuthProvider] Login successful');
        _user = response.data!.user;
        _recyclingUnit = response.data!.recyclingUnit;
        debugPrint('[AuthProvider] User: $_user');
        debugPrint('[AuthProvider] RecyclingUnit: $_recyclingUnit');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? response.message ?? 'Login failed';
        debugPrint('[AuthProvider] Login failed: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] Login exception: $e');
      debugPrint('[AuthProvider] Stack trace: $stackTrace');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _recyclingUnit = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('[AuthProvider] Checking auth status...');
    final userData = await _authService.getStoredUserData();
    final token = await _authService.getStoredToken();
    debugPrint('[AuthProvider] Stored user data: $userData');
    debugPrint('[AuthProvider] Stored token: ${token != null ? "exists" : "null"}');
    
    if (userData != null && token != null) {
      debugPrint('[AuthProvider] User data and token found, restoring session');
      if (userData['role'] == 'RECYCLING_UNIT') {
        _recyclingUnit = RecyclingUnit.fromJson(userData);
        debugPrint('[AuthProvider] Restored as recycling unit');
      } else {
        _user = User.fromJson(userData);
        debugPrint('[AuthProvider] Restored as user');
      }
      notifyListeners();
    } else {
      debugPrint('[AuthProvider] No stored auth data found');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

