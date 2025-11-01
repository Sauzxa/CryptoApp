import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration constants
class AppConfig {
  // Server configuration
  static String get serverIpAddress =>
      dotenv.env['SERVER_IP'] ?? '192.168.1.161';

  static int get serverPort =>
      int.tryParse(dotenv.env['SERVER_PORT'] ?? '') ?? 3000;

  // Base URL construction
  static String get baseUrl => 'http://$serverIpAddress:$serverPort';

  // Environment configuration
  static const bool isDebugMode = true;
  static const bool enableLogging = true;

  // API configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Internal API Key (for folders/documents endpoints - not auth related)
  static String get internalApiKey =>
      (dotenv.env['INTERNAL_API_KEY'] ?? '').trim();
}
