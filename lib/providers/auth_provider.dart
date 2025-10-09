import 'package:flutter/foundation.dart';
import '../models/UserModel.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../api/api_client.dart';

/// AuthProvider manages authentication state across the app
/// Uses ChangeNotifier to notify listeners when auth state changes
class AuthProvider with ChangeNotifier {
  final AuthService _authService = authService;
  final SocketService _socketService = socketService;

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
  bool get hasSeenWelcome => _authService.hasSeenWelcome;

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
        } else {
          // Connect to socket if authenticated
          await _connectSocket();
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
      debugPrint('AuthProvider: Starting login...');
      final result = await _authService.login(email, password);

      if (result.success) {
        _currentUser = result.user;
        _token = result.token;
        _errorMessage = null;

        debugPrint('AuthProvider: Login successful');
        debugPrint('AuthProvider: User = ${_currentUser?.name}');
        debugPrint('AuthProvider: Token exists = ${_token != null}');
        debugPrint('AuthProvider: isAuthenticated = $isAuthenticated');

        // Connect to socket after successful login
        await _connectSocket();

        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message ?? 'Erreur de connexion';
        debugPrint('AuthProvider: Login failed - $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      debugPrint('AuthProvider: Login error - $_errorMessage');
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
      debugPrint('AuthProvider: Starting logout...');

      // Disconnect socket before logging out
      _socketService.disconnect();

      await _authService.logout();
      _currentUser = null;
      _token = null;
      _errorMessage = null;
      debugPrint('AuthProvider: Logout successful - user and token cleared');
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion: ${e.toString()}';
      debugPrint('AuthProvider: Logout error - $_errorMessage');
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
    // Persist to storage
    _authService.updateUserData(updatedUser);
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

  /// Mark welcome screen as seen
  Future<void> markWelcomeAsSeen() async {
    await _authService.markWelcomeAsSeen();
    notifyListeners();
  }

  /// Connect to Socket.IO server
  Future<void> _connectSocket() async {
    if (_token != null) {
      debugPrint('AuthProvider: Connecting to socket...');
      await _socketService.connect(_token!);

      // Listen for agent status updates from other clients
      _socketService.onAgentStatusUpdate((data) {
        debugPrint('AuthProvider: Received status update: $data');
        final agentId = data['agentId'] as String?;
        final availability = data['availability'] as String?;

        // If it's the current user's status, update locally
        if (agentId == _currentUser?.id && availability != null) {
          _currentUser = _currentUser?.copyWith(availability: availability);
          notifyListeners();
          debugPrint(
            'AuthProvider: Updated current user availability to $availability',
          );
        }
      });
    }
  }

  /// Update agent availability status (field agents only)
  Future<bool> updateAvailability(String availability) async {
    if (_currentUser == null || _token == null) {
      _errorMessage = 'Utilisateur non connecté';
      notifyListeners();
      return false;
    }

    if (!isField) {
      _errorMessage =
          'Seuls les agents terrain peuvent modifier leur disponibilité';
      notifyListeners();
      return false;
    }

    try {
      debugPrint('AuthProvider: Updating availability to $availability...');

      // Call API to update status in database
      final response = await apiClient.updateAgentStatus(
        agentId: _currentUser!.id!,
        availability: availability,
        token: _token!,
      );

      if (response.success && response.data != null) {
        // Update local user data
        _currentUser = response.data;
        _authService.updateUserData(_currentUser!);

        // Emit socket event to notify other clients
        _socketService.emitStatusChange(availability);

        debugPrint('AuthProvider: Availability updated successfully');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Erreur lors de la mise à jour';
        debugPrint('AuthProvider: Update failed - $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      debugPrint('AuthProvider: Update error - $_errorMessage');
      notifyListeners();
      return false;
    }
  }
}
