/// Application configuration constants
class AppConfig {
  // Server configuration
  static const String serverIpAddress = '192.168.1.91';
  static const int serverPort = 3000;

  // Base URL construction
  static String get baseUrl => 'http://$serverIpAddress:$serverPort';

  // Environment configuration
  static const bool isDebugMode = true;
  static const bool enableLogging = true;

  // API configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}
