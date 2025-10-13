import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/UserModel.dart';
import '../api/api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';

  UserModel? _currentUser;
  String? _token;
  bool _hasSeenWelcome = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get hasSeenWelcome => _hasSeenWelcome;

  // Initialize auth service (call this on app startup)
  Future<void> initialize() async {
    await _loadStoredData();
  }

  // Load stored token and user data
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString(_tokenKey);
    final userData = prefs.getString(_userKey);
    _hasSeenWelcome = prefs.getBool(_hasSeenWelcomeKey) ?? false;

    print('🔍 Loading stored data...');
    print('   Token exists: ${_token != null}');
    print('   User data exists: ${userData != null}');

    if (userData != null) {
      try {
        final userJson = jsonDecode(userData);
        _currentUser = UserModel.fromJson(userJson);
        print('✅ User loaded from storage: ${_currentUser!.name}');
      } catch (e) {
        print('❌ Error loading user data: $e');
        // Clear invalid data
        await clearAuth();
      }
    }
  }

  // Register user
  Future<AuthResult> register(UserModel user) async {
    try {
      final response = await apiClient.register(user);

      if (response.success && response.data != null) {
        final data = response.data!;

        // Extract token from response
        _token = data['token'];

        // Extract user data from response
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }

        // Store data locally
        await _storeAuthData();

        return AuthResult(
          success: true,
          message: 'Inscription réussie',
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult(
          success: false,
          message: response.message ?? 'Erreur lors de l\'inscription',
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Erreur: ${e.toString()}');
    }
  }

  // Login user
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await apiClient.login(email, password);

      if (response.success && response.data != null) {
        // Debug: Print the actual response structure
        print('DEBUG - Response data keys: ${response.data!.keys}');
        print('DEBUG - Full response data: ${response.data}');

        final data = response.data!;
        _token = data['token'];

        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }

        // Store data locally
        await _storeAuthData();

        return AuthResult(
          success: true,
          message: 'Connexion réussie',
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult(
          success: false,
          message: response.message ?? 'Erreur de connexion',
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Erreur: ${e.toString()}');
    }
  }

  // Get current user from server (refresh user data)
  Future<AuthResult> getCurrentUser() async {
    if (_token == null) {
      return AuthResult(
        success: false,
        message: 'Aucun token d\'authentification',
      );
    }

    try {
      final response = await apiClient.getCurrentUser(_token!);

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _storeAuthData();

        return AuthResult(success: true, user: _currentUser);
      } else {
        // Token might be expired
        await clearAuth();
        return AuthResult(
          success: false,
          message: response.message ?? 'Session expirée',
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Erreur: ${e.toString()}');
    }
  }

  // Store authentication data
  Future<void> _storeAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
      print('✅ Token saved to storage');
    }

    if (_currentUser != null) {
      final userJson = jsonEncode(_currentUser!.toJson());
      await prefs.setString(_userKey, userJson);
      print('✅ User data saved to storage: ${_currentUser!.name}');
    }
  }

  // Update user data and persist to storage
  Future<void> updateUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    await _storeAuthData();
  }

  // Clear authentication data
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    _token = null;
    _currentUser = null;
    
    print('🗑️ Auth data cleared from storage');
  }

  // Logout
  Future<void> logout() async {
    // Call backend logout endpoint if token exists
    if (_token != null) {
      try {
        await apiClient.logout(_token!);
      } catch (e) {
        // Continue with local logout even if API call fails
        print('Logout API call failed: $e');
      }
    }

    // Clear local authentication data
    await clearAuth();
  }

  // Check if token is valid
  Future<bool> isTokenValid() async {
    if (_token == null) return false;

    final result = await getCurrentUser();
    return result.success;
  }

  // Mark welcome screen as seen
  Future<void> markWelcomeAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, true);
    _hasSeenWelcome = true;
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? token;

  AuthResult({required this.success, this.message, this.user, this.token});
}

// Singleton instance
final authService = AuthService();
