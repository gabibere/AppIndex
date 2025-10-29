import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/error_handling_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final token = await _getStoredToken();
      if (token != null) {
        // Get stored user ID from API service
        final userId = ApiService.getCurrentUserId() ?? '1';

        // Get stored username if available
        final storedUsername = await _getStoredUsername();

        // Create a basic user from stored data
        _user = User(
          id: userId,
          username: storedUsername ?? 'user',
          email: '${storedUsername ?? 'user'}@appindex.com',
          firstName: storedUsername ?? 'User',
          lastName: '',
          roles: ['user'],
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login with username and password
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Initialize API service if not already done
      if (!ApiService.isInitialized) {
        ApiService.initialize();
      }

      // Use the new API service for authentication
      final result = await ApiService.login(username, password);

      if (result.isSuccess) {
        // Get actual user ID from API service
        final userId = ApiService.getCurrentUserId() ?? '123';

        // Create user object from API response
        _user = User(
          id: userId,
          username: username,
          email: '$username@appindex.com',
          firstName: username, // Use username as first name
          lastName: '', // No last name from API
          phoneNumber: null,
          profileImage: null,
          roles: ['user'],
          preferences: {'theme': 'light', 'language': 'en'},
          lastLogin: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          isActive: true,
          isVerified: true,
        );

        _isAuthenticated = true;
        await _storeToken(
          'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        await _storeUsername(username);
        notifyListeners();
        return true;
      } else {
        _setError(
          ErrorHandlingService.getApiErrorMessage({
            'err': result.err,
            'msg_err': result.msgErr,
          }),
        );
        return false;
      }
    } catch (e) {
      _setError(ErrorHandlingService.getFriendlyErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Clear API service session
      ApiService.clearSession();
      await _clearStoredToken();
      await _clearStoredUsername();
      _user = null;
      _isAuthenticated = false;
      _clearError();
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return false;

    _setLoading(true);
    try {
      // Simple profile update without external service
      _user = _user!.copyWith(
        firstName: updates['firstName'] ?? _user!.firstName,
        lastName: updates['lastName'] ?? _user!.lastName,
        email: updates['email'] ?? _user!.email,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      // Simple password change validation
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        _setError('Password cannot be empty');
        return false;
      }
      if (newPassword.length < 6) {
        _setError('New password must be at least 6 characters');
        return false;
      }
      // In a real app, you would validate the current password and update it
      return true;
    } catch (e) {
      _setError('Password change failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> _storeUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _clearStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
  }
}
