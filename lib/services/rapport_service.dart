import 'dart:async';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../services/socket_service.dart';
import '../utils/socket_timeout_manager.dart';

/// Service to handle rapport submission with socket-first approach and API fallback
class RapportService {
  final ApiClient _apiClient;
  final SocketService _socketService;
  final SocketTimeoutManager _timeoutManager;

  RapportService({
    required ApiClient apiClient,
    required SocketService socketService,
  }) : _apiClient = apiClient,
       _socketService = socketService,
       _timeoutManager = SocketTimeoutManager();

  /// Submit a rapport with idempotency and dual-path submission (socket + API fallback)
  Future<RapportSubmissionResult> submitRapport({
    required String reservationId,
    required String rapportState,
    required String rapportMessage,
    required String token,
    required String roomId,
  }) async {
    // Generate unique idempotency key
    final idempotencyKey = const Uuid().v4();

    print('📤 Submitting rapport:');
    print('   - Reservation ID: $reservationId');
    print('   - Rapport state: $rapportState');
    print('   - Idempotency Key: $idempotencyKey');

    // Map rapport state to result
    final result = rapportState == 'potentiel' ? 'completed' : 'cancelled';

    // EXCLUSIVE PATH STRATEGY:
    // If socket is connected, use it exclusively. Do NOT fallback to API on timeout/error
    // to prevent duplicate submissions (race condition where socket works but ACK is slow).
    if (_socketService.socket?.connected == true) {
      print('🔌 Socket connected, attempting submission via socket ONLY');
      return await _trySocketSubmission(
        roomId: roomId,
        reservationId: reservationId,
        rapportState: rapportState,
        rapportMessage: rapportMessage,
        result: result,
        idempotencyKey: idempotencyKey,
      );
    }

    // Only use API if socket is explicitly disconnected
    print('🔌 Socket disconnected, using API submission');
    return await _tryApiSubmission(
      reservationId: reservationId,
      rapportState: rapportState,
      rapportMessage: rapportMessage,
      token: token,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Try submitting via socket with acknowledgment
  Future<RapportSubmissionResult> _trySocketSubmission({
    required String roomId,
    required String reservationId,
    required String rapportState,
    required String rapportMessage,
    required String result,
    required String idempotencyKey,
  }) async {
    final socket = _socketService.socket;

    if (socket == null || !socket.connected) {
      print('⚠️ Socket not available');
      return RapportSubmissionResult(
        success: false,
        message: 'Socket not connected',
      );
    }

    print('📤 Attempting socket submission...');

    // Create completer for acknowledgment
    final completer = Completer<RapportSubmissionResult>();
    final startTime = DateTime.now();

    // Set up one-time listener for acknowledgment
    void ackListener(dynamic data) {
      print('✅ Socket ACK received: $data');
      if (!completer.isCompleted) {
        final success = data is Map && data['success'] == true;
        final message = data is Map ? data['message'] as String? : null;

        completer.complete(
          RapportSubmissionResult(
            success: success,
            message:
                message ?? (success ? 'Rapport envoyé avec succès' : 'Erreur'),
          ),
        );
      }
    }

    socket.once('rapport:submitted', ackListener);

    // Set adaptive timeout
    final adaptiveTimeout = _timeoutManager.getTimeout();
    final timeoutTimer = Timer(adaptiveTimeout, () {
      if (!completer.isCompleted) {
        print(
          '⏱️ Socket acknowledgment timeout after ${adaptiveTimeout.inSeconds}s',
        );
        socket.off('rapport:submitted', ackListener);
        completer.complete(
          RapportSubmissionResult(
            success: false,
            message: 'Timeout waiting for server response',
          ),
        );
      }
    });

    // Send rapport via socket
    socket.emit('reservation_room:send_message', {
      'roomId': roomId,
      'type': 'rapport',
      'text': rapportMessage,
      'result': result,
      'rapportState': rapportState,
      'reservationId': reservationId,
      'idempotencyKey': idempotencyKey,
    });

    print('📤 Rapport sent via socket, waiting for acknowledgment...');

    // Wait for acknowledgment or timeout
    final socketResult = await completer.future;
    timeoutTimer.cancel();

    // Record response time for adaptive timeout
    if (socketResult.success) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _timeoutManager.recordResponseTime(responseTime);
      print('✅ Socket response time: ${responseTime}ms');
    }

    return socketResult;
  }

  /// Try submitting via API
  Future<RapportSubmissionResult> _tryApiSubmission({
    required String reservationId,
    required String rapportState,
    required String rapportMessage,
    required String token,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.submitRapport(
      reservationId,
      rapportState,
      rapportMessage,
      token,
      idempotencyKey: idempotencyKey,
    );

    return RapportSubmissionResult(
      success: response.success,
      message:
          response.message ??
          (response.success
              ? 'Rapport envoyé avec succès'
              : 'Erreur lors de l\'envoi'),
    );
  }
}

/// Result of a rapport submission
class RapportSubmissionResult {
  final bool success;
  final String message;

  RapportSubmissionResult({required this.success, required this.message});
}
