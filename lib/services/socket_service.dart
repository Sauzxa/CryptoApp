import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_endpoints.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  /// Initialize and connect to Socket.IO server
  Future<void> connect(String token) async {
    if (_isConnected && _socket != null) {
      return;
    }

    try {
      _socket = IO.io(
        ApiEndpoints.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Use websocket transport
            .enableAutoConnect() // Auto-connect
            .enableReconnection() // Enable auto-reconnection
            .setReconnectionAttempts(5) // Try 5 times
            .setReconnectionDelay(2000) // Wait 2 seconds between attempts
            .setAuth({
              'token': token, // Send token for authentication
            })
            .build(),
      );

      // Connection event handlers
      _socket!.onConnect((_) {
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
      });

      _socket!.onError((error) {});

      _socket!.onReconnect((attempt) {});

      _socket!.onReconnectError((error) {});

      _socket!.onReconnectFailed((_) {});

      // Connect manually if not auto-connected
      if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      _isConnected = false;
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      try {
        // Remove all listeners first
        removeAllListeners();

        // Disconnect the socket
        _socket!.disconnect();

        // Dispose of the socket
        _socket!.dispose();

        // Clear the reference
        _socket = null;
        _isConnected = false;
      } catch (e) {
        // Force clear anyway
        _socket = null;
        _isConnected = false;
      }
    } else {}
  }

  /// Emit agent status change event
  void emitStatusChange(String availability) {
    if (_socket != null && _isConnected) {
      _socket!.emit('agent:set-status', {'availability': availability});
    } else {}
  }

  /// Listen for agent status updates from other clients
  void onAgentStatusUpdate(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('agent:status', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('notification', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation created events
  void onReservationCreated(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:created', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation updated events
  void onReservationUpdated(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:updated', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Acknowledge notification
  void acknowledgeNotification(String notificationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('ack:notification', {'notificationId': notificationId});
    }
  }

  /// Listen for agent available notifications (for commercial agents)
  void onAgentAvailable(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('agent_available', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation rejected event (Agent Terrain)
  void onReservationRejected(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:rejected', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation assigned event (Agent Terrain)
  void onReservationAssigned(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:assigned', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation reassigned event (Agent Commercial)
  void onReservationReassigned(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:reassigned', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for rapport submitted event (Agent Commercial)
  void onRapportSubmitted(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('rapport:submitted', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for availability toggle enabled event (Agent Terrain)
  void onAvailabilityToggleEnabled(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('agent:availability_toggle_enabled', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for commercial action event (Both agents)
  void onCommercialAction(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:commercial_action', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Listen for reservation rescheduled event (Agent Terrain)
  void onReservationRescheduled(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('reservation:rescheduled', (data) {
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Remove all listeners
  void removeAllListeners() {
    if (_socket != null) {
      _socket!.off('agent:status');
      _socket!.off('agent:status_changed');
      _socket!.off('notification');
      _socket!.off('reservation:created');
      _socket!.off('reservation:updated');
      _socket!.off('agent_available');
      // New events
      _socket!.off('reservation:rejected');
      _socket!.off('reservation:assigned');
      _socket!.off('reservation:reassigned');
      _socket!.off('rapport:submitted');
      _socket!.off('agent:availability_toggle_enabled');
      _socket!.off('reservation:commercial_action');
      _socket!.off('reservation:rescheduled');
    }
  }
}

// Singleton instance
final socketService = SocketService();
