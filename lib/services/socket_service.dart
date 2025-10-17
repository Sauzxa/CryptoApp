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
      print('✅ Socket already connected');
      return;
    }

    try {
      print('🔌 Connecting to Socket.IO server...');
      print('🔑 Using token: ${token.substring(0, 20)}...');

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
        print('✅ Socket connected successfully');
        print('📡 Socket ID: ${_socket!.id}');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        print('❌ Socket connection error: $error');
      });

      _socket!.onError((error) {
        print('❌ Socket error: $error');
      });

      _socket!.onReconnect((attempt) {
        print('🔄 Socket reconnecting... Attempt: $attempt');
      });

      _socket!.onReconnectError((error) {
        print('❌ Socket reconnection error: $error');
      });

      _socket!.onReconnectFailed((_) {
        print('❌ Socket reconnection failed after multiple attempts');
      });

      // Connect manually if not auto-connected
      if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      print('❌ Error initializing socket: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      print('🔌 Disconnecting socket...');
      
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
        
        print('✅ Socket disconnected and disposed');
      } catch (e) {
        print('⚠️ Error during socket disconnect: $e');
        // Force clear anyway
        _socket = null;
        _isConnected = false;
      }
    } else {
      print('ℹ️ Socket already disconnected');
    }
  }

  /// Emit agent status change event
  void emitStatusChange(String availability) {
    if (_socket != null && _isConnected) {
      print('📤 Emitting agent status: $availability');
      _socket!.emit('agent:set-status', {'availability': availability});
    } else {
      print('❌ Cannot emit status: Socket not connected');
    }
  }

  /// Listen for agent status updates from other clients
  void onAgentStatusUpdate(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('agent:status', (data) {
        print('📥 Received agent status update: $data');
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
        print('📥 Received notification: $data');
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
        print('📥 Received reservation created: $data');
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
        print('📥 Received reservation updated: $data');
        if (data is Map<String, dynamic>) {
          callback(data);
        }
      });
    }
  }

  /// Acknowledge notification
  void acknowledgeNotification(String notificationId) {
    if (_socket != null && _isConnected) {
      print('📤 Acknowledging notification: $notificationId');
      _socket!.emit('ack:notification', {'notificationId': notificationId});
    }
  }

  /// Listen for agent available notifications (for commercial agents)
  void onAgentAvailable(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('agent_available', (data) {
        print('📥 Received agent_available notification: $data');
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
      _socket!.off('notification');
      _socket!.off('reservation:created');
      _socket!.off('reservation:updated');
      _socket!.off('agent_available');
      print('🧹 Removed all socket listeners');
    }
  }
}

// Singleton instance
final socketService = SocketService();
