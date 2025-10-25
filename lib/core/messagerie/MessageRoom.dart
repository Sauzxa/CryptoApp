import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/providers/messaging_provider.dart';
import 'package:CryptoApp/models/RoomModel.dart';
import 'package:CryptoApp/api/api_endpoints.dart';
import 'package:CryptoApp/api/api_client.dart';
import 'package:CryptoApp/services/messaging_service.dart';
import 'package:CryptoApp/services/socket_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:intl/intl.dart';
import 'package:CryptoApp/utils/snackbar_utils.dart';
import 'RapportBottomSheet.dart';
import 'CommercialActionBottomSheet.dart';

class MessageRoomPage extends StatefulWidget {
  final RoomModel room;

  const MessageRoomPage({Key? key, required this.room}) : super(key: key);

  @override
  State<MessageRoomPage> createState() => _MessageRoomPageState();
}

class _MessageRoomPageState extends State<MessageRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  late final RecorderController _recorderController;
  final Map<String, PlayerController> _playerControllers = {};
  StreamSubscription<void>? _audioPlayerCompleteSubscription;

  bool _isRecording = false;
  bool _isLoadingMessages = true;
  bool _isSendingMessage = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  String? _currentlyPlayingMessageId;
  int _previousMessageCount = 0;
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    // Debug: Print room commercialAction value
    print(
      '🔍 INIT: widget.room.commercialAction = ${widget.room.commercialAction}',
    );
    print('🔍 INIT: widget.room.id = ${widget.room.id}');
    print('🔍 INIT: widget.room.reservationId = ${widget.room.reservationId}');
    print('🔍 INIT: Full room data: ${widget.room.toJson()}');

    // Join socket room for real-time messages
    _joinSocketRoom();
    _setupSocketListeners();

    // Initialize waveform recorder controller with optimized quality settings
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate =
          48000 // Higher sample rate for better quality
      ..bitRate = 192000; // Higher bitrate for better quality

    // Listen for audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((ap.PlayerState state) {
      if (state == ap.PlayerState.completed) {
        if (mounted) {
          setState(() {
            _currentlyPlayingMessageId = null;
          });
        }
      }
    });

    // Listen for audio player completion - store subscription to cancel later
    _audioPlayerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((
      _,
    ) {
      if (mounted) {
        setState(() {
          _currentlyPlayingMessageId = null;
        });
      }
    });

    // Listen to text field changes to update send button color
    _messageController.addListener(() {
      setState(() {
        // This will trigger rebuild to update send button color
      });
    });

    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    final token = authProvider.token;
    if (token != null) {
      // Join room for Socket.IO updates
      messagingProvider.joinRoom(widget.room.id);

      // Fetch messages
      await messagingProvider.fetchRoomMessages(
        token: token,
        roomId: widget.room.id,
      );

      // Mark messages as seen
      await messagingProvider.markMessagesAsSeen(
        token: token,
        roomId: widget.room.id,
      );
    }

    setState(() {
      _isLoadingMessages = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _joinSocketRoom() {
    final socket = socketService.socket;
    if (socket == null || widget.room.id.isEmpty) return;

    print('🔌 Joining socket room: ${widget.room.id}');
    print('🔌 Room type: ${widget.room.roomType}');
    print('🔌 Reservation ID: ${widget.room.reservationId}');

    // Check if this is a reservation room
    if (widget.room.roomType == 'reservation' &&
        widget.room.reservationId != null) {
      print('🔌 Joining reservation room via socket');
      socket.emit('reservation_room:join', {
        'roomId': widget.room.id,
        'reservationId': widget.room.reservationId,
        'agentCommercialId': widget.room.agentCommercialId,
        'agentTerrainId': widget.room.agentTerrainId,
      });
    } else {
      print('🔌 Joining normal room via socket');
      socket.emit('room:join', {'roomId': widget.room.id});
    }
  }

  void _setupSocketListeners() {
    final socket = socketService.socket;
    if (socket == null) {
      return;
    }

    final isReservationRoom = widget.room.roomType == 'reservation';

    if (isReservationRoom) {
      // Reservation room specific listeners
      socket.on('reservation_room:message', (data) {
        _reloadMessages();
      });

      socket.on('reservation_room:joined', (data) {});

      socket.on('reservation_room:error', (data) {
        print('❌ Socket error: ${data['message']}');
        if (mounted) {
          SnackbarUtils.showError(context, 'Erreur: ${data['message']}');
        }
      });
    } else {
      // Normal room listeners
      socket.on('new_message', (data) {
        _reloadMessages();
      });

      socket.on('message_sent', (data) {
        _reloadMessages();
      });

      socket.on('room:joined', (data) {});
    }

    // Common error listener
    socket.on('error', (data) {
      print('❌ General socket error: ${data['message']}');
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${data['message']}');
      }
    });
  }

  void _removeSocketListeners() {
    final socket = socketService.socket;
    if (socket == null) return;

    final isReservationRoom = widget.room.roomType == 'reservation';

    if (isReservationRoom) {
      socket.off('reservation_room:message');
      socket.off('reservation_room:joined');
      socket.off('reservation_room:error');

      // Leave reservation room
      if (widget.room.id.isNotEmpty) {
        socket.emit('reservation_room:leave', {'roomId': widget.room.id});
      }
    } else {
      socket.off('new_message');
      socket.off('message_sent');
      socket.off('room:joined');

      // Leave normal room
      if (widget.room.id.isNotEmpty) {
        socket.emit('room:leave', {'roomId': widget.room.id});
      }
    }

    socket.off('error');
  }

  Future<void> _reloadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    final token = authProvider.token;
    if (token != null) {
      await messagingProvider.fetchRoomMessages(
        token: token,
        roomId: widget.room.id,
      );

      messagingProvider.getMessagesForRoom(widget.room.id);
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _isSendingMessage = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;

    if (token != null) {
      _messageController.clear();

      final success = await messagingProvider.sendTextMessage(
        token: token,
        roomId: widget.room.id,
        text: text,
      );

      if (!mounted) return;

      if (success) {
        // Scroll to bottom
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Erreur lors de l\'envoi du message',
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permission status first
      final micStatus = await Permission.microphone.status;

      // Request permission if not already granted
      if (!micStatus.isGranted) {
        final result = await Permission.microphone.request();

        if (!result.isGranted) {
          if (!mounted) return;

          // Show different message for permanently denied
          if (result.isPermanentlyDenied) {
            SnackbarUtils.showError(
              context,
              'Permission microphone refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.',
              duration: const Duration(seconds: 5),
            );
          } else {
            SnackbarUtils.showWarning(
              context,
              'Permission microphone requise pour enregistrer des messages vocaux.',
            );
          }
          return;
        }
      }

      // Check storage permission for Android 12 and below
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;

        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }

      // Double check with audio recorder
      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;
        SnackbarUtils.showError(
          context,
          'Erreur: Permission microphone non disponible',
        );
        return;
      }

      // Permission granted, start recording

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start both audio recorder and waveform recorder with optimized settings
      await Future.wait([
        _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 192000, // Higher bitrate for better quality
            sampleRate: 48000, // Higher sample rate for better quality
            numChannels: 1, // Mono for voice
            autoGain: false, // Disable auto gain to prevent cutting
            echoCancel: false, // Disable echo cancellation to prevent artifacts
            noiseSuppress:
                false, // Disable noise suppression to prevent cutting
          ),
          path: path,
        ),
        _recorderController.record(path: path),
      ]);

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
      });

      // Update duration every second
      _updateRecordingDuration();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erreur: $e');
    }
  }

  void _updateRecordingDuration() {
    if (_isRecording) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording) {
          setState(() {
            _recordingDuration++;
          });
          _updateRecordingDuration();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop both audio recorder and waveform recorder
      final results = await Future.wait([
        _audioRecorder.stop(),
        _recorderController.stop(),
      ]);

      final path = results[0];

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (path != null && path.isNotEmpty) {
        // Check file size to verify audio was captured
        final file = File(path);
        if (await file.exists()) {
          await file.length();
        }

        await _sendVoiceMessage(path);
      } else {}
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      SnackbarUtils.showError(
        context,
        'Erreur lors de l\'arrêt de l\'enregistrement: $e',
      );
    }
  }

  Future<void> _cancelRecording() async {
    try {
      // Stop both recorders
      await Future.wait([
        _audioRecorder.stop(),
        _recorderController.stop(false), // false = don't save the file
      ]);

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = 0;
      });

      // Delete the file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = 0;
      });

      SnackbarUtils.showError(context, 'Erreur lors de l\'annulation: $e');
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    if (!mounted) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );
      final token = authProvider.token;

      if (token != null) {
        final file = File(path);

        // Check if file exists
        if (!await file.exists()) {
          throw Exception('Fichier audio introuvable');
        }

        final success = await messagingProvider.sendVoiceMessage(
          token: token,
          roomId: widget.room.id,
          voiceFile: file,
          duration: _recordingDuration,
        );

        if (!mounted) return;

        if (success) {
          // Delete temporary file
          if (await file.exists()) {
            await file.delete();
          }

          // Scroll to bottom
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        } else {
          if (mounted) {
            SnackbarUtils.showError(
              context,
              'Erreur lors de l\'envoi du message vocal',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _recordingDuration = 0;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _playVoiceMessage(MessageModel message) async {
    try {
      if (_currentlyPlayingMessageId == message.id) {
        // Stop playing
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _currentlyPlayingMessageId = null;
        });
      } else {
        // Stop any currently playing audio first
        if (_currentlyPlayingMessageId != null) {
          await _audioPlayer.stop();
        }

        // Start playing with optimized settings
        final voiceUrl = message.voiceUrl;
        if (voiceUrl != null && voiceUrl.isNotEmpty) {
          // Construct full URL if it's a relative path
          final fullUrl = voiceUrl.startsWith('http')
              ? voiceUrl
              : '${ApiEndpoints.baseUrl}$voiceUrl';

          // Configure audio player for better quality playback
          await _audioPlayer.setVolume(1.0); // Full volume
          await _audioPlayer.setPlaybackRate(1.0); // Normal playback rate

          // Play with high quality settings
          await _audioPlayer.play(ap.UrlSource(fullUrl));

          if (!mounted) return;
          setState(() {
            _currentlyPlayingMessageId = message.id;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentlyPlayingMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lecture audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    // Check if this is a rapport message
    if (message.isRapport) {
      return _buildRapportMessage(message);
    }

    // Check if this is a commercial action message
    if (message.type == 'commercial_action') {
      return _buildCommercialActionMessage(message);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for other users (left side)
          if (!isMe) ...[
            _buildProfilePicture(message.sender),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom: 2,
                left: isMe ? 64 : 0,
                right: isMe ? 0 : 64,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF6366F1)
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name (if not me)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),

                  // Message content
                  if (message.type == 'text')
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1F2937),
                        fontSize: 15,
                      ),
                    )
                  else
                    _buildVoiceMessageContent(message, isMe),

                  const SizedBox(height: 4),

                  // Timestamp and seen indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeago.format(message.createdAt, locale: 'fr'),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.seenBy.length > 1
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.seenBy.length > 1
                              ? Colors.blue.shade200
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Profile picture for current user (right side)
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildProfilePicture(message.sender),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePicture(UserBasic user) {
    final hasProfilePhoto =
        user.profilePhoto != null && user.profilePhoto!.url != null;

    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
      backgroundImage: hasProfilePhoto
          ? NetworkImage(
              user.profilePhoto!.url!.startsWith('http')
                  ? user.profilePhoto!.url!
                  : '${ApiEndpoints.baseUrl}${user.profilePhoto!.url!}',
            )
          : null,
      child: !hasProfilePhoto
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            )
          : null,
    );
  }

  Widget _buildVoiceMessageContent(MessageModel message, bool isMe) {
    final isPlaying = _currentlyPlayingMessageId == message.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playVoiceMessage(message),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.white : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform-style visualization
              SizedBox(
                height: 35,
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(25, (index) {
                    // Create varied heights for waveform effect
                    final heights = [
                      0.3,
                      0.5,
                      0.8,
                      1.0,
                      0.7,
                      0.4,
                      0.6,
                      0.9,
                      0.5,
                      0.3,
                    ];
                    final heightFactor = heights[index % heights.length];

                    return Container(
                      width: 2.5,
                      height: 35 * heightFactor,
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF6366F1).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.voiceDuration ?? 0}s',
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(top: BorderSide(color: Colors.red.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Enregistrement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_recordingDuration}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Waveform visualization
                SizedBox(
                  height: 40,
                  child: AudioWaveforms(
                    size: Size(MediaQuery.of(context).size.width - 200, 40),
                    recorderController: _recorderController,
                    enableGesture: false,
                    waveStyle: WaveStyle(
                      waveColor: Colors.red,
                      extendWaveform: true,
                      showMiddleLine: false,
                      scaleFactor: 100,
                      waveThickness: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _stopRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Rapport button (only for reservation rooms and agent terrain)
          if (_isReservationRoom() && _isAgentTerrain()) ...[
            GestureDetector(
              onTap: _showRapportBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Voice message button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.grey.shade300
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                color: _isRecording
                    ? Colors.grey.shade600
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isSendingMessage ? null : _sendTextMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty
                    ? Colors.grey.shade300
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: _isSendingMessage
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for rapport functionality
  bool _isReservationRoom() {
    return widget.room.roomType == 'reservation' &&
        widget.room.reservationId != null;
  }

  bool _isAgentTerrain() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isField;
  }

  Future<void> _showRapportBottomSheet() async {
    try {
      // Fetch all reservations to find the current one
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || widget.room.reservationId == null) return;

      // Get all reservations and find the current one
      final response = await apiClient.getReservations(token);

      if (!response.success || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du chargement des détails'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Find the reservation by ID
      final reservation = response.data!.firstWhere(
        (r) => r.id == widget.room.reservationId,
        orElse: () => throw Exception('Reservation not found'),
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RapportBottomSheet(
            clientName: reservation.clientFullName,
            clientPhone: reservation.clientPhone,
            agentCommercialName: reservation.agentCommercialName ?? 'N/A',
            agentTerrainName: reservation.agentTerrainName ?? 'N/A',
            onSubmit: (rapportState, rapportMessage) {
              _submitRapport(reservation.id!, rapportState, rapportMessage);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _submitRapport(
    String reservationId,
    String rapportState,
    String? rapportMessage,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envoi du rapport...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Send rapport as a message via socket (this creates the message in chat)
      final socket = socketService.socket;
      if (socket != null) {
        print('📤 Sending rapport via socket');
        print('📤 Room ID: ${widget.room.id}');
        print('📤 Room type: ${widget.room.roomType}');
        print('📤 Reservation ID: $reservationId');
        print('📤 Rapport state: $rapportState');
        print('📤 Rapport message: $rapportMessage');

        // Map rapport state to result
        String result;
        switch (rapportState) {
          case 'potentiel':
            result = 'completed'; // Potentiel means client is interested
            break;
          case 'non_potentiel':
            result = 'cancelled'; // Non potentiel means not interested
            break;
          default:
            result = 'cancelled';
        }

        print('📤 Mapped result: $result');

        // Send rapport message via socket
        socket.emit('reservation_room:send_message', {
          'roomId': widget.room.id,
          'type': 'rapport',
          'text': rapportMessage ?? 'Rapport soumis',
          'result': result, // For reservation state
          'rapportState': rapportState, // Actual rapport state for display
          'reservationId': reservationId,
        });

        print('📤 Rapport sent via socket');

        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Rapport envoyé avec succès');
        }
      } else {
        // Fallback to API if socket not available
        final response = await apiClient.submitRapport(
          reservationId,
          rapportState,
          rapportMessage,
          token,
        );

        if (response.success) {
          if (mounted) {
            SnackbarUtils.showSuccess(
              context,
              response.message ?? 'Rapport envoyé avec succès',
            );

            // Navigate back to trigger reservation check
            Navigator.pop(context, true); // true = rapport was submitted
          }
        } else {
          if (mounted) {
            SnackbarUtils.showError(
              context,
              response.message ?? 'Erreur lors de l\'envoi',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Widget _buildRapportMessage(MessageModel message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCommercial = authProvider.isCommercial;

    print('🔍 DEBUG: isCommercial = $isCommercial');
    print(
      '🔍 DEBUG: widget.room.commercialAction = ${widget.room.commercialAction}',
    );
    print(
      '🔍 DEBUG: Can show button? ${isCommercial && widget.room.commercialAction == null}',
    );
    print('🔍 DEBUG: User role = ${authProvider.currentUser?.role}');

    // Parse rapport data from message text (JSON format)
    Map<String, dynamic> rapportData;
    try {
      rapportData = jsonDecode(message.text);
    } catch (e) {
      rapportData = {
        'rapportMessage': message.text,
        'rapportState': 'potentiel',
      };
    }

    final rapportState = rapportData['rapportState'] ?? 'potentiel';
    final rapportMessage = rapportData['rapportMessage'] ?? message.text;
    final isPotentiel = rapportState == 'potentiel';

    Color bgColor = isPotentiel ? Colors.green.shade50 : Colors.red.shade50;
    Color borderColor = isPotentiel ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: borderColor),
              const SizedBox(width: 8),
              Text(
                '📋 RAPPORT DE RENDEZ-VOUS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPotentiel ? Icons.thumb_up : Icons.thumb_down,
                color: borderColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'État: ${isPotentiel ? "POTENTIEL" : "NON POTENTIEL"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
          if (rapportMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rapportMessage.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy à HH:mm').format(message.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),

          // Commercial action button (only for potentiel rapports)
          FutureBuilder<bool>(
            future: _shouldShowButton(),
            builder: (context, snapshot) {
              final isCommercial = authProvider.isCommercial;

              // Don't show if not commercial agent
              if (!isCommercial) {
                return const SizedBox.shrink();
              }

              // Show button only if rapport is potentiel
              if (snapshot.hasData && snapshot.data == true) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _handleButtonClick();
                        },
                        icon: const Icon(Icons.business_center, size: 18),
                        label: const Text('Actions Commerciales'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Don't show button if rapport is non_potentiel
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialActionMessage(MessageModel message) {
    // Parse commercial action data from message text (JSON format)
    Map<String, dynamic> actionData;
    try {
      actionData = jsonDecode(message.text);
    } catch (e) {
      actionData = {'action': 'paye', 'message': message.text};
    }

    final action = actionData['action'] ?? 'paye';
    final actionMessage = actionData['message'] ?? message.text;

    // Determine color and icon based on action
    Color bgColor;
    Color borderColor;
    IconData icon;
    String actionText;

    switch (action) {
      case 'paye':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        icon = Icons.check_circle;
        actionText = 'Payé';
        break;
      case 'en_cours':
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange;
        icon = Icons.schedule;
        actionText = 'En Cours';
        break;
      case 'annulee':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        icon = Icons.cancel;
        actionText = 'Annulé';
        break;
      default:
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey;
        icon = Icons.business_center;
        actionText = 'Action Commerciale';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor),
              const SizedBox(width: 8),
              Text(
                '💼 ACTION COMMERCIALE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: borderColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'État: $actionText',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
          if (actionMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              actionMessage.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy à HH:mm').format(message.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove socket listeners and leave room
    _removeSocketListeners();

    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recorderController.dispose();

    // Cancel audio player completion subscription
    _audioPlayerCompleteSubscription?.cancel();

    // Dispose all player controllers
    for (var controller in _playerControllers.values) {
      controller.dispose();
    }
    _playerControllers.clear();

    // Leave room - but check if widget is still mounted
    // We need to leave the room before disposing, but safely
    try {
      if (mounted) {
        final messagingProvider = Provider.of<MessagingProvider>(
          context,
          listen: false,
        );
        messagingProvider.leaveRoom(widget.room.id);
      }
    } catch (e) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.9)
              : Colors.white.withOpacity(0.95),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF6366F1),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.room.name,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF6366F1),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.room.members.length} membres',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF6366F1).withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF6366F1),
              ),
              onSelected: (value) {
                if (value == 'leave') {
                  _showLeaveRoomDialog();
                } else if (value == 'info') {
                  _showRoomInfo();
                } else if (value == 'delete') {
                  _showDeleteRoomDialog();
                } else if (value == 'add_members') {
                  _showAddMembersDialog();
                }
              },
              itemBuilder: (context) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final isCreator =
                    widget.room.creator.id == authProvider.currentUser?.id;

                return [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('Informations'),
                      ],
                    ),
                  ),
                  if (isCreator) ...[
                    const PopupMenuItem(
                      value: 'add_members',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Color(0xFF6366F1)),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter des membres',
                            style: TextStyle(color: Color(0xFF6366F1)),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer la conversation',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Quitter', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: Consumer<MessagingProvider>(
                builder: (context, messagingProvider, child) {
                  if (_isLoadingMessages) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }

                  final messages = messagingProvider.getMessagesForRoom(
                    widget.room.id,
                  );

                  // Auto-scroll to bottom when new messages arrive
                  if (messages.length > _previousMessageCount) {
                    _previousMessageCount = messages.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun message',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envoyez le premier message!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.sender.id == currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),

            // Recording UI or Message input
            if (_isRecording) _buildRecordingUI() else _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  void _showLeaveRoomDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter la conversation'),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter cette conversation? '
          'Vous ne recevrez plus de messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final messagingProvider = Provider.of<MessagingProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;

              if (token != null) {
                final success = await messagingProvider.leaveRoomPermanently(
                  token: token,
                  roomId: widget.room.id,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vous avez quitté la conversation'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la sortie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRoomInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCreator = widget.room.creator.id == authProvider.currentUser?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    widget.room.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Créé ${timeago.format(widget.room.createdAt, locale: 'fr')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Membres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.room.members.map((member) {
              final hasProfilePhoto =
                  member.profilePhoto != null &&
                  member.profilePhoto!.url != null;
              final isMemberCreator = widget.room.creator.id == member.id;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  backgroundImage: hasProfilePhoto
                      ? NetworkImage(
                          member.profilePhoto!.url!.startsWith('http')
                              ? member.profilePhoto!.url!
                              : '${ApiEndpoints.baseUrl}${member.profilePhoto!.url!}',
                        )
                      : null,
                  child: !hasProfilePhoto
                      ? Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(member.name),
                subtitle: Text(member.role),
                trailing: isMemberCreator
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Créateur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : (isCreator
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showRemoveMemberDialog(member);
                              },
                              tooltip: 'Retirer',
                            )
                          : null),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoomDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la conversation'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette conversation? '
          'Tous les messages seront définitivement supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final messagingProvider = Provider.of<MessagingProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;

              if (token != null) {
                final success = await messagingProvider.deleteRoom(
                  token: token,
                  roomId: widget.room.id,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    // Fetch available users
    final result = await MessagingService.getAvailableUsers(
      token: token,
      roomId: widget.room.id,
    );

    if (!mounted) return;

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final availableUsers = result['users'] as List<UserBasic>;

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun utilisateur disponible à ajouter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedUsers = <String>[];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Ajouter des membres'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                final isSelected = selectedUsers.contains(user.id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedUsers.add(user.id);
                      } else {
                        selectedUsers.remove(user.id);
                      }
                    });
                  },
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  secondary: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    backgroundImage: user.profilePhoto?.url != null
                        ? NetworkImage(
                            user.profilePhoto!.url!.startsWith('http')
                                ? user.profilePhoto!.url!
                                : '${ApiEndpoints.baseUrl}${user.profilePhoto!.url!}',
                          )
                        : null,
                    child: user.profilePhoto?.url == null
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: selectedUsers.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);

                      final messagingProvider = Provider.of<MessagingProvider>(
                        context,
                        listen: false,
                      );

                      final success = await messagingProvider.addMembersToRoom(
                        token: token,
                        roomId: widget.room.id,
                        memberIds: selectedUsers,
                      );

                      if (!mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Membres ajoutés avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Erreur lors de l\'ajout des membres',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(UserBasic member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer le membre'),
        content: Text(
          'Voulez-vous retirer ${member.name} de cette conversation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final messagingProvider = Provider.of<MessagingProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;

              if (token != null) {
                final success = await messagingProvider.removeMemberFromRoom(
                  token: token,
                  roomId: widget.room.id,
                  memberId: member.id,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member.name} a été retiré'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors du retrait'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Check if button should be shown (only for potentiel rapports)
  Future<bool> _shouldShowButton() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || widget.room.reservationId == null) {
        return false;
      }

      // Fetch reservation to check rapportState
      final response = await apiClient.getReservations(token);

      if (response.success && response.data != null) {
        final reservation = response.data!.firstWhere(
          (r) => r.id == widget.room.reservationId,
          orElse: () => throw Exception('Reservation not found'),
        );

        // Only show button if rapportState is 'potentiel'
        return reservation.rapportState == 'potentiel';
      }
    } catch (e) {
      print('Error checking rapport state: $e');
    }

    return false;
  }

  // Handle button click with backend check
  Future<void> _handleButtonClick() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await apiClient.getReservations(token);

      if (response.success &&
          response.data != null &&
          widget.room.reservationId != null) {
        final reservation = response.data!.firstWhere(
          (r) => r.id == widget.room.reservationId,
          orElse: () => throw Exception('Reservation not found'),
        );

        if (reservation.commercialAction != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Vous avez déjà répondu: ${reservation.commercialActionDisplay}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking commercial action: $e');
    }

    _showCommercialActionDialog();
  }

  Future<void> _showCommercialActionDialog() async {
    try {
      // Fetch reservation details to get client and agent info
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || widget.room.reservationId == null) return;

      // Get all reservations and find the current one
      final response = await apiClient.getReservations(token);

      if (!response.success || response.data == null) {
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Erreur lors du chargement des détails',
          );
        }
        return;
      }

      // Find the reservation by ID
      final reservation = response.data!.firstWhere(
        (r) => r.id == widget.room.reservationId,
        orElse: () => throw Exception('Reservation not found'),
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CommercialActionBottomSheet(
            clientName: reservation.clientFullName,
            clientPhone: reservation.clientPhone,
            agentCommercialName: reservation.agentCommercialName ?? 'N/A',
            agentTerrainName: reservation.agentTerrainName ?? 'N/A',
            onSubmit: (action, newReservedAt, message) async {
              await _executeCommercialAction(action, newReservedAt, message);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _executeCommercialAction(
    String action,
    String? newReservedAt,
    String? message,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || widget.room.reservationId == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traitement en cours...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final response = await apiClient.takeCommercialAction(
        widget.room.reservationId!,
        action,
        token,
        newReservedAt: newReservedAt,
        message: message,
      );

      if (response.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Action enregistrée avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Send commercial action as a message via socket (this creates the message in chat)
        final socket = socketService.socket;
        if (socket != null) {
          socket.emit('reservation_room:send_message', {
            'roomId': widget.room.id,
            'type': 'commercial_action',
            'text': jsonEncode({'action': action, 'message': message}),
            'reservationId': widget.room.reservationId,
          });
        }

        // Reload messages to refresh UI
        await _reloadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Erreur lors de l\'action'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }
}
