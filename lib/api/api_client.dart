import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/UserModel.dart';
import '../models/ReservationModel.dart';
import 'api_endpoints.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers with authorization token
  Map<String, String> _getAuthHeaders(String? token) {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic HTTP request method
  Future<ApiResponse<Map<String, dynamic>>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final url = Uri.parse(ApiEndpoints.getFullUrl(endpoint));
      final headers = _getAuthHeaders(token);

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await _client
              .post(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(url, headers: headers)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            'Pas de connexion internet. Veuillez vérifier votre connexion.',
        statusCode: 0,
      );
    } on HttpException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur de connexion au serveur.',
        statusCode: 0,
      );
    } on FormatException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur de format de données.',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur inattendue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Handle HTTP response
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Erreur du serveur',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur de traitement de la réponse: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  // Authentication Methods

  /// Register a new user
  Future<ApiResponse<Map<String, dynamic>>> register(UserModel user) async {
    try {
      final response = await _makeRequest(
        'POST',
        ApiEndpoints.register,
        body: user.toJson(),
      );

      if (response.success && response.data != null) {
        // Backend returns { success: true, data: { user: {...}, token: "..." } }
        final responseData = response.data!['data'];

        if (responseData != null && responseData['user'] != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: responseData, // Contains both user and token
            message: response.data!['message'] ?? 'Inscription réussie',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Données utilisateur manquantes',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.message ?? 'Erreur lors de l\'inscription',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur lors de l\'inscription: ${e.toString()}',
      );
    }
  }

  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        ApiEndpoints.login,
        body: {'email': email.toLowerCase().trim(), 'password': password},
      );

      if (response.success && response.data != null) {
        // Backend returns { success: true, data: { user: {...}, token: "..." } }
        // Extract the nested 'data' field to match the register method pattern
        final responseData = response.data!['data'];

        if (responseData != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: responseData, // Contains both user and token
            message: response.data!['message'] ?? 'Connexion réussie',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Données utilisateur manquantes',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.message ?? 'Email ou mot de passe incorrect',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur lors de la connexion: ${e.toString()}',
      );
    }
  }

  /// Get current user info
  Future<ApiResponse<UserModel>> getCurrentUser(String token) async {
    try {
      final response = await _makeRequest('GET', ApiEndpoints.me, token: token);

      if (response.success && response.data != null) {
        final user = UserModel.fromJson(response.data!);

        return ApiResponse<UserModel>(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message:
              response.message ??
              'Impossible de récupérer les informations utilisateur',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Erreur lors de la récupération des données: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<ApiResponse<void>> logout(String token) async {
    try {
      final response = await _makeRequest(
        'POST',
        ApiEndpoints.logout,
        token: token,
      );

      if (response.success) {
        return ApiResponse<void>(
          success: true,
          message: 'Déconnexion réussie',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.message ?? 'Erreur lors de la déconnexion',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Erreur lors de la déconnexion: ${e.toString()}',
      );
    }
  }

  // Health check
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    try {
      final response = await _makeRequest(
        'GET',
        ApiEndpoints.health,
        timeout: const Duration(seconds: 10),
      );

      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Serveur non disponible',
      );
    }
  }

  // Profile Methods

  /// Update user profile
  Future<ApiResponse<UserModel>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;

      final response = await _makeRequest(
        'PUT',
        '${ApiEndpoints.agents}/me',
        body: body,
        token: token,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['data']['user'];
        final user = UserModel.fromJson(userData);

        return ApiResponse<UserModel>(
          success: true,
          data: user,
          message: response.data!['message'] ?? 'Profil mis à jour avec succès',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message:
              response.message ?? 'Erreur lors de la mise à jour du profil',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Erreur lors de la mise à jour du profil: ${e.toString()}',
      );
    }
  }

  /// Upload profile photo
  Future<ApiResponse<UserModel>> uploadProfilePhoto({
    required String token,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse(
        ApiEndpoints.getFullUrl('${ApiEndpoints.agents}/me/photo'),
      );

      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final apiResponse = _handleResponse(response);

      if (apiResponse.success && apiResponse.data != null) {
        final userData = apiResponse.data!['data']['user'];
        final user = UserModel.fromJson(userData);

        return ApiResponse<UserModel>(
          success: true,
          data: user,
          message:
              apiResponse.data!['message'] ?? 'Photo de profil mise à jour',
          statusCode: apiResponse.statusCode,
        );
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message:
              apiResponse.message ??
              'Erreur lors du téléchargement de la photo',
          statusCode: apiResponse.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Pas de connexion internet',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Erreur lors du téléchargement: ${e.toString()}',
      );
    }
  }

  /// Get MIME type for image file
  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Agent Methods

  /// Get all agents
  Future<ApiResponse<List<UserModel>>> getAllAgents(String token) async {
    try {
      final response = await _makeRequest(
        'GET',
        ApiEndpoints.agents,
        token: token,
      );

      if (response.success && response.data != null) {
        final agentsData = response.data!['data']['agents'] as List;
        final agents = agentsData
            .map((json) => UserModel.fromJson(json))
            .toList();

        return ApiResponse<List<UserModel>>(
          success: true,
          data: agents,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<UserModel>>(
          success: false,
          message:
              response.message ?? 'Erreur lors de la récupération des agents',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<UserModel>>(
        success: false,
        message: 'Erreur lors de la récupération des agents: ${e.toString()}',
      );
    }
  }

  /// Update agent availability status
  Future<ApiResponse<UserModel>> updateAgentStatus({
    required String agentId,
    required String availability,
    required String token,
  }) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '${ApiEndpoints.agents}/$agentId/status',
        body: {'availability': availability},
        token: token,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['data']['user'];
        final user = UserModel.fromJson(userData);

        return ApiResponse<UserModel>(
          success: true,
          data: user,
          message: response.data!['message'] ?? 'Statut mis à jour avec succès',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message:
              response.message ?? 'Erreur lors de la mise à jour du statut',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Erreur lors de la mise à jour du statut: ${e.toString()}',
      );
    }
  }

  // Reservation Methods

  /// Create a new reservation
  Future<ApiResponse<ReservationModel>> createReservation(
    ReservationModel reservation,
    String token,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        ApiEndpoints.createReservation,
        body: reservation.toJson(),
        token: token,
      );

      if (response.success && response.data != null) {
        // Backend returns { success: true, data: { reservation: {...} } }
        final reservationData = response.data!['data']['reservation'];

        if (reservationData != null) {
          final createdReservation = ReservationModel.fromJson(reservationData);
          return ApiResponse<ReservationModel>(
            success: true,
            data: createdReservation,
            message:
                response.data!['message'] ?? 'Réservation créée avec succès',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<ReservationModel>(
            success: false,
            message: 'Données de réservation manquantes',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<ReservationModel>(
          success: false,
          message:
              response.message ??
              'Erreur lors de la création de la réservation',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ReservationModel>(
        success: false,
        message:
            'Erreur lors de la création de la réservation: ${e.toString()}',
      );
    }
  }

  /// Get all reservations
  Future<ApiResponse<List<ReservationModel>>> getReservations(
    String token,
  ) async {
    try {
      final response = await _makeRequest(
        'GET',
        ApiEndpoints.reservations,
        token: token,
      );

      if (response.success && response.data != null) {
        try {
          final reservationsData =
              response.data!['data']['reservations'] as List;
          final reservations = reservationsData
              .map((json) {
                try {
                  return ReservationModel.fromJson(json);
                } catch (e) {
                  return null;
                }
              })
              .whereType<ReservationModel>() // Filter out nulls
              .toList();

          return ApiResponse<List<ReservationModel>>(
            success: true,
            data: reservations,
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse<List<ReservationModel>>(
            success: false,
            message: 'Erreur de format des données: ${e.toString()}',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<List<ReservationModel>>(
          success: false,
          message:
              response.message ??
              'Erreur lors de la récupération des réservations',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<ReservationModel>>(
        success: false,
        message:
            'Erreur lors de la récupération des réservations: ${e.toString()}',
      );
    }
  }

  /// Update reservation state
  Future<ApiResponse<ReservationModel>> updateReservationState(
    String reservationId,
    String state,
    String token,
  ) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '${ApiEndpoints.reservations}/$reservationId/state',
        body: {'state': state},
        token: token,
      );

      if (response.success && response.data != null) {
        final reservationData = response.data!['data']['reservation'];

        if (reservationData != null) {
          final updatedReservation = ReservationModel.fromJson(reservationData);
          return ApiResponse<ReservationModel>(
            success: true,
            data: updatedReservation,
            message:
                response.data!['message'] ?? 'État de réservation mis à jour',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<ReservationModel>(
            success: false,
            message: 'Données de réservation manquantes',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<ReservationModel>(
          success: false,
          message:
              response.message ?? 'Erreur lors de la mise à jour de l\'état',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<ReservationModel>(
        success: false,
        message: 'Erreur lors de la mise à jour de l\'état: ${e.toString()}',
      );
    }
  }

  /// Reject reservation and reassign to next agent (Agent Terrain only)
  Future<ApiResponse<ReservationModel>> rejectReservation(
    String reservationId,
    String token,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        '${ApiEndpoints.reservations}/$reservationId/reject',
        token: token,
      );

      if (response.success && response.data != null) {
        final reservationData = response.data!['data']['reservation'];
        if (reservationData != null) {
          final reservation = ReservationModel.fromJson(reservationData);
          return ApiResponse<ReservationModel>(
            success: true,
            data: reservation,
            message:
                response.data!['message'] ?? 'Réservation rejetée avec succès',
            statusCode: response.statusCode,
          );
        }
      }
      return ApiResponse<ReservationModel>(
        success: false,
        message: response.message ?? 'Erreur lors du rejet de la réservation',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<ReservationModel>(
        success: false,
        message: 'Erreur lors du rejet: ${e.toString()}',
      );
    }
  }

  /// Submit rapport after meeting (Agent Terrain only)
  Future<ApiResponse<ReservationModel>> submitRapport(
    String reservationId,
    String rapportState, // 'potentiel' or 'non_potentiel'
    String? rapportMessage,
    String token,
  ) async {
    try {
      final body = {
        'rapportState': rapportState,
        if (rapportMessage != null && rapportMessage.isNotEmpty)
          'rapportMessage': rapportMessage,
      };

      final response = await _makeRequest(
        'PUT',
        '${ApiEndpoints.reservations}/$reservationId/rapport',
        body: body,
        token: token,
      );

      if (response.success && response.data != null) {
        final reservationData = response.data!['data']['reservation'];
        if (reservationData != null) {
          final reservation = ReservationModel.fromJson(reservationData);
          return ApiResponse<ReservationModel>(
            success: true,
            data: reservation,
            message: response.data!['message'] ?? 'Rapport envoyé avec succès',
            statusCode: response.statusCode,
          );
        }
      }
      return ApiResponse<ReservationModel>(
        success: false,
        message: response.message ?? 'Erreur lors de l\'envoi du rapport',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<ReservationModel>(
        success: false,
        message: 'Erreur lors de l\'envoi du rapport: ${e.toString()}',
      );
    }
  }

  /// Take commercial action on rapport (Agent Commercial only)
  /// Actions: 'paye', 'en_cours', 'annule'
  Future<ApiResponse<ReservationModel>> takeCommercialAction(
    String reservationId,
    String action,
    String token, {
    String? newReservedAt, // Required for 'en_cours' action
    String? message, // Optional message for all actions
  }) async {
    try {
      final body = {
        'action': action,
        if (newReservedAt != null) 'newReservedAt': newReservedAt,
        if (message != null && message.isNotEmpty) 'message': message,
      };

      final response = await _makeRequest(
        'PUT',
        '${ApiEndpoints.reservations}/$reservationId/commercial-action',
        body: body,
        token: token,
      );

      if (response.success && response.data != null) {
        final reservationData = response.data!['data']['reservation'];
        if (reservationData != null) {
          final reservation = ReservationModel.fromJson(reservationData);
          return ApiResponse<ReservationModel>(
            success: true,
            data: reservation,
            message:
                response.data!['message'] ?? 'Action effectuée avec succès',
            statusCode: response.statusCode,
          );
        }
      }
      return ApiResponse<ReservationModel>(
        success: false,
        message: response.message ?? 'Erreur lors de l\'action commerciale',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<ReservationModel>(
        success: false,
        message: 'Erreur lors de l\'action: ${e.toString()}',
      );
    }
  }

  /// Get commercial suivi dashboard data (Agent Commercial only)
  Future<ApiResponse<Map<String, dynamic>>> getCommercialSuivi(
    String token, {
    String? section, // 'paye', 'annule', 'en_cours', or 'all'
    String? agentId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (section != null) queryParams['section'] = section;
      if (agentId != null) queryParams['agentId'] = agentId;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        ApiEndpoints.getFullUrl(
          '${ApiEndpoints.reservations}/commercial/suivi',
        ),
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _client
          .get(uri, headers: _getAuthHeaders(token))
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData.success && responseData.data != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData.data!['data'],
          message: responseData.data!['message'],
          statusCode: responseData.statusCode,
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: responseData.message ?? 'Erreur lors du chargement du suivi',
        statusCode: responseData.statusCode,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur lors du chargement du suivi: ${e.toString()}',
      );
    }
  }

  /// Get commercial calendar view (Agent Commercial only)
  Future<ApiResponse<Map<String, dynamic>>> getCommercialCalendar(
    String token, {
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse(
        ApiEndpoints.getFullUrl(
          '${ApiEndpoints.reservations}/commercial/calendar',
        ),
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _client
          .get(uri, headers: _getAuthHeaders(token))
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData.success && responseData.data != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData.data!['data'],
          message: responseData.data!['message'],
          statusCode: responseData.statusCode,
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            responseData.message ?? 'Erreur lors du chargement du calendrier',
        statusCode: responseData.statusCode,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur lors du chargement du calendrier: ${e.toString()}',
      );
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _client.close();
  }
}

// Singleton instance
final apiClient = ApiClient();
