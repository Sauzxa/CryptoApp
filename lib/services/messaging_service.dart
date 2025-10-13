import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../api/api_endpoints.dart';
import '../models/RoomModel.dart';

class MessagingService {
  // Create a new room
  static Future<Map<String, dynamic>> createRoom({
    required String token,
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/messages/rooms');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'memberIds': memberIds}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'room': RoomModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create room',
        };
      }
    } catch (e) {
      print('Error creating room: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get all rooms for current user
  static Future<Map<String, dynamic>> getUserRooms({
    required String token,
  }) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/messages/rooms');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final rooms = (data['data'] as List)
            .map((room) => RoomModel.fromJson(room))
            .toList();

        return {'success': true, 'rooms': rooms};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch rooms',
        };
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get messages in a room
  static Future<Map<String, dynamic>> getRoomMessages({
    required String token,
    required String roomId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/messages',
      );

      final queryParams = {
        'limit': limit.toString(),
        if (before != null) 'before': before.toIso8601String(),
      };

      uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final messages = (data['data'] as List)
            .map((msg) => MessageModel.fromJson(msg))
            .toList();

        return {'success': true, 'messages': messages};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch messages',
        };
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Send text message
  static Future<Map<String, dynamic>> sendTextMessage({
    required String token,
    required String roomId,
    required String text,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/messages',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': MessageModel.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      print('Error sending text message: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Send voice message
  static Future<Map<String, dynamic>> sendVoiceMessage({
    required String token,
    required String roomId,
    required File voiceFile,
    required int duration,
  }) async {
    try {
      print('📤 Sending voice message:');
      print('  Room ID: $roomId');
      print('  File path: ${voiceFile.path}');
      print('  File exists: ${await voiceFile.exists()}');
      print('  Duration: $duration');

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/messages',
      );

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add file with explicit content type for m4a
      final file = await http.MultipartFile.fromPath(
        'voice',
        voiceFile.path,
        contentType: MediaType('audio', 'm4a'), // Explicitly set content type
      );
      request.files.add(file);
      request.fields['voiceDuration'] = duration.toString();

      print('📡 Sending request to: $url');
      print('📡 File content type: ${file.contentType}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Voice message sent successfully');
        return {
          'success': true,
          'message': MessageModel.fromJson(data['data']),
        };
      } else {
        print('❌ Failed to send voice message: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send voice message',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Error sending voice message: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Mark messages as seen
  static Future<Map<String, dynamic>> markRoomMessagesAsSeen({
    required String token,
    required String roomId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/messages/seen',
      );

      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark messages as seen',
        };
      }
    } catch (e) {
      print('Error marking messages as seen: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Leave room
  static Future<Map<String, dynamic>> leaveRoom({
    required String token,
    required String roomId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/leave',
      );

      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to leave room',
        };
      }
    } catch (e) {
      print('Error leaving room: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get available users to invite
  static Future<Map<String, dynamic>> getAvailableUsers({
    required String token,
    String? roomId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/users/available${roomId != null ? '/$roomId' : ''}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final users = (data['data'] as List)
            .map((user) => UserBasic.fromJson(user))
            .toList();

        return {'success': true, 'users': users};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch users',
        };
      }
    } catch (e) {
      print('Error fetching available users: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Delete room (admin/creator only)
  static Future<Map<String, dynamic>> deleteRoom({
    required String token,
    required String roomId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId',
      );

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete room',
        };
      }
    } catch (e) {
      print('Error deleting room: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Add members to room (admin/creator only)
  static Future<Map<String, dynamic>> addMembersToRoom({
    required String token,
    required String roomId,
    required List<String> memberIds,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/members',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'memberIds': memberIds}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'room': RoomModel.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add members',
        };
      }
    } catch (e) {
      print('Error adding members: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Remove member from room (admin/creator only)
  static Future<Map<String, dynamic>> removeMemberFromRoom({
    required String token,
    required String roomId,
    required String memberId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/$roomId/members/$memberId',
      );

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to remove member',
        };
      }
    } catch (e) {
      print('Error removing member: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Find or create direct room
  static Future<Map<String, dynamic>> findOrCreateDirectRoom({
    required String token,
    required String otherUserId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/messages/rooms/direct',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otherUserId': otherUserId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'room': RoomModel.fromJson(data['data']),
          'isNew': data['isNew'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create/find room',
        };
      }
    } catch (e) {
      print('Error finding/creating direct room: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
