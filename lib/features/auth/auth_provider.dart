import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/recycling_unit_service.dart';
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(mobile: mobile, password: password);
      
      if (response.isSuccess && response.data != null) {
        _user = response.data!.user;
        _recyclingUnit = response.data!.recyclingUnit;
        
        // If unitType is missing, try to fetch it from the API
        if (_recyclingUnit != null && _recyclingUnit!.unitType == null) {
          await _fetchUnitDetails(_recyclingUnit!.id);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error?.message ?? response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchUnitDetails(String unitId) async {
    try {
      final recyclingUnitService = RecyclingUnitService();
      final response = await recyclingUnitService.getRecyclingUnits();
      
      if (response.isSuccess && response.data != null) {
        final unit = response.data!.firstWhere(
          (u) => u.id == unitId,
          orElse: () => _recyclingUnit!,
        );
        if (unit.unitType != null) {
          _recyclingUnit = unit;
        }
      }
    } catch (e) {
      // Continue without unitType - the app will still work
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
    final userData = await _authService.getStoredUserData();
    final token = await _authService.getStoredToken();
    
    if (userData != null && token != null) {
      if (userData['role'] == 'RECYCLING_UNIT') {
        _recyclingUnit = RecyclingUnit.fromJson(userData);
      } else {
        _user = User.fromJson(userData);
      }
      notifyListeners();
    } else {
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

