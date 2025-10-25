import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/firebase_notification_service.dart';
import '../api/api_client.dart';
import '../models/UserModel.dart';
import 'messaging_provider.dart';

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
  bool _canToggleAvailability = true; // Controlled by socket events

  // Public getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get hasSeenWelcome => _authService.hasSeenWelcome;
  bool get canToggleAvailability => _canToggleAvailability;

  // Role-based getters
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCommercial => _currentUser?.isCommercial ?? false;
  bool get isField => _currentUser?.isField ?? false;

  /// Initialize the provider - load stored auth data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔄 AuthProvider: Initializing...');
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      _token = _authService.token;

      debugPrint('📦 AuthProvider: Loaded from storage');
      debugPrint('   Token: ${_token != null ? "exists" : "null"}');
      debugPrint('   User: ${_currentUser?.name ?? "null"}');

      // If we have a token, try to connect socket
      // Don't validate token on startup - let user in even if offline
      if (_token != null && _currentUser != null) {
        debugPrint('✅ AuthProvider: User is authenticated');
        // Try to connect socket (non-blocking)
        _connectSocket().catchError((e) {
          debugPrint('⚠️ Socket connection failed: $e');
          // Don't logout on socket failure
        });
      } else {
        debugPrint('❌ AuthProvider: No stored credentials');
      }
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation: ${e.toString()}';
      debugPrint('❌ AuthProvider initialization error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ AuthProvider: Initialization complete');
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

        // Send FCM token to backend after successful login
        await _sendFCMTokenToBackend();

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
  Future<void> logout({MessagingProvider? messagingProvider}) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Starting logout...');

      // Clear messaging data first (before disconnecting socket)
      if (messagingProvider != null) {
        messagingProvider.clearMessagingData();
        debugPrint('AuthProvider: Messaging data cleared');
      }

      // Disconnect socket before logging out
      _socketService.disconnect();
      debugPrint('AuthProvider: Socket disconnected');

      // Call auth service logout (with timeout)
      await _authService.logout().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            'AuthProvider: Logout API call timed out, continuing with local logout',
          );
        },
      );

      _currentUser = null;
      _token = null;
      _errorMessage = null;
      debugPrint('AuthProvider: Logout successful - user and token cleared');
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion: ${e.toString()}';
      debugPrint('AuthProvider: Logout error - $_errorMessage');
      // Clear local data anyway
      _currentUser = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthProvider: Logout complete');
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

  /// Send FCM token to backend after login
  Future<void> _sendFCMTokenToBackend() async {
    try {
      final fcmToken = firebaseNotificationService.fcmToken;
      if (fcmToken != null && _token != null) {
        debugPrint('AuthProvider: Sending FCM token to backend...');
        await firebaseNotificationService.sendTokenToBackend(fcmToken, _token!);
        debugPrint('AuthProvider: FCM token sent successfully');
      } else {
        debugPrint('AuthProvider: No FCM token or auth token available');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error sending FCM token: $e');
    }
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

      // Listen for direct status changes (from "Commencer" button, rapport, etc.)
      _socketService.socket?.on('agent:status_changed', (data) {
        debugPrint('AuthProvider: Received direct status change: $data');
        final availability = data['availability'] as String?;
        final message = data['message'] as String?;

        if (availability != null && _currentUser != null) {
          _currentUser = _currentUser?.copyWith(availability: availability);
          _authService.updateUserData(_currentUser!);
          notifyListeners();
          debugPrint(
            'AuthProvider: Status changed to $availability - $message',
          );
        }
      });

      // Listen for availability toggle enabled (when rapport is sent)
      _socketService.socket?.on('agent:availability_toggle_enabled', (data) {
        debugPrint('🔓 AuthProvider: Toggle enabled via socket: $data');
        _canToggleAvailability = true;
        notifyListeners();
      });
    }
  }

  /// Set if agent can toggle availability
  void setCanToggleAvailability(bool canToggle) {
    _canToggleAvailability = canToggle;
    notifyListeners();
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
