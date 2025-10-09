import 'package:flutter/foundation.dart';
import '../models/UserModel.dart';
import '../services/auth_service.dart';

/// AuthProvider manages authentication state across the app
/// Uses ChangeNotifier to notify listeners when auth state changes
class AuthProvider with ChangeNotifier {
  final AuthService _authService = authService;

  // Private state
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCommercial => _currentUser?.isCommercial ?? false;
  bool get isField => _currentUser?.isField ?? false;

  /// Initialize the provider - load stored auth data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      _token = _authService.token;

      // Verify token is still valid
      if (_token != null) {
        final isValid = await _authService.isTokenValid();
        if (!isValid) {
          await logout();
        }
      }
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation: ${e.toString()}';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(user);

      if (result.success) {
        _currentUser = result.user;
        _token = result.token;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message ?? 'Erreur lors de l\'inscription';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result.success) {
        _currentUser = result.user;
        _token = result.token;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message ?? 'Erreur de connexion';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _token = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion: ${e.toString()}';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current user data from server
  Future<bool> refreshUser() async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.getCurrentUser();

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message;
        // If refresh fails, user might be logged out
        if (_errorMessage?.contains('Session expirée') ?? false) {
          await logout();
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user data locally (after profile update)
  void updateUser(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  /// Get user's display name
  String get userName => _currentUser?.displayName ?? 'Utilisateur';

  /// Get user's email
  String get userEmail => _currentUser?.email ?? '';

  /// Get user's role display name
  String get userRole => _currentUser?.roleDisplayName ?? '';

  /// Get field agent availability
  String get availability => _currentUser?.availabilityDisplayName ?? '';
}
