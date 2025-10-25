import '../config/config.dart';

class ApiEndpoints {
  // Base URL for your backend server
  // Using centralized configuration for easy IP address management
  static String get baseUrl => AppConfig.baseUrl;

  // API version prefix
  static const String apiPrefix = '/api';

  // Authentication endpoints
  static const String auth = '$apiPrefix/auth';
  static const String register = '$auth/register';
  static const String login = '$auth/login';
  static const String me = '$auth/me';
  static const String logout = '$auth/logout';

  // User/Agent endpoints
  static const String agents = '$apiPrefix/agents';

  // Reservations endpoints
  static const String reservations = '$apiPrefix/reservations';
  static const String createReservation = reservations;
  static const String reservationHistory = '$reservations/history';

  // Call logs endpoints
  static const String calls = '$apiPrefix/calls';

  // Folders & Documents endpoints
  static const String folders = '$apiPrefix/folders';

  // Admin endpoints
  static const String admin = '$apiPrefix/admin';
  static const String adminStats = '$admin/stats';
  static const String adminDashboard = '$admin/dashboard';

  // Health check
  static const String health = '/health';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
