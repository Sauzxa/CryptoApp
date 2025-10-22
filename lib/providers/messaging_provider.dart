import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/RoomModel.dart';
import '../services/messaging_service.dart';
import '../services/socket_service.dart';

class MessagingProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();

  // State
  List<RoomModel> _rooms = [];
  Map<String, List<MessageModel>> _roomMessages = {};
  Map<String, bool> _typingUsers = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRoomId;

  // Getters
  List<RoomModel> get rooms => _rooms;
  Map<String, List<MessageModel>> get roomMessages => _roomMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRoomId => _currentRoomId;

  List<MessageModel> getMessagesForRoom(String roomId) {
    return _roomMessages[roomId] ?? [];
  }

  RoomModel? getRoomById(String roomId) {
    try {
      return _rooms.firstWhere((room) => room.id == roomId);
    } catch (e) {
      return null;
    }
  }

  bool isUserTypingInRoom(String roomId) {
    return _typingUsers[roomId] ?? false;
  }

  /// Clear all messaging data (call on logout)
  void clearMessagingData() {
    debugPrint('🧹 MessagingProvider: Clearing all messaging data...');

    // Clear all state
    _rooms = [];
    _roomMessages = {};
    _typingUsers = {};
    _isLoading = false;
    _errorMessage = null;
    _currentRoomId = null;

    // Remove all socket listeners
    if (_socketService.socket != null) {
      final socket = _socketService.socket!;
      socket.off('message:new');
      socket.off('message:seen-update');
      socket.off('room:updated');
      socket.off('room:new');
      socket.off('room:typing-update');
      socket.off('room:member-left');
      socket.off('new_message');
      socket.off('message_sent');
      debugPrint('✅ MessagingProvider: All socket listeners removed');
    }

    notifyListeners();
    debugPrint('✅ MessagingProvider: Data cleared successfully');
  }

  /// Initialize messaging system with Socket.IO event listeners
  void initializeMessaging() {
    if (_socketService.socket == null) return;

    final socket = _socketService.socket!;

    // Listen for new messages
    socket.on('message:new', (data) {
      try {
        final message = MessageModel.fromJson(data['message']);
        final roomId = data['roomId'];

        _addMessageToRoom(roomId, message);
        _updateRoomLastMessage(roomId, message);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling new message: $e');
      }
    });

    // Listen for message seen updates
    socket.on('message:seen-update', (data) {
      try {
        final messageId = data['messageId'];
        final userId = data['userId'];
        final roomId = data['roomId'];

        _markMessageAsSeen(roomId, messageId, userId);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling seen update: $e');
      }
    });

    // Listen for room updates
    socket.on('room:updated', (data) {
      try {
        final roomId = data['roomId'];
        final lastMessage = MessageModel.fromJson(data['lastMessage']);

        _updateRoomLastMessage(roomId, lastMessage);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling room update: $e');
      }
    });

    // Listen for new rooms
    socket.on('room:new', (data) {
      try {
        final room = RoomModel.fromJson(data['room']);
        _rooms.insert(0, room);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling new room: $e');
      }
    });

    // Listen for typing indicators
    socket.on('room:typing-update', (data) {
      try {
        final roomId = data['roomId'];
        final isTyping = data['isTyping'];

        _typingUsers[roomId] = isTyping;
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling typing update: $e');
      }
    });

    // Listen for member leaving
    socket.on('room:member-left', (data) {
      try {
        final roomId = data['roomId'];
        final userId = data['userId'];

        _removeUserFromRoom(roomId, userId);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling member left: $e');
      }
    });

    debugPrint('✅ Messaging provider initialized');
  }

  /// Fetch all rooms
  Future<void> fetchRooms(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MessagingService.getUserRooms(token: token);

      if (result['success']) {
        _rooms = result['rooms'];
        _errorMessage = null;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Error fetching rooms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new room
  Future<bool> createRoom({
    required String token,
    required String name,
    required List<String> memberIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MessagingService.createRoom(
        token: token,
        name: name,
        memberIds: memberIds,
      );

      if (result['success']) {
        final newRoom = result['room'] as RoomModel;
        _rooms.insert(0, newRoom);
        _errorMessage = null;

        // Notify members via Socket.IO
        _socketService.socket?.emit('room:created', {
          'roomId': newRoom.id,
          'memberIds': memberIds,
        });

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating room: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch messages for a room
  Future<void> fetchRoomMessages({
    required String token,
    required String roomId,
  }) async {
    try {
      final result = await MessagingService.getRoomMessages(
        token: token,
        roomId: roomId,
      );

      if (result['success']) {
        _roomMessages[roomId] = result['messages'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  /// Join a room (for Socket.IO real-time updates)
  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    _socketService.socket?.emit('room:join', {'roomId': roomId});
    debugPrint('Joined room: $roomId');
  }

  /// Leave a room (Socket.IO)
  void leaveRoom(String roomId) {
    if (_currentRoomId == roomId) {
      _currentRoomId = null;
    }
    _socketService.socket?.emit('room:leave', {'roomId': roomId});
    debugPrint('Left room: $roomId');
  }

  /// Send a text message
  Future<bool> sendTextMessage({
    required String token,
    required String roomId,
    required String text,
  }) async {
    try {
      final result = await MessagingService.sendTextMessage(
        token: token,
        roomId: roomId,
        text: text,
      );

      if (result['success']) {
        final message = result['message'] as MessageModel;

        // Add to local state immediately for better UX
        _addMessageToRoom(roomId, message);
        _updateRoomLastMessage(roomId, message);
        notifyListeners();

        // Socket.IO will handle real-time delivery to other users
        // No need to emit here, backend already handles it

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      return false;
    }
  }

  /// Send a voice message
  Future<bool> sendVoiceMessage({
    required String token,
    required String roomId,
    required File voiceFile,
    required int duration,
  }) async {
    try {
      final result = await MessagingService.sendVoiceMessage(
        token: token,
        roomId: roomId,
        voiceFile: voiceFile,
        duration: duration,
      );

      if (result['success']) {
        final message = result['message'] as MessageModel;

        // Add to local state immediately for better UX
        _addMessageToRoom(roomId, message);
        _updateRoomLastMessage(roomId, message);
        notifyListeners();

        // Socket.IO will handle real-time delivery to other users
        // No need to emit here, backend already handles it

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending voice message: $e');
      return false;
    }
  }

  /// Mark messages as seen
  Future<void> markMessagesAsSeen({
    required String token,
    required String roomId,
  }) async {
    try {
      await MessagingService.markRoomMessagesAsSeen(
        token: token,
        roomId: roomId,
      );
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  /// Leave a room permanently
  Future<bool> leaveRoomPermanently({
    required String token,
    required String roomId,
  }) async {
    try {
      final result = await MessagingService.leaveRoom(
        token: token,
        roomId: roomId,
      );

      if (result['success']) {
        _rooms.removeWhere((room) => room.id == roomId);
        _roomMessages.remove(roomId);

        // Notify other members
        _socketService.socket?.emit('room:user-left', {
          'roomId': roomId,
          'userId': token, // Replace with actual userId
        });

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error leaving room: $e');
      return false;
    }
  }

  /// Emit typing indicator
  void emitTyping(String roomId, bool isTyping) {
    _socketService.socket?.emit('room:typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  // Private helper methods

  void _addMessageToRoom(String roomId, MessageModel message) {
    if (_roomMessages[roomId] == null) {
      _roomMessages[roomId] = [];
    }

    // Avoid duplicates
    final existingIndex = _roomMessages[roomId]!.indexWhere(
      (msg) => msg.id == message.id,
    );

    if (existingIndex == -1) {
      _roomMessages[roomId]!.add(message);
    } else {
      _roomMessages[roomId]![existingIndex] = message;
    }
  }

  void _updateRoomLastMessage(String roomId, MessageModel message) {
    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex] = _rooms[roomIndex].copyWith(
        lastMessage: message,
        updatedAt: message.createdAt,
      );

      // Move room to top
      final room = _rooms.removeAt(roomIndex);
      _rooms.insert(0, room);
    }
  }

  void _markMessageAsSeen(String roomId, String messageId, String userId) {
    if (_roomMessages[roomId] == null) return;

    final messageIndex = _roomMessages[roomId]!.indexWhere(
      (msg) => msg.id == messageId,
    );

    if (messageIndex != -1) {
      final message = _roomMessages[roomId]![messageIndex];
      if (!message.seenBy.contains(userId)) {
        final updatedSeenBy = [...message.seenBy, userId];
        _roomMessages[roomId]![messageIndex] = message.copyWith(
          seenBy: updatedSeenBy,
        );
      }
    }
  }

  void _removeUserFromRoom(String roomId, String userId) {
    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final updatedMembers = room.members
          .where((member) => member.id != userId)
          .toList();

      _rooms[roomIndex] = room.copyWith(members: updatedMembers);
    }
  }

  /// Delete room (admin/creator only)
  Future<bool> deleteRoom({
    required String token,
    required String roomId,
  }) async {
    try {
      final result = await MessagingService.deleteRoom(
        token: token,
        roomId: roomId,
      );

      if (result['success']) {
        _rooms.removeWhere((room) => room.id == roomId);
        _roomMessages.remove(roomId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting room: $e');
      return false;
    }
  }

  /// Add members to room (admin/creator only)
  Future<bool> addMembersToRoom({
    required String token,
    required String roomId,
    required List<String> memberIds,
  }) async {
    try {
      final result = await MessagingService.addMembersToRoom(
        token: token,
        roomId: roomId,
        memberIds: memberIds,
      );

      if (result['success']) {
        final updatedRoom = result['room'] as RoomModel;
        final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
        if (roomIndex != -1) {
          _rooms[roomIndex] = updatedRoom;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding members: $e');
      return false;
    }
  }

  /// Remove member from room (admin/creator only)
  Future<bool> removeMemberFromRoom({
    required String token,
    required String roomId,
    required String memberId,
  }) async {
    try {
      final result = await MessagingService.removeMemberFromRoom(
        token: token,
        roomId: roomId,
        memberId: memberId,
      );

      if (result['success']) {
        final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
        if (roomIndex != -1) {
          final room = _rooms[roomIndex];
          final updatedMembers = room.members
              .where((member) => member.id != memberId)
              .toList();
          _rooms[roomIndex] = room.copyWith(members: updatedMembers);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return false;
    }
  }

  /// Find or create direct room
  Future<RoomModel?> findOrCreateDirectRoom({
    required String token,
    required String otherUserId,
  }) async {
    try {
      final result = await MessagingService.findOrCreateDirectRoom(
        token: token,
        otherUserId: otherUserId,
      );

      if (result['success']) {
        final room = result['room'] as RoomModel;
        final isNew = result['isNew'] as bool;

        if (isNew) {
          // Add to rooms list if it's a new room
          _rooms.insert(0, room);
          notifyListeners();
        } else {
          // Update existing room if found
          final roomIndex = _rooms.indexWhere((r) => r.id == room.id);
          if (roomIndex == -1) {
            // Room exists in DB but not in local state, add it
            _rooms.insert(0, room);
            notifyListeners();
          }
        }

        return room;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding/creating direct room: $e');
      return null;
    }
  }

  /// Create a reservation room between agent terrain and agent commercial
  Future<Map<String, dynamic>> createReservationRoom({
    required String token,
    required String reservationId,
    required String agentCommercialId,
    required String agentTerrainId,
    required String clientName,
  }) async {
    try {
      final result = await MessagingService.createReservationRoom(
        token: token,
        reservationId: reservationId,
        agentCommercialId: agentCommercialId,
        agentTerrainId: agentTerrainId,
        clientName: clientName,
      );

      if (result['success']) {
        final room = result['room'] as RoomModel;

        // Add to rooms list
        _rooms.add(room);
        notifyListeners();

        return {'success': true, 'room': room};
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Clean up
  void dispose() {
    _rooms.clear();
    _roomMessages.clear();
    _typingUsers.clear();
    super.dispose();
  }
}
